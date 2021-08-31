[CmdletBinding()]
Param (
    [Parameter(Position = 0)][string] $module_dir_path = $(throw "Mandatory parameter not provided: <module_dir_path>"),
    [Parameter()][string] $description,
    [Parameter()][switch] $major,
    [Parameter()][switch] $minor,
    [Parameter()][switch] $patch,
    [Parameter()][switch] $new,
    [Parameter()][switch] $skip_publish
)



##########  VARS  ###############################################

$defaults = @{
    'version' = '0.1.0';
    'powershell_version' = '5.1';
    'functions_to_export' = '*';
    'aliases_to_export'   = '*';
}



##########  FUNCTIONS  ##########################################

#--------------------------------------------------
function verify-public-url {
    param ([Parameter()][string] $url)
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    $wc = New-Object System.Net.WebClient
    try { $wc.DownloadString($url) }
    catch { return $false }
    return $true
}



##########  MAIN  ###############################################

#--------------------------------------------------
# INIT
$ErrorActionPreference = 'Stop'
$host.PrivateData.ErrorBackgroundColor = $host.UI.RawUI.BackgroundColor
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
if (!(Get-Module UtilityFunctions)) { Import-Module UtilityFunctions -Force -DisableNameChecking }


#--------------------------------------------------
info "verifying module location: " -no_newline
$MODULE_PATH = $module_dir_path | abspath -verify
$MODULE_NAME = Split-Path $MODULE_PATH -Leaf
Resolve-Path (Join-Path $MODULE_PATH "$MODULE_NAME`.psm1") | Out-Null
info "found" -success


#--------------------------------------------------
info "looking for module manifest file (.psd1): " -no_newline
$MODULE_MANIFEST_PATH = Join-Path $MODULE_PATH "$MODULE_NAME.psd1"
$NEW_MANIFEST = $true
if (Test-Path $MODULE_MANIFEST_PATH) {
    $NEW_MANIFEST = $false
    info "found" -success
} else { warning "does not exist, will be created" -no_prefix }


#--------------------------------------------------
# CREATE NEW MANIFEST
if ($NEW_MANIFEST) {
    

    info "creating new manifest"
    
}


#--------------------------------------------------
# UPDATE EXISTING MANIFEST
else {
    info "updating existing manifest"

}