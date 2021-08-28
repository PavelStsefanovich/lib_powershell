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
        [switch]$no_newline,
        [switch]$success
    )

    $color = 'Gray'
    if ($success) { $color = 'Green' }
    Write-Host ($message_padding + $message) -ForegroundColor $color -NoNewline:$no_newline

    <#
    .Description
    Prints info message into the console. Optionally colors text green and omits trailing newline.
    .PARAMETER message
    Message to display.
    Example: -message "Some info."
    .PARAMETER no_newline
    Omits trailing newline, so the next console output will be printed to the same line.
    Example: -no_newline
    .PARAMETER success
    Colors message text green.
    Example: -success
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function warning {
    param(
        [string]$message,
        [switch]$no_newline,
        [switch]$no_prefix
    )

    if ($no_prefix) { Write-Host ($message_padding + $message) -ForegroundColor Yellow -NoNewline:$no_newline }
    else { Write-Host ($message_padding + "WARNING: $message") -ForegroundColor Yellow -NoNewline:$no_newline }

    <#
    .Description
    Prints warning message into the console following defined format: "WARNING: <message>" and colors it yellow.
    Optionally omits 'WARNING' prefix and trailing newline.
    .PARAMETER message
    Message to display.
    Example: -message "Note something!"
    .PARAMETER no_newline
    Omits trailing newline, so the next console output will be printed to the same line.
    Example: -no_newline
    .PARAMETER no_prefix
    Omits 'WARNING:' prefix.
    Example: -no_prefix
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function request-consent {
    param([string]$question)

    do {
        warning (" (?) $question ( y/n ): ") -no_prefix
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
        $script_args,
        [switch]$kill_original,
        [string]$working_directory = $PWD.path
    )

    if ($MyInvocation.ScriptName -eq "") { throw 'Script must be saved as a .ps1 file.' }
    if (isadmin) { return $null }

    try {
        $script_fullpath = $MyInvocation.ScriptName
        $argline = "-noprofile -nologo -noexit"
        $argline += " -Command cd `"$working_directory`"; `"$script_fullpath`""

        if ($script_args) {
            $script_args.GetEnumerator() | % {
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
    .PARAMETER script_args
    Arguments to be passed to the elevated script.
    Example: -script_args $PSBoundParameters
    .PARAMETER kill_original
    Kills original (non-admin) script/console when elevated script has started.
    Example: -kill_original
    .PARAMETER working_directory
    Specifies directory where elevated script should be started. Defaults to current directory.
    Example: -working_directory <some/path>
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
        if ([System.IO.Path]::IsPathRooted($path)) { $abspath = $path}
        else { $abspath = (Join-Path ($parent | abspath) $path) }
        if ($verify) { $abspath = (Resolve-Path $abspath -ErrorAction Stop).Path }
        $abspath
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
        [string]$executable,
        [switch]$no_errormessage
    )

    if ($no_errormessage) { (gcm $executable -ErrorAction SilentlyContinue).Source }
    else { (gcm $executable -ErrorAction Stop).Source }

    <#
    .Description
    Returns executable's source path if it's discoverable from the command line, throws exception otherwise.
    Optionally returns Null instead of throwing exception.
    .PARAMETER executable
    Specifies executable name (<base_name> or <base_name>.exe) to lookup.
    Example: -executable <executable_name>
    .PARAMETER no_errormessage
    Returns Null instead of throwing exception in case executable source path cannot be resolved.
    Example: -no_errormessage
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function list-module-commands {
    param(
        [Parameter(Position = 0)][ValidateNotNullOrEmpty()][string]$module_name = $(throw "Mandatory parameter not provided: <module_name>."),
        [Parameter()][switch]$as_hashtable
    )

    if (!(Get-Module $module_name)) { throw "Module not found: `"$module_name`""}
    $commands_map = @{}
    $max_length = 0

    (Get-Command -Module $module_name).name | `
        % {
            $commands_map.add($_, (Get-Alias -Definition $_ -ErrorAction SilentlyContinue))
            if ($_.length -gt $max_length) { $max_length = $_.length }
        }

    if ($as_hashtable) { return $commands_map }
    $commands_map.keys | sort | %{
        $line = " $_"
        if ($commands_map.$_) { $line += " "*(($max_length + 5) - $_.length) + "--> $($commands_map.$_)" }
        write $line
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
        [string]$from_dir,
        [string]$zip_path,
        [parameter()][ValidateSet('Optimal','Fastest','NoCompression')][string]$compression = 'Optimal',
        [switch]$include_basedir
    )

    try { $from_dir = $from_dir | abspath -verify }
    catch { throw "Failed to validate parameter <from_dir>: $($_.ToString())" }
    $zip_path = $zip_path | abspath
    mkdir (Split-Path $zip_path) -Force -ErrorAction stop | Out-Null
    Add-Type -AssemblyName "system.io.compression.filesystem"
    [io.compression.zipfile]::CreateFromDirectory($from_dir, $zip_path, $compression, $include_basedir.IsPresent)

    <#
    .Description
    Compresses a directory into .zip archive.
    Optionally includes target directory as a root directory in the archive.
    .PARAMETER from_dir
    Specifies absolute or relative path to the directory to be compressed.
    Path will be converted to absolute path and must exist, otherwise throws exception.
    Example: -from_dir <path/to/dir>
    .PARAMETER zip_path
    Specifies absolute or relative path to the output .zip file.
    Missing subdirectories will be created.
    Example: -zip_path <path/to/file.zip>
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
        [string]$zip_path,
        [string]$to_dir
    )

    try { $zip_path = $zip_path | abspath -verify }
    catch { throw "Failed to validate parameter <zip_path>: $($_.ToString())" }
    $to_dir = $to_dir | abspath
    mkdir (Split-Path $to_dir) -Force -ErrorAction stop | Out-Null
    Add-Type -AssemblyName "system.io.compression.filesystem"
    [io.compression.zipfile]::ExtractToDirectory($zip_path, $to_dir)

    <#
    .Description
    Extracts .zip archive into a directory.
    .PARAMETER zip_path
    Specifies absolute or relative path to the .zip file.
    Path will be converted to absolute path and must exist, otherwise throws exception.
    Example: -zip_path <path/to/file.zip>
    .PARAMETER to_dir
    Specifies absolute or relative path to the directory to be compressed.
    Missing subdirectories will be created.
    Example: -to_dir <path/to/dir>
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function extract-file {
    param(
        [string]$file_filter,
        [string]$zip_path,
        [string]$to_dir = $($PWD.path)
    )

    try { $zip_path = $zip_path | abspath -verify }
    catch { throw "Failed to validate parameter <zip_path>: $($_.ToString())" }
    $to_dir = $to_dir | abspath
    mkdir $to_dir -Force -ErrorAction stop | Out-Null
    [Reflection.Assembly]::LoadWithPartialName( "System.IO.Compression.FileSystem" ) | Out-Null
    $zipstream = [System.IO.Compression.ZipFile]::OpenRead($zip_path)

    foreach ($zipfile in $zipstream.Entries) {
        if ($zipfile.Name -like $name_filter) {
            $destination_file_path = Join-Path $to_dir $zipfile.Name
            $filestream = New-Object IO.FileStream ($destination_file_path) , 'Append', 'Write', 'Read'
            $file = $zipfile.Open()
            $file.CopyTo($filestream)
            $file.Close()
            $filestream.Close()
        }
    }

    <#
    .SYNOPSIS
    Alias: unzipf
    .Description
    Extracts files that match filter from .zip archive into a directory.
    .PARAMETER file_filter
    Specifies mask to filter file names in the .zip archive.
    Accepts wildcards "*".
    Example: -file_filter <*.txt>
    .PARAMETER zip_path
    Specifies absolute or relative path to the .zip file.
    Path will be converted to absolute path and must exist, otherwise throws exception.
    Example: -zip_path <path/to/file.zip>
    .PARAMETER to_dir
    Specifies absolute or relative path to the directory to be compressed.
    Missing subdirectories will be created.
    Example: -to_dir <path/to/dir>
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
        [Parameter(Position = 1)][string]$search_dir = $($pwd.path),
        [Parameter()][string]$file_filter = "*",
        [Parameter()][switch]$not_recursevly,        
        [Parameter()][switch]$open,
        [Parameter()][string]$out_file = "list_of_files_with_text.txt"
    )

    $ErrorActionPreference = 'Stop'

    # validate <search_dir> path
    try { $search_dir = $search_dir | abspath -verify }
    catch { throw "Failed to validate parameter <search_dir>: $($_.ToString())" }

    # search text/pattern in files
    if ($PSCmdlet.ParameterSetName -eq "plain") { $search_string = $text }
    else { $search_string = $regex }
    $file_list = (ls $search_dir -Recurse:$(!$not_recursevly.IsPresent) -Filter $file_filter | `
        sls -SimpleMatch:$($PSCmdlet.ParameterSetName -eq "plain") -Pattern $search_string -List).Path

    if ($open) {
        $text_editor = which notepad++ -no_errormessage
        if (!$text_editor) { $text_editor = 'notepad.exe' }
        $file_list | % { & $text_editor $_ }
    }

    if ($out_file) {
        $out_file = $out_file | abspath
        mkdir (Split-Path $out_file) -Force | Out-Null
        $file_list | Out-File $out_file -Force
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
    .PARAMETER search_dir
    Specifies absolute or relative path to the search root directory.
    Path will be converted to absolute path and must exist, otherwise throws exception.
    Example: -search_dir <path/to/dir>
    .PARAMETER file_filter
    Specifies mask to filter file names in the search directory and subdirectories.
    Accepts wildcards "*".
    Example: -file_filter <*.txt>
    .PARAMETER not_recursevly
    Limits search to only search root directory without subdirectories.
    Example: -not_recursevly
    .PARAMETER open
    Opens found paths in the Notepad++ (or Windows notepad if Notepad++ is not available).
    Example: -open
    .PARAMETER out_file
    Specifies absolute or relative path to the output file where results will be sent instead of the console.
    Missing subdirectories will be created.
    Example: -out_file <path/to/file>
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function sha {
    [cmdletbinding(DefaultParameterSetName = "text")]
    param(
        [Parameter(ParameterSetName = "text", Position = 0, ValueFromPipeline = $true)][AllowEmptyString()]
        [Alias("text")][string]$text_to_hash,
    
        [Parameter(ParameterSetName = "file", Position = 0)][ValidateNotNullOrEmpty()]
        [Alias("file")][string]$file_to_hash,
        
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
            try { $file_to_hash = $file_to_hash | abspath -verify }
            catch { throw "Failed to validate parameter <file_to_hash>: $($_.ToString())" }
            $byte_array = [System.IO.File]::ReadAllBytes($file_to_hash)
        }
        else { $byte_array = [System.Text.Encoding]::UTF8.GetBytes($text_to_hash) }
        
        $hash_byte_array = $hasher.ComputeHash($byte_array)
        $hash_byte_array | % { $hash_string += $_.ToString() }
        "$algorithm_prefix $hash_string"
    }

    end { $hasher = $null }

    <#
    .Description
    Generates hash for text or file using SHA- algorithm of choice. Defaults to SHA256.
    .PARAMETER text_to_hash
    Specifies text to be hashed. Allows ValueFromPipeline.
    Example 1: sha -text "some text"
    Example 2: "some text" | sha
    .PARAMETER file_to_hash
    Specifies absolute or relative path to the file for which hash string will be generated.
    Path will be converted to absolute path and must exist, otherwise throws exception.
    Example: -file_to_hash <path/to/file>
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
        [Parameter(Position = 0, ValueFromPipeline = $true)][AllowEmptyString()][Alias("text")][string]$text_to_encrypt,
        [parameter()][switch]$decrypt
    )

    process {
        if ($decrypt) { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($text_to_encrypt)) }
        else { [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text_to_encrypt)) }
    }

    <#
    .Description
    Encrypts or decrypts text using base64 encryption algorithm.
    .PARAMETER text_to_encrypt
    Specifies text to be encrypted. Allows ValueFromPipeline. This is default option.
    Example 1: base64 -text_to_encrypt "some text"
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
    param([Parameter(Position = 0, ValueFromPipeline = $true)][System.Security.SecureString]$s_sting)

    process {
        $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s_sting)
        $plain_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto($pointer)
        return $plain_text
    }

    <#
    .SYNOPSIS
    Alias: sstp
    .Description
    Converts [SecureString] object into plain text.
    .PARAMETER s_sting
    Specifies [SecureString] object to be converted.
    Example 1: ss-to-plain -s_sting $sstring
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
        [Parameter(ParameterSetName = "integrated")][switch]$use_win_authentication = $true,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][Alias("q")][string]$query,
        [Parameter()][Alias("t")][int]$timeout = 0,
        [Parameter(Mandatory = $true)][Alias("o")][string]$out_file,
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
    if ($out_file) {
        $out_file = $out_file | abspath
        mkdir (Split-Path $out_file) -Force | Out-Null
        $output | Out-File $out_file -Force
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
    .PARAMETER use_win_authentication
    This is default option that is used if neither credential nor username/password specified.
    No need to use explicitly.
    .PARAMETER query
    Specifies SQL query to execute against remote database server.
    Example: -query "select * from <tab_name>"
    .PARAMETER timeout
    Specifies SQL command timeout in seconds.
    Example: -timeout 10
    .PARAMETER out_file
    Specifies absolute or relative path to the output file where results will be sent instead of the console.
    Missing subdirectories will be created.
    Example: -out_file <path/to/file>
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
        [Parameter()][Alias("w")][string]$working_directory = $PWD.path,
        [Parameter()][Alias("c")][PSCredential]$credential,
        [Parameter()][Alias("nw")][switch]$create_new_window,
        [Parameter()][Alias("nc")][switch]$no_console_output
    )

    $ErrorActionPreference = 'Stop'

    # resolve executable path
    $resolved_exe_path = which $executable -no_errormessage
    if ($resolved_exe_path) { $executable = $resolved_exe_path }
    else {
        try { $executable = $executable | abspath -verify }
        catch { throw "Failed to validate parameter <executable>: $($_.ToString())" }
    }

    # resolve working_directory
    try { $working_directory = $working_directory | abspath -verify }
    catch { throw "Failed to validate parameter <working_directory>: $($_.ToString())" }

    # build ProcessStartInfo object
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = "$executable"
    $ProcessInfo.WorkingDirectory = $working_directory
    $ProcessInfo.CreateNoWindow = !$create_new_window.IsPresent
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

    # add standard error stream and exit code
    $output.stderr = $Process.StandardError.ReadToEnd()
    $output.errcode = $Process.ExitCode

    return $output
        [Parameter()][Alias("e")][string]$executable = $(throw "Mandatory parameter not provided: <executable>."),
        [Parameter()][Alias("a")][string]$arguments,
        [Parameter()][Alias("w")][string]$working_directory = $PWD.path,
        [Parameter()][Alias("c")][PSCredential]$credential,
        [Parameter()][Alias("nw")][switch]$create_new_window,
        [Parameter()][Alias("nc")][switch]$no_console_output
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
    .PARAMETER working_directory
    Specifies directory from where executable should run.
    Directory path will be converted to absolute path and must exist, otherwise throws exception.
    Defaults to current directory.
    Example: -working_directory <path/to/dir>
    .PARAMETER credential
    Specifies PSCredential to run executable in the scope of another user.
    Example: -credential <pscredential_object>
    .PARAMETER create_new_window
    Allows executable to run in a new window outside of current console.
    Example: -create_new_window
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
        [Parameter(Position = 5)][string]$out_file
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

    if ($out_file) {
        $out_file = $out_file | abspath
        mkdir (Split-Path $out_file) -Force -ErrorAction Stop | Out-Null
        $final_result_set | Out-File $out_file -Force
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
    .PARAMETER out_file_path
    Specifies file path to output result set. If not specified, result set is displayed in console instead.
    Example: -out_file_path app_list.txt
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions
    #>
}


#--------------------------------------------------
function file-tabs-to-spaces {
    param(
        [Parameter(Position = 0)][string]$file_path,
        [Parameter(Position = 1)][string]$out_file = $file_path,
        [Parameter(Position = 2)][int]$tab_size = 4
    )

    $ErrorActionPreference = 'Stop'
    $converted_content = @()

    # validate input parameters
    try { $file_path_absolute = $file_path | abspath -verify }
    catch { throw "Failed to validate parameter <file_path>: $($_.ToString())" }
    if ($out_file -eq $file_path) {
        $out_file = $file_path_absolute
    }
    else {
        $out_file = $out_file | abspath
        mkdir (Split-Path $out_file) -Force | Out-Null
    }

    # process file content
    Get-Content $file_path_absolute | % {
        $line = $_
        while ( $true ) {
            $i = $line.IndexOf([char] 9)
            if ( $i -eq -1 ) { break }
            if ( $tab_size -gt 0 ) { $pad = " " * ($tab_size - ($i % $tab_size)) }
            else { $pad = "" }
            $line = $line -replace "^([^\t]{$i})\t(.*)$", "`$1$pad`$2"
        }
        $converted_content += $line
    }
    Set-Content $out_file -Value $converted_content -Force
}


#--------------------------------------------------
function file-hex-dump {
    param(
        [Parameter(Position = 0)][Alias("file")][string]$file_path,
        [Parameter(Position = 1)][Alias("width")][int]$table_width = 20,
        [Parameter(Position = 2)][Alias("len")][int]$number_of_bytes = -1, # defaults to all
        [Parameter(Position = 3)][string]$out_file
    )

    $ErrorActionPreference = 'Stop'
    $OFS = ""

    # validate input parameters
    try { $file_path = $file_path | abspath -verify }
    catch { throw "Failed to validate parameter <file_path>: $($_.ToString())" }
    if ($out_file) {
        $out_file = $out_file | abspath
        mkdir (Split-Path $out_file) -Force | Out-Null
        ni $out_file -Force | Out-Null
    }

    # process file
    Get-Content -Encoding byte `
                    -Path $file_path `
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
                if ($out_file) { "$hex $char" | Out-File $out_file -Force -Append }
                else { "$hex $char" }
            }
        }
}


#--------------------------------------------------
function dir-natural-sort {
    param (
        [Parameter(Position = 0)][string]$dir_path = $($PWD.path),
        [Parameter(Position = 5)][string]$out_file
    )

    try { $dir_path = $dir_path | abspath -verify }
    catch { throw "Failed to validate parameter <dir_path>: $($_.ToString())" }
    $to_natural = { [regex]::Replace($_, '\d+', { $args[0].Value.PadLeft(20) }) }
    $output = ls | sort $to_natural

    if ($out_file) {
        $out_file = $out_file | abspath
        mkdir (Split-Path $out_file) -Force -ErrorAction Stop | Out-Null
        $output | Out-File $out_file -Force
    }
    else {
        $output
    }
}


#--------------------------------------------------
function ll {
    param(
        [Parameter(Position = 0)][string]$filter = '*',
        [parameter()][ValidateSet('Name', 'Attrib', 'Size', 'Date')][string]$sort_by = 'Name',
        [Parameter()][switch]$desc,
        [Parameter()][int]$spacer_size = 4
    )

    $dir_content = @()
    $sp = " " * $spacer_size
    switch ($sort_by) {
        'name' { $sort_attr = 'Name' }
        'attrib' { $sort_attr = 'Mode' }
        'size' { $sort_attr = 'Length' }
        'date' { $sort_attr = 'LastWriteTime' }
    }
    $columns_sizes = @{
        'Name'          = 0;
        'Size'          = 0;
        'LastWriteTime' = 0;
    }

    foreach ($item in (ls -Filter $filter | sort $sort_attr -Descending:$desc.IsPresent )) {
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

        $item_dict = [ordered]@{}
        $item_dict.Add('Mode', $item.Mode)
        $item_dict.Add('Name', $item.Name)
        if ($size) { $size = [math]::round($size, 2) }
        $item_dict.Add('Size', "$size $unit")
        $item_dict.Add('LastWriteTime', $item.LastWriteTime)
        $dir_content += $item_dict

        if ($columns_sizes.Name -lt $item.Name.Length) { $columns_sizes.Name = $item.Name.Length }
        if ($columns_sizes.Size -lt "$size $unit".Length) { $columns_sizes.Size = "$size $unit".Length }
    }

    if ($dir_content.Length -gt 0) {
        $title = "Attrib" + $sp
        $title += "Name" + " " * ($columns_sizes.Name + $spacer_size - 4)
        $title += "Size" + " " * ($columns_sizes.Size + $spacer_size - 4)
        $title += "Date Modified"
        if ($title.length -gt $Host.UI.RawUI.WindowSize.Width) { $title = $title.Substring(0, $Host.UI.RawUI.WindowSize.Width) }
        write "`n$title"

        $div_char = [string][char]9472
        $divider = $div_char * 6 + $sp
        $divider += $div_char * 4 + " " * ($columns_sizes.Name + $spacer_size - 4)
        $divider += $div_char * 4 + " " * ($columns_sizes.Size + $spacer_size - 4)
        $divider += $div_char * 13
        if ($divider.length -gt $Host.UI.RawUI.WindowSize.Width) { $divider = $divider.Substring(0, $Host.UI.RawUI.WindowSize.Width) }
        write $divider

        foreach ($item in $dir_content) {
            $line = $item.Mode + $sp
            $line += $item.Name + " " * ($columns_sizes.Name + $spacer_size - $item.Name.Length)
            $line += $item.Size + " " * ($columns_sizes.Size + $spacer_size - $item.Size.Length)
            $line += $item.LastWriteTime
            if ($line.length -gt $Host.UI.RawUI.WindowSize.Width) { $line = $line.Substring(0, $Host.UI.RawUI.WindowSize.Width) }
            write $line
        }
    }

    <#
    .Description
    Cosmetic substitute for built-in Get-ChildItem command. Displays directory content in nicely formatted form.
    Only includes most common collumns. Allows to sort by each column. Does not support recursion.
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
    .PARAMETER spacer_size
    Specifies number of spaces between columns.
    Example: -spacer_size 5
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

Export-ModuleMember -Function * -Alias *
