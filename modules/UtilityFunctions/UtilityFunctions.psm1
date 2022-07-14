$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$message_padding = "  "


#--------------------------------------------------
function newline {
    param([int]$count = 1)

    1..$count | % { Write-Host "`n" }

    <#
    .SYNOPSIS
    Alias: lf
    .Description
    Prints newline character(s) into the console.
    .PARAMETER count
    Specifies amount of consequent newlines to be printed. Defaults to 1.
    Example: -count 5
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function error {
    param([string]$message)

    Write-Host ($message_padding + "ERROR: $message`n") -ForegroundColor Red

    <#
    .Description
    Prints error message into the console following defined format: "ERROR: <message>"
    .PARAMETER message
    Message to display.
    Example: -message "Something went wrong."
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function info {
    param(
        [string]$message,
        [switch]$nonewline,
        [switch]$success,
        [switch]$sub
    )

    $color = 'White'
    if ($success) { $color = 'Green' }
    if ($sub) { $color = 'DarkGray' }

    Write-Host ($message_padding + $message) -ForegroundColor $color -NoNewline:$nonewline

    <#
    .Description
    Prints info message into the console. Optionally colors text green and omits trailing newline.
    .PARAMETER message
    Message to display.
    Example: -message "Some info."
    .PARAMETER nonewline
    Omits trailing newline, so the next console output will be printed to the same line.
    Example: -nonewline
    .PARAMETER success
    Colors message text green.
    Example: -success
    .PARAMETER sub
    Colors message text dark gray.
    Example: -sub
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function warning {
    param(
        [string]$message,
        [switch]$nonewline,
        [switch]$noprefix
    )

    if ($noprefix) { Write-Host ($message_padding + $message) -ForegroundColor Yellow -NoNewline:$nonewline }
    else { Write-Host ($message_padding + "WARNING: $message") -ForegroundColor Yellow -NoNewline:$nonewline }

    <#
    .Description
    Prints warning message into the console following defined format: "WARNING: <message>" and colors it yellow.
    Optionally omits 'WARNING' prefix and trailing newline.
    .PARAMETER message
    Message to display.
    Example: -message "Note something!"
    .PARAMETER nonewline
    Omits trailing newline, so the next console output will be printed to the same line.
    Example: -nonewline
    .PARAMETER noprefix
    Omits 'WARNING:' prefix.
    Example: -noprefix
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function request-consent {
    param([string]$question)

    do {
        warning (" (?) $question ( y/n ): ") -noprefix
        $key = [System.Console]::ReadKey("NoEcho").key
        if ($key -notin 'Y', 'N') { error "It's a yes/no question." }
    }
    while ($key -notin 'Y', 'N')

    switch ($key) {
        'Y' { info "<yes>"; return $true }
        'N' { info "<no>"; return $false }
    }

    <#
    .SYNOPSIS
    Alias: confirm
    .Description
    Prints yes/no question into the console following defined format: "(?) <question> ( y/n ):" and awaits a key press from the user.
    Only accepts y(Y) and n(N) for response and gives user a hint otherwise.
    Returns True (y) or False (n).
    .PARAMETER question
    Message to display.
    Example: -question "Do you want to continue?"
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function wait-any-key {
    [System.Console]::ReadKey("NoEcho").key | Out-Null

    <#
    .SYNOPSIS
    Alias: wait
    .Description
    Halts script/command execution and awaits a key press from the user.
    Does not accept any parameters.
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function isadmin {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole] "Administrator")

    <#
    .Description
    Returns True if current console/script runs as admin and False otherwise.
    Does not accept any parameters.
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function restart-elevated {
    param(
        $arguments,
        [switch]$kill_original,
        [string]$workdir = $PWD.path
    )

    if ($MyInvocation.ScriptName -eq "") { throw 'Script must be saved as a .ps1 file.' }
    if (isadmin) { return $null }

    try {
        $script_fullpath = $MyInvocation.ScriptName
        $argline = "-noprofile -nologo -noexit"
        $argline += " -Command cd `"$workdir`"; `"$script_fullpath`""

        if ($arguments) {
            $arguments.GetEnumerator() | % {
                if ($_.Value -is [boolean]) { $argline += " -$($_.key) `$$($_.value)" }
                elseif ($_.Value -is [switch]) { $argline += " -$($_.key)" }
                else { $argline += " -$($_.key) `"$($_.value)`"" }
            }
        }

        $p = Start-Process "$PSHOME\powershell.exe" -Verb Runas -ArgumentList $argline -PassThru -ErrorAction 'stop'
        if ($kill_original) { [System.Diagnostics.Process]::GetCurrentProcess() | Stop-Process -ErrorAction Stop }
        info "Elevated process id: $($p.id)"
        exit
    }
    catch {
        error "Failed to restart script with elevated premissions."
        throw $_
    }

    <#
    .Description
    Restarts current script as administrator. Allows to pass current arguments.
    Optionally kills original (non-admin) script/console.
    .PARAMETER arguments
    Arguments to be passed to the elevated script.
    Example: -arguments $PSBoundParameters
    .PARAMETER kill_original
    Kills original (non-admin) script/console when elevated script has started.
    Example: -kill_original
    .PARAMETER workdir
    Specifies directory where elevated script should be started. Defaults to current directory.
    Example: -workdir <some/path>
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function is-restart-pending {
    $is_restart_pending = $false
    if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { $is_restart_pending = $true }
    if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { $is_restart_pending = $true }
    if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { $is_restart_pending = $true }

    try {
        $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
        $status = $util.DetermineIfRebootPending()
        if (($status -ne $null) -and $status.RebootPending) {
            $is_restart_pending = $true
        }
    }
    catch { }

    return $is_restart_pending

    <#
    .SYNOPSIS
    Alias: isrp
    .Description
    Returns True if system restart is pending and False otherwise.
    Does not accept any parameters.
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function hibernate {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::SetSuspendState("Suspend", $false, $true) | Out-Null

    <#
    .SYNOPSIS
    Alias: hib
    .Description
    Puts computer to sleep.
    Does not accept any parameters.
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function json-to-hashtable {
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)][AllowEmptyString()][string]$json,
        [Parameter()][switch]$large
    )

    begin {
        try { Add-Type -AssemblyName "System.Web.Extensions, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" -ErrorAction Stop }
        catch {
            error "Unable to locate the System.Web.Extensions namespace from System.Web.Extensions.dll. Are you using .NET 4.5 or greater?"
            throw $_
        }

        $jsSerializer = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
        if ($large) { $jsSerializer.MaxJsonLength = 104857600 }
    }

    process { $jsSerializer.Deserialize($json, 'Hashtable') }

    end { $jsSerializer = $null }

    <#
    .SYNOPSIS
    Alias: jth
    .Description
    Converts a string in json format into hashtable.
    This is a replacement for PowerShell built-in ConvertFrom-Json function, which returns PSObject.
    Allows pipeline input.
    .PARAMETER json
    String in json format to be converted. Allows ValueFromPipeline.
    Example 1: json-to-hashtable -json <json_string>
    Example 2: <json_string> | json-to-hashtable
    .PARAMETER large
    Increases maximum allowed size of the json string. Use if fails otherwise.
    Example: -large
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function abspath {
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)][AllowEmptyString()][string]$path,
        [Parameter()][string]$parent = $pwd.Path,
        [Parameter()][switch]$verify
    )

    process {
        if ($path) {
            if ($path -eq '.') { $path = '' }
            $path = $path.replace('/','\')
            $path = $path -replace '^~', "$HOME"
            $path = $path -replace '^\.\\', ''
            if ([System.IO.Path]::IsPathRooted($path)) { $abspath = $path }
            else { $abspath = (Join-Path ($parent | abspath) $path) }
            if ($verify) { $abspath = (Resolve-Path $abspath -ErrorAction Stop).Path }
            $abspath
        }
    }

    <#
    .Description
    Converts any path into absolute path. Optionally verifies if path exists.
    Allows pipeline input.
    .PARAMETER path
    Absolute or relative path to be converted. Allows ValueFromPipeline.
    Example 1: abspath -path <relative/path>
    Example 2: <relative/path> | abspath
    .PARAMETER parent
    Specifies parent path (absolute or relative to current directory) to resolve from.
    Parent path itself will be resolved first.
    Example: -parent <some/path>
    .PARAMETER verify
    Verifies if resolved path exists, throws excepion otherwise.
    Example: -verify
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function which {
    param(
        [string]$executable
    )

    (gcm $executable -ErrorAction SilentlyContinue).Source

    <#
    .Description
    Returns executable's source path if it's discoverable from the command line.
    Otherwise, returns Null.
    .PARAMETER executable
    Specifies executable name (<base_name> or <base_name>.exe) to lookup.
    Example: -executable <executable_name>
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function list-module-commands {
    param(
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias("name")]
        [string]$module_name = $(throw "Mandatory parameter not provided: <module_name>."),

        [Parameter(Position = 1)]
        [switch]$as_hashtable
    )

    try { $module_name = (Get-Module $module_name).Name }
    catch { throw "Cannot find module `"$module_name`"" }

    if (!$module_name) { throw "Module not found: `"$module_name`""}
    $module_version = (Get-Module $module_name).Version.ToString()
    $commands_map = @{}
    $max_length = 0

    (Get-Command -Module $module_name).name | `
        % {
            $commands_map.add($_, (Get-Alias -Definition $_ -ErrorAction SilentlyContinue))
            if ($_.length -gt $max_length) { $max_length = $_.length }
        }

    if ($as_hashtable) { return $commands_map }
    info "$module_name v$module_version`:"
    $commands_map.keys | sort | %{
        $line = " $_".PadRight($max_length + 5)
        if ($commands_map.$_) { $line += "-->  $($commands_map.$_)" }
        info $line -sub
    }

    <#
    .SYNOPSIS
    Alias: listmc
    .Description
    Prints available commands of a PowerShell module together with their aliases.
    Optionally returns result as hashtable instead of printing to console.
    .PARAMETER module_name
    Specifies name of the module for which list of commands should be displayed.
    Example: -module_name <ModuleName>
    .PARAMETER as_hashtable
    Returns commands with aliases as hashtable instead of printing to console.
    Example: -as_hashtable
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function zip {
    param(
        [string]$fromdir,
        [string]$zippath,
        [parameter()][ValidateSet('Optimal','Fastest','NoCompression')][string]$compression = 'Optimal',
        [switch]$include_basedir
    )

    try { $fromdir = $fromdir | abspath -verify }
    catch { throw "Failed to validate parameter <fromdir>: $($_.ToString())" }
    if (!$zippath) { $zippath = (Split-Path $fromdir -Leaf) + ".zip" }
    $zippath = $zippath | abspath
    mkdir (Split-Path $zippath) -Force -ErrorAction stop | Out-Null
    Add-Type -AssemblyName "system.io.compression.filesystem"
    try {
        [io.compression.zipfile]::CreateFromDirectory($fromdir, $zippath, $compression, $include_basedir.IsPresent)
    }
    catch {
        if (Test-Path $zippath) {
            if ((gi $zippath).PSIsContainer) {
                error "Invalid value of parameter -zippath: `"$zippath`". This path resolves to existing directory, but must be a filepath."
            }
        }
        throw $_
    }

    <#
    .Description
    Compresses a directory into .zip archive.
    Optionally includes target directory as a root directory in the archive.
    .PARAMETER fromdir
    Specifies absolute or relative path to the directory to be compressed.
    Path will be converted to absolute path and must exist, otherwise throws exception.
    Example: -fromdir <path/to/dir>
    .PARAMETER zippath
    Specifies absolute or relative path to the output .zip file.
    Missing subdirectories will be created.
    Example: -zippath <path/to/file.zip>
    .PARAMETER compression
    Specifies compression level. Accepted values: 'Optimal', 'Fastest, 'NoCompression'.
    Defaults to 'Optimal'
    Example: -compression <Fastest>
    .PARAMETER include_basedir
    Includes target directory as a root directory in the archive (Windows style).
    Example: -include_basedir
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function unzip {
    param(
        [string]$zippath,
        [string]$todir = $PWD.path
    )

    try { $zippath = $zippath | abspath -verify }
    catch { throw "Failed to validate parameter <zippath>: $($_.ToString())" }
    $todir = $todir | abspath
    if (! (Test-Path $todir)) { mkdir $todir -Force -ErrorAction stop | Out-Null }
    Add-Type -AssemblyName "system.io.compression.filesystem"
    [io.compression.zipfile]::ExtractToDirectory($zippath, $todir)

    <#
    .Description
    Extracts .zip archive into a directory.
    .PARAMETER zippath
    Specifies absolute or relative path to the .zip file.
    Path will be converted to absolute path and must exist, otherwise throws exception.
    Example: -zippath <path/to/file.zip>
    .PARAMETER todir
    Specifies absolute or relative path to the directory to be compressed.
    Missing subdirectories will be created.
    Example: -todir <path/to/dir>
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function extract-file {
    param(
        [string]$filter,
        [string]$zippath,
        [string]$todir = $($PWD.path)
    )

    try { $zippath = $zippath | abspath -verify }
    catch { throw "Failed to validate parameter <zippath>: $($_.ToString())" }
    $todir = $todir | abspath
    mkdir $todir -Force -ErrorAction stop | Out-Null
    [Reflection.Assembly]::LoadWithPartialName( "System.IO.Compression.FileSystem" ) | Out-Null
    $zipstream = [System.IO.Compression.ZipFile]::OpenRead($zippath)

    foreach ($zipfile in $zipstream.Entries) {
        if ($zipfile.Name -like $filter) {
            $destination_filepath = Join-Path $todir $zipfile.Name
            $filestream = New-Object IO.FileStream ($destination_filepath) , 'Append', 'Write', 'Read'
            $file = $zipfile.Open()
            $file.CopyTo($filestream)
            $file.Close()
            $filestream.Close()
        }
    }

    $zipstream.Dispose()

    <#
    .SYNOPSIS
    Alias: unzipf
    .Description
    Extracts files that match filter from .zip archive into a directory.
    .PARAMETER filter
    Specifies mask to filter file names in the .zip archive.
    Accepts wildcards "*".
    Example: -filter <*.txt>
    .PARAMETER zippath
    Specifies absolute or relative path to the .zip file.
    Path will be converted to absolute path and must exist, otherwise throws exception.
    Example: -zippath <path/to/file.zip>
    .PARAMETER todir
    Specifies absolute or relative path to the directory to be compressed.
    Missing subdirectories will be created.
    Example: -todir <path/to/dir>
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function get-files-with-text {
    [cmdletbinding(DefaultParameterSetName = "plain")]
    param(
        [Parameter(ParameterSetName = "plain", Position = 0)][ValidateNotNullOrEmpty()][string]$text,
        [Parameter(ParameterSetName = "regex", Position = 0)][ValidateNotNullOrEmpty()][string]$regex,
        [Parameter(Position = 1)][string]$searchdir = $($pwd.path),
        [Parameter()][string]$filter = "*",
        [Parameter()][switch]$norecurse,
        [Parameter()][switch]$open,
        [Parameter()][string]$outfile
    )

    $ErrorActionPreference = 'Stop'

    # validate <searchdir> path
    try { $searchdir = $searchdir | abspath -verify }
    catch { throw "Failed to validate parameter <searchdir>: $($_.ToString())" }

    # search text/pattern in files
    if ($PSCmdlet.ParameterSetName -eq "plain") { $search_string = $text }
    else { $search_string = $regex }
    $file_list = (ls $searchdir -Recurse:$(!$norecurse.IsPresent) -Filter $filter | `
        sls -SimpleMatch:$($PSCmdlet.ParameterSetName -eq "plain") -Pattern $search_string -List).Path

    if ($open) {
        $text_editor = which notepad++
        if (!$text_editor) { $text_editor = 'notepad.exe' }
        $file_list | % { & $text_editor $_ }
    }

    if ($outfile) {
        $outfile = $outfile | abspath
        mkdir (Split-Path $outfile) -Force | Out-Null
        $file_list | Out-File $outfile -Force
    }
    else {
        $file_list
    }

    <#
    .SYNOPSIS
    Alias: fwt
    .Description
    Searches directory for all the files that contain search string or regex pattern match and prints their paths.
    Optionally opens found paths in Notepad++ (or Windows notepad if Notepad++ is not available).
    Optionally dumps results into file instead of displaying in the console.
    .PARAMETER text
    Specifies literal search string (no wildcards, not case-sensitive). This is default option.
    Example: -text 'search string'
    .PARAMETER regex
    Specifies search regex pattern. Case-sensitive. Must be specified explicitly.
    Example: -regex <.*Regex(\sPattern)+.*>
    .PARAMETER searchdir
    Specifies absolute or relative path to the search root directory.
    Path will be converted to absolute path and must exist, otherwise throws exception.
    Example: -searchdir <path/to/dir>
    .PARAMETER filter
    Specifies mask to filter file names in the search directory and subdirectories.
    Accepts wildcards "*".
    Example: -filter <*.txt>
    .PARAMETER norecurse
    Limits search to only search root directory without subdirectories.
    Example: -norecurse
    .PARAMETER open
    Opens found paths in the Notepad++ (or Windows notepad if Notepad++ is not available).
    Example: -open
    .PARAMETER outfile
    Specifies absolute or relative path to the output file where results will be sent to instead of the console.
    Missing subdirectories will be created.
    Example: -outfile <path/to/file>
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function sha {
    [cmdletbinding(DefaultParameterSetName = "text")]
    param(
        [Parameter(ParameterSetName = "text", Position = 0, ValueFromPipeline = $true)][AllowEmptyString()][string]$text,
        [Parameter(ParameterSetName = "file", Position = 0)][ValidateNotNullOrEmpty()][string]$file,
        [parameter()][ValidateSet('1', '256', '384', '512')][string]$algorithm = '256'
    )

    begin {
        $algorithm_prefix = "SHA$algorithm`:"
        $algorithm_name = "SHA$algorithm`Managed"
        $hasher = new-object System.Security.Cryptography.$algorithm_name
    }

    process {
        $ErrorActionPreference = 'Stop'

        if ($PSCmdlet.ParameterSetName -eq 'file') {
            try { $file = $file | abspath -verify }
            catch { throw "Failed to validate parameter <file>: $($_.ToString())" }
            $byte_array = [System.IO.File]::ReadAllBytes($file)
        }
        else { $byte_array = [System.Text.Encoding]::UTF8.GetBytes($text) }

        $hash_byte_array = $hasher.ComputeHash($byte_array)
        $hash_byte_array | % { $hash_string += $_.ToString() }
        "$algorithm_prefix $hash_string"
    }

    end { $hasher = $null }

    <#
    .Description
    Generates hash for text or file using SHA- algorithm of choice. Defaults to SHA256.
    .PARAMETER text
    Specifies text to be hashed. Allows ValueFromPipeline.
    Example 1: sha -text "some text"
    Example 2: "some text" | sha
    .PARAMETER file
    Specifies absolute or relative path to the file for which hash string will be generated.
    Path will be converted to absolute path and must exist, otherwise throws exception.
    Example: -file <path/to/file>
    .PARAMETER algorithm
    Specifies type of SHA- algorithm. Accepted values: '1', '256', '384', '512'.
    Defaults to '256'
    Example: -algorithm 384
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function base64 {
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)][AllowEmptyString()][string]$text,
        [parameter()][switch]$decrypt
    )

    process {
        if ($decrypt) { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($text)) }
        else { [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text)) }
    }

    <#
    .Description
    Encrypts or decrypts text using base64 encryption algorithm.
    .PARAMETER text
    Specifies text to be encrypted. Allows ValueFromPipeline. This is default option.
    Example 1: base64 -text "some text"
    Example 2: "some text" | base64
    .PARAMETER decrypt
    Decrypts input object instead of encrypting it.
    Example: -decrypt
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function ss-to-plain {
    param([Parameter(Position = 0, ValueFromPipeline = $true)][System.Security.SecureString]$sstring)

    process {
        $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sstring)
        $plain_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto($pointer)
        return $plain_text
    }

    <#
    .SYNOPSIS
    Alias: sstp
    .Description
    Converts [SecureString] object into plain text.
    .PARAMETER sstring
    Specifies [SecureString] object to be converted.
    Example 1: ss-to-plain -sstring $sstring
    Example 2: $sstring | ss-to-plain
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------

function run-sql() {
    [cmdletbinding(DefaultParameterSetName = "integrated")]
    Param (
        [Parameter()][Alias("s")][string]$server = '.',
        [Parameter(Mandatory = $true)][Alias("d")][string]$database,
        [Parameter(Mandatory = $true, ParameterSetName = "pscred")][Alias("c")][pscredential]$credential,
        [Parameter(Mandatory = $true, ParameterSetName = "not_integrated")][Alias("u")][string]$user,
        [Parameter(Mandatory = $true, ParameterSetName = "not_integrated")][Alias("p")][securestring]$passw,
        [Parameter(ParameterSetName = "integrated")][switch]$winauth = $true,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][Alias("q")][string]$query,
        [Parameter()][Alias("t")][int]$timeout = 0,
        [Parameter()][Alias("o")][string]$outfile,
        [Parameter()][Alias("n")][switch]$no_success_message
    )

    $ErrorActionPreference = 'Stop'

    # build connection string
    $connstring = "Server=$server; Database=$database; "
    if ($PSCmdlet.ParameterSetName -eq "integrated") { $connstring += "Trusted_Connection=Yes; Integrated Security=SSPI;" }
    else {
        if ($PSCmdlet.ParameterSetName -eq "pscred") { $user = $credential.UserName; $passw = $credential.Password }
        $connstring += "User ID=$user; Password=$($passw | ss-to-plain);"
    }

    try {
        # CONNECT TO DATABASE
        $connection = New-Object System.Data.SqlClient.SqlConnection($connstring)
        $connection.Open()
    }
    catch {
        if ($_.Exception -like '*A network-related or instance-specific error occurred while establishing a connection to SQL Server*') {
            throw "Connection error: $($_.ToString())"
        }
    }

    # build command object
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $command.CommandTimeout = $timeout

    # build adapter object
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet

    try {
        # EXECUTE QUERY
        $adapter.Fill($dataset) | Out-Null

        # capture ouput
        $output = $dataset.Tables
        if (!$output[0]) {
            $output = New-Object System.Collections.ArrayList
        }

        # result message
        if (!$no_success_message) {
            info 'executed successfully' -success
        }
    }
    catch {
        throw $_.ToString().replace('Exception calling "Fill" with "1" argument(s):', 'SQL Server returned error:')
    }
    finally {
        $connection.Close()
    }

    # dump to file
    if ($outfile) {
        $outfile = $outfile | abspath
        mkdir (Split-Path $outfile) -Force | Out-Null
        $output | Out-File $outfile -Force
    }
    else {
        return $output
    }

    <#
    .SYNOPSIS
    Alias: sql
    .Description
    Executes SQL query against remote database server and returns response, if any.
    Uses Windows authentication by default.
    .PARAMETER server
    Specifies remote SQL instance to run query against. Uses format <server\instance>.
    Defaults to local_host\default_instance (".").
    Example: -server <remote.server.com>\<instance_name>
    .PARAMETER database
    Specifies database on SQL instance to run query against.
    Example: -database <db_name>
    .PARAMETER credential
    Specifies PSCredential to use for authentication on SQL instance.
    Example: -credential <pscredential_object>
    .PARAMETER user
    Specifies username to use for authentication on SQL instance.
    Example: -user <user_name>
    .PARAMETER passw
    Specifies password to use for authentication on SQL instance.
    Example: -passw <password>
    .PARAMETER winauth
    This is default option that is used if neither credential nor username/password specified.
    No need to use explicitly.
    .PARAMETER query
    Specifies SQL query to execute against remote database server.
    Example: -query "select * from <tab_name>"
    .PARAMETER timeout
    Specifies SQL command timeout in seconds.
    Example: -timeout 10
    .PARAMETER outfile
    Specifies absolute or relative path to the output file where results will be sent to instead of the console.
    Missing subdirectories will be created.
    Example: -outfile <path/to/file>
    .PARAMETER no_success_message
    Supresses successful execution status message that is shown by default. The message is useful when query does not expect return data.
    Example: -no_success_message
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function run-process {
    param (
        [Parameter()][Alias("e")][string]$executable = $(throw "Mandatory parameter not provided: <executable>."),
        [Parameter()][Alias("a")][string]$arguments,
        [Parameter()][Alias("w")][string]$workdir = $PWD.path,
        [Parameter()][Alias("c")][PSCredential]$credential,
        [Parameter()][Alias("nw")][switch]$newwindow,
        [Parameter()][Alias("nc")][switch]$no_console_output
    )

    $ErrorActionPreference = 'Stop'

    # resolve executable path
    $resolved_exe_path = which $executable
    if ($resolved_exe_path) { $executable = $resolved_exe_path }
    else {
        try { $executable = $executable | abspath -verify }
        catch { throw "Failed to validate parameter <executable>: $($_.ToString())" }
    }

    # resolve working_directory
    try { $workdir = $workdir | abspath -verify }
    catch { throw "Failed to validate parameter <workdir>: $($_.ToString())" }

    # build ProcessStartInfo object
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = "$executable"
    $ProcessInfo.WorkingDirectory = $workdir
    $ProcessInfo.CreateNoWindow = !$newwindow.IsPresent
    $ProcessInfo.RedirectStandardError = $true
    $ProcessInfo.RedirectStandardOutput = $true
    $ProcessInfo.UseShellExecute = $false
    $ProcessInfo.Arguments = $arguments

    # set credentials
    if ($credential) {
        $ProcessInfo.Username = $credential.GetNetworkCredential().username
        $ProcessInfo.Domain = $credential.GetNetworkCredential().Domain
        $ProcessInfo.Password = $credential.Password
        wtite-host "running as user '$($ProcessInfo.Username)'"
    }

    # build and run Process object
    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $ProcessInfo
    $Process.Start() | Out-Null
    [hashtable]$output = @{}

    if ($no_console_output) {
        $Process.WaitForExit()
        $output.stdout = $Process.StandardOutput.ReadToEnd()
    }
    else {
        while (!$Process.StandardOutput.EndOfStream) {
            $line = $null
            $line = $Process.StandardOutput.ReadLine()
            write-host $line
            $output.stdout += "$line`n"
        }
    }

    # add standard error stream and exit code to the output
    $output.stderr = $Process.StandardError.ReadToEnd()
    $output.exitcode = $Process.ExitCode
    return $output

    <#
    .SYNOPSIS
    Alias: run
    .Description
    This is a simple replacement for the PowerShell built-in Start-Process.
    Runs synchronously (that is current thread is blocked until the child process exits).
    .PARAMETER executable
    Specifies executable name or path.
    Executable must be discoverable from the command line, throws exception otherwise.
    Example: -executable cmd
    .PARAMETER arguments
    Specifies arguments to be passed to the executable as a single string.
    Example: -arguments "/C first_arg second_arg"
    .PARAMETER workdir
    Specifies directory from where executable should run.
    Directory path will be converted to absolute path and must exist, otherwise throws exception.
    Defaults to current directory.
    Example: -workdir <path/to/dir>
    .PARAMETER credential
    Specifies PSCredential to run executable in the scope of another user.
    Example: -credential <pscredential_object>
    .PARAMETER newwindow
    Allows executable to run in a new window outside of current console.
    Example: -newwindow
    .PARAMETER no_console_output
    Disables printing of child process output into the console during execution.
    By default, run-process emits output of the child process into the console
    in addition to returning to the parent process as a part of the output object.
    Example: -no_console_output
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function list-installed-software {
    param (
        [Parameter(Position = 0)][string]$name_filter = '*',
        [Parameter(Position = 1)][string]$version_filter = '*',
        [Parameter(Position = 2)][string]$publisher_filter = '*',
        [Parameter(Position = 3)][string]$hive_filter = '*',
        [Parameter(Position = 4)][string[]]$show_properties = @('name'),
        [Parameter(Position = 5)][string]$outfile
    )


    $uninstallKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')

    $registryAlias = @{
        'HKEY_LOCAL_MACHINE' = 'HKLM:'
        'HKEY_CURRENT_USER'  = 'HKCU:'
    }

    $accepted_properties = @{
        'name'             = 'DisplayName'
        'version'          = 'DisplayVersion'
        'publisher'        = 'Publisher'
        'install_location' = 'InstallLocation'
        'uninstall_string' = 'UninstallString'
        'hive'             = 'PSDrive'
    }

    $all_software = @()

    foreach ($key in $uninstallKeys) {
        $software = [array](gp $key\* -ErrorAction SilentlyContinue)
        if ($software) {
            $all_software += $software
        }
    }

    $filtered_result_set = $all_software |
    ? { $_.DisplayName.length -gt 0 } |
    ? { $_.DisplayName -like $name_filter } |
    ? { $_.DisplayVersion -like $version_filter } |
    ? { $_.Publisher -like $publisher_filter } |
    ? { $_.PSDrive -like $hive_filter }

    $sorted_result_set = $filtered_result_set | sort -Property DisplayName

    $optimized_properties = @('DisplayName')

    foreach ($property in $show_properties) {
        if ($property -eq '*') {
            $optimized_properties = @('DisplayName', 'DisplayVersion', 'Publisher', 'InstallLocation', 'UninstallString', 'PSDrive')
            break
        }
        $prop_name = $accepted_properties.$property
        if ($prop_name) {
            if ($prop_name -notin $optimized_properties) {
                $optimized_properties += $prop_name
            }
        }
        else {
            Write-Warning "skipping unknown property '$property'"
        }
    }

    $final_result_set = $sorted_result_set | select $optimized_properties

    if ($outfile) {
        $outfile = $outfile | abspath
        mkdir (Split-Path $outfile) -Force -ErrorAction Stop | Out-Null
        $final_result_set | Out-File $outfile -Force
    }
    else {
        $final_result_set
    }

    <#
    .SYNOPSIS
    Alias: listis
    .Description
    Lists software records found under following registry keys:
    - HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
    - HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
    - HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
    By default lists all records by DisplayName.
    All parameters are optional.
    .PARAMETER name_filter
    Filters results by DisplayName. Accepts wildcards '*'.
    Example: -name_filter *Java*
    .PARAMETER version_filter
    Filters results by DisplayVersion. Accepts wildcards '*'.
    Example: -version_filter 2.1.*
    .PARAMETER publisher_filter
    Filters results by Publisher. Accepts wildcards '*'.
    Example: -publisher_filter Micro*
    .PARAMETER hive_filter
    Filters results by PSDrive (which corresponds to the registry hives). Accepts wildcards '*'.
    Example: -hive_filter hklm
    .PARAMETER show_properties
    Lists software properties (comma-separated) to be incuded into the result set.
    Accepted values: 'name', 'version', 'publisher', 'install_location', 'uninstall_string', 'hive', '*'.
    If '*' specified, all supported properties will be included, no need to specify them explicitly.
    Example: -properties name, version, publisher
    .PARAMETER outfile
    Specifies file path to output result set. If not specified, result set is displayed in console instead.
    Example: -outfile app_list.txt
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function file-tabs-to-spaces {
    param(
        [Parameter(Position = 0)][string]$filepath,
        [Parameter(Position = 1)][string]$outfile = $filepath,
        [Parameter(Position = 2)][int]$tabsize = 4
    )

    $ErrorActionPreference = 'Stop'
    $converted_content = @()

    # validate input parameters
    try { $filepath_absolute = $filepath | abspath -verify }
    catch { throw "Failed to validate parameter <filepath>: $($_.ToString())" }
    if ($outfile -eq $filepath) {
        $outfile = $filepath_absolute
    }
    else {
        $outfile = $outfile | abspath
        mkdir (Split-Path $outfile) -Force | Out-Null
    }

    # process file content
    Get-Content $filepath_absolute | % {
        $line = $_
        while ( $true ) {
            $i = $line.IndexOf([char] 9)
            if ( $i -eq -1 ) { break }
            if ( $tabsize -gt 0 ) { $pad = " " * ($tabsize - ($i % $tabsize)) }
            else { $pad = "" }
            $line = $line -replace "^([^\t]{$i})\t(.*)$", "`$1$pad`$2"
        }
        $converted_content += $line
    }
    Set-Content $outfile -Value $converted_content -Force

    <#
    .Description
    Converts tabs into spaces in a file (in-place or into a new file).
    .PARAMETER filepath
    Specifies absolute or relative path to the file to be converted.
    Path will be converted to absolute path and must exist, otherwise throws exception.
    Example: -filepath <path/to/file>
    .PARAMETER outfile
    Specifies absolute or relative path to the file where to send converted content to instead of the original file.
    Missing subdirectories will be created.
    Example: -outfile <path/to/file>
    .PARAMETER tabsize
    Specifies number of spaces that constitute single tab character.
    Example: -tabsize 2
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function file-hex-dump {
    param(
        [Parameter(Position = 0)][Alias("file")][string]$filepath,
        [Parameter(Position = 1)][Alias("width")][int]$table_width = 20,
        [Parameter(Position = 2)][Alias("len")][int]$number_of_bytes = -1, # defaults to all
        [Parameter(Position = 3)][string]$outfile
    )

    $ErrorActionPreference = 'Stop'
    $OFS = ""

    # validate input parameters
    try { $filepath = $filepath | abspath -verify }
    catch { throw "Failed to validate parameter <filepath>: $($_.ToString())" }
    if ($outfile) {
        $outfile = $outfile | abspath
        mkdir (Split-Path $outfile) -Force | Out-Null
        ni $outfile -Force | Out-Null
    }

    # process file
    Get-Content -Encoding byte `
                    -Path $filepath `
                    -ReadCount $table_width `
                    -TotalCount $number_of_bytes | `
        % {
            $record = $_
            if (($record -eq 0).count -ne $table_width) {
                $hex = $record | % { " " + ("{0:x}" -f $_).PadLeft(2, "0") }
                $char = $record | `
                    % {
                        if ([char]::IsLetterOrDigit($_)) { [char] $_ }
                        else { "." }
                    }
                if ($outfile) { "$hex $char" | Out-File $outfile -Force -Append }
                else { "$hex $char" }
            }
        }

    <#
    .Description
    Generates HEX table of a file's binary data.
    .PARAMETER filepath
    Specifies absolute or relative path to the file to generate HEX table for.
    Path will be converted to absolute path and must exist, otherwise throws exception.
    Example: -filepath <path/to/file>
    .PARAMETER table_width
    Specifies width of HEX table.
    Example: -table_width 15
    .PARAMETER number_of_bytes
    Specifies amount of bytes to display. Defaults to all (-1).
    Example: -number_of_bytes 1000
    .PARAMETER outfile
    Specifies absolute or relative path to the output file where HEX table will be sent to instead of the console.
    Missing subdirectories will be created.
    Example: -outfile <path/to/file>
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function ll {
    param(
        [Parameter(Position = 0)][string]$dirpath = $PWD.path,
        [Parameter()][string]$filter = '*',
        [parameter()][ValidateSet('Name', 'Size', 'Date')][string]$sort_by = 'Name',
        [Parameter()][switch]$desc,
        [Parameter()][switch]$file,
        [Parameter()][switch]$trim_name,
        [Parameter()][switch]$force,
        [Parameter()][int]$spacer = 4
    )

    $ErrorActionPreference = 'Stop'
    # validate dirpath parameter
    try { $dirpath = $dirpath | abspath -verify }
    catch { throw "Failed to validate parameter <dirpath>: $($_.ToString())" }

    $dir_content = @()
    $sp = " " * $spacer
    switch ($sort_by) {
        'name' { $sort_attr = 'Name' }
        'size' { $sort_attr = 'Length' }
        'date' { $sort_attr = 'LastWriteTime' }
    }
    $columns_sizes = @{
        'Name'          = 0;
        'Size'          = 0;
        'LastWriteTime' = 0;
    }
    $trim_size = 38

    # natural sort for numbered items
    $to_natural = { [regex]::Replace($_, '\d+', { $args[0].Value.PadLeft(20) }) }

    # sort by Date
    if ($sort_attr -eq 'LastWriteTime') { $ls_output = ls $dirpath -Filter $filter -File:$file -Force:$force | sort $sort_attr -Descending:$(!$desc.IsPresent) }
    else {
        if (!$file) {
            # if $sort_by == 'Size', sort directories by name instead, because they all have Size == 0
            $sort_attr_dir = $sort_attr
            if ($sort_attr_dir -eq 'Length') { $sort_attr_dir = 'Name' }

            # sort directories
            if ($sort_attr_dir -eq 'Name') { $ls_output_dirs = ls $dirpath -Filter $filter -Directory -Force:$force | sort $to_natural -Descending:$desc.IsPresent }
        }

        # files
        if ($sort_attr -eq 'Name') { $ls_output_files = ls $dirpath -Filter $filter -File -Force:$force | sort $to_natural -Descending:$desc.IsPresent }
        if ($sort_attr -eq 'Length') { $ls_output_files = ls $dirpath -Filter $filter -File -Force:$force | sort $sort_attr -Descending:$desc.IsPresent }

        # concatenate all with directories first
        $ls_output = @($ls_output_dirs) + @($ls_output_files)
    }

    foreach ($item in $ls_output) {

        # make Size pretty
        $size = $null
        $unit = $null
        if ($item.Mode -notlike 'd*') {
            $size = $item.Length / 1GB
            $unit = 'GB'
            if ($size -lt 1) {
                $size = $item.Length / 1MB
                $unit = 'MB'
                if ($size -lt 1) {
                    $size = $item.Length / 1KB
                    $unit = 'KB'
                    if ($size -lt 1) {
                        $size = $item.Length
                        $unit = 'bytes'
                    }
                }
            }
        }

        # make Date pretty
        $timespan = (Get-Date -Hour 0 -Minute 0 -Second 0) - (Get-Date ($item.LastWriteTime))
        if ($timespan.TotalDays -le 0) { $datetime = "Today at " + (Get-Date $item.LastWriteTime -Format "HH:mm:ss") }
        elseif ($timespan.TotalDays -gt 0 -and $timespan.TotalDays -lt 1) { $datetime = "Yesterday at " + (Get-Date $item.LastWriteTime -Format "HH:mm:ss") }
        else { $datetime = Get-Date $item.LastWriteTime -Format "ddd, MMM dd, yyyy; HH:mm:ss" }

        $item_dict = [ordered]@{}
        $item_dict.Add('Mode', $item.Mode)
        $item_dict.Add('Name', $item.Name)
        if ($size) { $size = [math]::round($size, 2) }
        $item_dict.Add('Size', "$size $unit")
        $item_dict.Add('LastWriteTime', $datetime)
        $dir_content += $item_dict

        if ($columns_sizes.Name -lt $item.Name.Length) { $columns_sizes.Name = $item.Name.Length }
        if ($trim_name -and ($columns_sizes.Name -gt $trim_size)) { $columns_sizes.Name = $trim_size }
        if ($columns_sizes.Size -lt "$size $unit".Length) { $columns_sizes.Size = "$size $unit".Length }
    }

    # print dirictory content
    if ($dir_content.Length -gt 0) {

        # header
        $title = "Attrib" + $sp
        $title += "Name" + " " * ($columns_sizes.Name + $spacer - 4)
        $title += "Size" + " " * ($columns_sizes.Size + $spacer - 4)
        $title += "Date Modified"
        if ($title.length -gt $Host.UI.RawUI.WindowSize.Width) { $title = $title.Substring(0, $Host.UI.RawUI.WindowSize.Width) }
        write "`n$title"

        # divider
        $div_char = [string][char]9472
        $divider = $div_char * 6 + $sp
        $divider += $div_char * 4 + " " * ($columns_sizes.Name + $spacer - 4)
        $divider += $div_char * 4 + " " * ($columns_sizes.Size + $spacer - 4)
        $divider += $div_char * 13
        if ($divider.length -gt $Host.UI.RawUI.WindowSize.Width) { $divider = $divider.Substring(0, $Host.UI.RawUI.WindowSize.Width) }
        write $divider

        # list directory children
        foreach ($item in $dir_content) {
            if ($trim_name) {
                if ($item.Name.Length -gt $trim_size) { $item.Name = $item.Name.Substring(0, $trim_size - 3) + "..." }
            }
            $line = $item.Mode + $sp
            $line += $item.Name + " " * ($columns_sizes.Name + $spacer - $item.Name.Length)
            $line += $item.Size + " " * ($columns_sizes.Size + $spacer - $item.Size.Length)
            $line += $item.LastWriteTime
            if ($line.length -gt $Host.UI.RawUI.WindowSize.Width) { $line = $line.Substring(0, $Host.UI.RawUI.WindowSize.Width) }
            write $line
        }
    }

    <#
    .Description
    Cosmetic substitute for built-in Get-ChildItem command. Displays directory content in nicely formatted form.
    Only includes most common collumns. Allows to sort by each column. Does not support recursion.
    .PARAMETER dirpath
    Specifies absolute or relative path to the directory to list.
    Path will be converted to absolute path and must exist, otherwise throws exception.
    Defaults to the current directory.
    Example: -dirpath <path/to/file>
    .PARAMETER filter
    Filters included files and directories. Accepts wildcards '*'.
    Example: -filter *.ps1
    .PARAMETER sort_by
    Specifies the column to sort the result list by. By default sorts in ascending order.
    Accepted values: 'Name', 'Attrib', 'Size', 'Date' (not case-sensitive).
    Example: -sort_by size
    .PARAMETER desc
    Changes sort order to descending.
    Example: -desc
    .PARAMETER trim_name
    Trims long filenames to preset length (38 characters).
    Example: -trim_name
    .PARAMETER force
    Includes hidden files and directories.
    Example: -force
    .PARAMETER spacer
    Specifies number of spaces between columns.
    Example: -spacer 5
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function unblock-downloaded {
    param (
        [Parameter(Position = 0)][string]$dirpath,
        [Parameter(Position = 1)][switch]$recurse
    )

    if ($dirpath) { $dirpath = $dirpath | abspath -verify }
    else { $dirpath = '~\Downloads' | abspath -verify }
    ls $dirpath -File -Recurse:$recurse | Unblock-File

    <#
    .SYNOPSIS
    Alias: unb
    .Description
    Unblocks files in the "$HOME\Downloads" directory (and optionally in it's children).
    Optionally unblocks in the specified directory (and optionally in it's children).
    .PARAMETER dirpath
    If specified, unblocks files in the target directory instead of default "$HOME\Downloads".
    Example: -dirpath <some/dir>
    .PARAMETER recurse
    If specified, includes target directory children recursivly.
    Example: -recurse
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function get-dotnet-fwk-version {

    $dotnet_registry_key = "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\"

    $dotnet_releases = @{
        "378389" = "4.5";
        "378675" = "4.5.1"
        "379893" = "4.5.2";
        "393295" = "4.6";
        "394254" = "4.6.1";
        "394802" = "4.6.2";
        "460798" = "4.7";
        "461308" = "4.7.1";
        "461808" = "4.7.2";
        "528040" = "4.8"
    }

    $installed_releases = @()

    try { $release = (Get-ItemProperty $dotnet_registry_key -Name Release).Release }
    catch { error $_.exception }

    if ([int]$release -lt 378389) {
        warning ".NET 4.5 or later is not detected" -noprefix
        return ""
    }

    foreach ($key in ($dotnet_releases.Keys | sort -Descending)) {
        if ([int]$release -ge [int]$key) { return $dotnet_releases.$key }
    }

    error "Failed to determine highest .NET Framework."
    return ""

    <#
    .SYNOPSIS
    Alias: netfwk
    .Description
    Returns highest installed version of .NET framework.
    Does not accept any parameters.
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function get-fqdn {
    param (
        [Parameter()][switch] $old_notation
    )    

    if ( $old_notation ) {
        return (Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | % { $_.domain, $_.name -join ('\') })
    }

    return (Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | % { $_.name, $_.domain -join ('.') })

    <#
    .SYNOPSIS
    Alias: fqdn
    .Description
    Returns Fully Qualified Domain Name of the current host.
    Optionally returns old notation in the format "DOMAIN\COMPUTERNAME".
    .PARAMETER old_notation
    If specified, returns old notation in the format "DOMAIN\COMPUTERNAME".
    Example: -old_notation
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}



#--------------------------------------------------
Set-Alias -Name lf -Value newline -Force
Set-Alias -Name confirm -Value request-consent -Force
Set-Alias -Name jth -Value json-to-hashtable -Force
Set-Alias -Name sstp -Value ss-to-plain -Force
Set-Alias -Name isrp -Value is-restart-pending -Force
Set-Alias -Name hib -Value hibernate -Force
Set-Alias -Name wait -Value wait-any-key -Force
Set-Alias -Name fwt -Value get-files-with-text -Force
Set-Alias -Name listmc -Value list-module-commands -Force
Set-Alias -Name sql -Value run-sql -Force
Set-Alias -Name run -Value run-process -Force
Set-Alias -Name unzipf -Value extract-file -Force
Set-Alias -Name listis -Value list-installed-software -Force
Set-Alias -Name dsort -Value dir-natural-sort -Force
Set-Alias -Name unb -Value unblock-downloaded -Force
Set-Alias -Name netfwk -Value get-dotnet-fwk-version -Force
Set-Alias -Name fqdn -Value get-fqdn -Force

Export-ModuleMember -Function * -Alias *
