[CmdletBinding(DefaultParameterSetName = 'call_api')]
param (
    [Parameter(
        Mandatory = $true,
        ParameterSetName = "add_login")]
    [alias("al")]
    [string]$add_login,

    [Parameter(
        Mandatory = $true,
        ParameterSetName = "add_login")]
    [alias("url")]
    [string]$artifactory_base_url,


    [Parameter(ParameterSetName = "list_logins")]
    [alias("ll")]
    [switch]$list_logins,


    [Parameter(ParameterSetName = "delete_login")]
    [alias("dl")]
    [string]$delete_login,


    [Parameter(ParameterSetName = "set_default_login")]
    [alias("default")]
    [string]$set_default_login,


    [Parameter(
        Mandatory = $true,
        ParameterSetName = "call_api",
        Position = 0)]
    [alias("api")]
    [string]$call_api,


    [Parameter(ParameterSetName = "call_api")]
    [ValidateSet("DELETE", "GET", "PATCH", "POST", "PUT")]
    [alias("m")]
    [string]$api_method = 'GET',


    [Parameter(ParameterSetName = "call_api")]
    [ValidateSet("application/json", "application/x-www-form-urlencoded", "text/plain", "application/text")]
    [alias("t")]
    [string]$content_type = 'application/json',


    [Parameter(ParameterSetName = "call_api")]
    [alias("d")]
    [string]$request_data,

    [Parameter(ParameterSetName = "call_api")]
    [alias("in")]
    [string]$request_input_file,

    [Parameter(ParameterSetName = "call_api")]
    [alias("out")]
    [string]$output_file,

    [Parameter(ParameterSetName = "call_api")]
    [alias("login")]
    [string]$use_login
)


##########  FUNCTIONS  ###############################################

function minfo ($message, [switch]$sub, [switch]$newline) {
    if ($sub) {
        $message = "  $message"
        $color = "DarkGray"
    }
    else {
        $color = "White"
    }
    if ($newline) {
        $message += "`n"
    }
    Write-Host $message -ForegroundColor $color
}

function mwarn ($message, [switch]$newline) {
    if ($newline) {
        $message += "`n"
    }
    write-host " (!) $message" -ForegroundColor Yellow
}

function merr ($message, [switch]$newline) {
    if ($newline) {
        $message += "`n"
    }
    write-host " (!) $message" -ForegroundColor Red
}

function json_to_hash {
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [String] $json
    )

    begin {
        Write-Debug "Beginning $($MyInvocation.Mycommand)"
        Write-Debug "Bound parameters:`n$($PSBoundParameters | out-string)"

        try {
            Add-Type -AssemblyName "System.Web.Extensions, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" -ErrorAction Stop
        }
        catch {
            throw "Unable to locate the System.Web.Extensions namespace from System.Web.Extensions.dll. Are you using .NET 4.5 or greater?"
        }

        $jsSerializer = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
    }

    process {
        $jsSerializer.Deserialize($json, 'Hashtable')
    }

    end {
        $jsSerializer = $null
        Write-Debug "Completed $($MyInvocation.Mycommand)"
    }
}

function sstring_to_plain ([System.Security.SecureString]$sstring) {
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sstring)
    $plain_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto($pointer)
    return $plain_text
}



##########  MAIN  ####################################################
$ErrorActionPreference = 'Stop'

$config_file_path = "~/.jfr/config.json"
$config_default = @{ "logins" = @{} }

if (!(Test-Path $config_file_path)) {
    ni $config_file_path -Force | Out-Null
    $config_default | ConvertTo-Json | Set-Content $config_file_path -Force
}

if ( $PSVersionTable.PSVersion.Major -gt 5 ) { $config = cat $config_file_path -Raw | ConvertFrom-Json -AsHashtable }
else { $config = cat $config_file_path -Raw | json_to_hash }

if (!$config) {
    $config = $config_default
}


#######  Add Login
if ($add_login) {

    $failure = $false

    # validate values
    $pattern = '^\w+$'
    if ($add_login.TrimEnd() -notmatch $pattern) {
        mwarn "<add_login> value must not be an empty string, can only have letters, digits and underscore."
        $failure = $true
    }

    if ($add_login -in $config.logins.Keys) {
        mwarn "Login ID '$add_login' is being used already. To force update, first delete existing login."
        minfo "(use '-list_logins' parameter to list saved logins)" -sub -newline
        exit
    }

    if ($artifactory_base_url.TrimEnd().Length -eq 0) {
        mwarn "<artifactory_base_url> value must not be an empty string."
        $failure = $true
    }

    $pattern = 'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)'
    if ($artifactory_base_url.TrimEnd('/') -notmatch $pattern) {
        mwarn "<artifactory_base_url> value cannot be an empty string and must be a valid URL."
        $failure = $true
    }

    if ($failure) {
        merr "Operation failed: 'add_artifactory_login'" -newline
        exit 1
    }

    # append mandatory suffix
    $artifactory_base_url = $artifactory_base_url.TrimEnd('/')
    if (! $artifactory_base_url.EndsWith('/artifactory')) {
        $artifactory_base_url += '/artifactory'
    }

    # get API token for new login
    $credential = Get-Credential
    $password = sstring_to_plain $credential.Password
    $pair = "$($credential.UserName):$password"
    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
    $basicAuthValue = "Basic $encodedCreds"
    $headers_ = @{ 'Authorization' = $basicAuthValue }
    $url_ = $artifactory_base_url + '/api/security/apiKey'
    $api_token = (irm -Uri $url_ -Headers $headers_).apiKey

    # create API token if does not exist
    if (!$api_token) {
        $api_token = (irm -Uri $url_ -Method POST -Headers $headers_).apiKey
    }

    # check if login exists
    foreach ($login in $config.logins.GetEnumerator()) {
        $login_token = sstring_to_plain (ConvertTo-SecureString -String $login.value.api_token)
        if ($api_token -eq $login_token -and $login.value.base_url -eq $artifactory_base_url) {
            mwarn "This Login already saved with ID : $($login.key)"
            minfo "(use '-list_logins' parameter to list saved logins)" -sub -newline
            exit
        }
    }

    # add login
    $login = @{
        'base_url'  = $artifactory_base_url
        'api_token' = ConvertTo-SecureString -String $api_token -AsPlainText -Force | ConvertFrom-SecureString
    }
    $config.logins.Add($add_login, $login)

    # set current login as default
    if (!$config.default_login) {
        $config.default_login = $add_login
    }

    # save config file
    $config | ConvertTo-Json | Set-Content $config_file_path -Force
    minfo "Login ID : $add_login" -sub -newline
    exit
}


#######  List Logins
if ($list_logins) {

    foreach ($login in $config.logins.GetEnumerator()) {

        $message = "$($login.key) @ $($login.value.base_url)"

        if ($login.key -eq $config.default_login) {
            $message += " (default)"
        }

        minfo $message -sub
    }

}


#######  Delete Login
if ($delete_login) {

    $failure = $false

    # validate values
    if ($delete_login.TrimEnd().Length -eq 0) {
        mwarn "<delete_login> value must not be an empty string."
        $failure = $true
    }

    $pattern = '^\w+$'
    if ($delete_login.TrimEnd() -notmatch $pattern) {
        mwarn "<delete_login> can only have letters, digits and underscore."
        $failure = $true
    }

    # delete login
    if (!$config.logins.Remove($delete_login)) {
        mwarn "Login ID '$delete_login' does not exist."
        $failure = $true
    }

    if ($failure) {
        merr "Operation failed: 'delete_login'" -newline
        exit 1
    }

    # save config file
    $config | ConvertTo-Json | Set-Content $config_file_path -Force
    minfo "Deleted login '$delete_login'" -sub -newline
    exit
}


#######  Set Default Login
if ($set_default_login) {

    $failure = $false

    # validate values
    if ($set_default_login.TrimEnd().Length -eq 0) {
        mwarn "<set_default_login> value must not be an empty string."
        $failure = $true
    }

    $pattern = '^\w+$'
    if ($set_default_login.TrimEnd() -notmatch $pattern) {
        mwarn "<set_default_login> can only have letters, digits and underscore."
        $failure = $true
    }

    if ($set_default_login -notin $config.logins.keys) {
        mwarn "Login ID '$set_default_login' does not exist."
        $failure = $true
    }

    if ($failure) {
        merr "Operation failed: 'set_default_login'" -newline
        exit 1
    }

    # set default login
    $config.default_login = $set_default_login

    # save config file
    $config | ConvertTo-Json | Set-Content $config_file_path -Force
    minfo "Default Login: '$set_default_login'" -sub -newline
    exit
}

#######  Call API
if ($call_api) {

    $failure = $false

    # validate values
    if (!$call_api.StartsWith('/api/')) {
        mwarn "Expected <call_api> format: '/api/...'. Specified value: '$call_api'."
    }

    if ($request_data -and $request_input_file) {
        mwarn "Ambigous data source: <request_data> and <request_input_file> cannot be used at the same time."
        $failure = $true
    }

    if (($content_type -eq 'application/text') -and !($request_input_file)) {
        mwarn "Content-type 'application/text' requires <request_input_file> to be provided."
        $failure = $true
    }

    if (($api_method -ne 'GET') -and !($request_data) -and !($request_input_file)) {
        mwarn "No data provided with API Method '$api_method'."
    }

    if ($use_login) {

        if ($use_login -notin $config.logins.keys) {
            mwarn "Login ID '$use_login' does not exist."
            $failure = $true
        }

        # retrive login info
        if (!$failure) {
            $base_url = $config.logins.($use_login).base_url
            $api_token = sstring_to_plain (ConvertTo-SecureString -String $config.logins.($use_login).api_token)
        }

    }
    else {
        if (!$failure) {
            $base_url = $config.logins.($config.default_login).base_url
            $api_token = $config.logins.($config.default_login).api_token
            $api_token = sstring_to_plain (ConvertTo-SecureString -String $config.logins.($config.default_login).api_token)
        }
    }

    if ($failure) {
        merr "Operation failed: 'Call API'" -newline
        exit 1
    }

    # construct API call parameters
    $url_ = $base_url + $call_api
    $headers_ = @{'X-JFrog-Art-Api' = $api_token }
    $method_ = $api_method
    $type_ = $content_type

    # GET
    if ($api_method -eq 'GET') {
        if ($output_file) {
            irm -Uri $url_ -Headers $headers_ -OutFile $output_file
        }
        else {
            irm -Uri $url_ -Headers $headers_
        }
    }

    # UPLOAD FILE
    elseif ($request_data) {
        irm -Uri $url_ -Headers $headers_ -Method $method_ -ContentType $type_ -Body $request_data
    }

    # UPLOAD DATA
    else {
        irm -Uri $url_ -Headers $headers_ -Method $method_ -ContentType $type_ -InFile $request_input_file
    }
}
