$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$message_padding = "  "


#--------------------------------------------------
function newline {
    param([int]$count = 1)
    Write-Host ("$message_padding`n" * $count).TrimEnd()
}


#--------------------------------------------------
function error {
    param([string]$message)
    Write-Host ($message_padding + "ERROR: $message`n") -ForegroundColor Red
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
}


#--------------------------------------------------
function request-consent {
    param([string]$question)

    do {
        warning (" (?) $question ( Y: yes / N: no): ") -no_prefix
        $key = [System.Console]::ReadKey("NoEcho").key
        if ($key -notin 'Y', 'N') { error "It's a yes/no question." }
    }
    while ($key -notin 'Y', 'N')

    switch ($key) {
        'Y' { info "<yes>"; return $true }
        'N' { info "<no>"; return $false }
    }
}


#--------------------------------------------------
function wait-any-key {
    [System.Console]::ReadKey("NoEcho").key | Out-Null
}


#--------------------------------------------------
function isadmin {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole] "Administrator")
}


#--------------------------------------------------
function restart-elevated {
    param(
        $script_args,
        [switch]$kill_original,
        [string]$current_dir = $PWD.path
    )

    if ($MyInvocation.ScriptName -eq "") { throw 'Script must be saved as a .ps1 file.' }
    if (isadmin) { return $null }

    try {
        $script_fullpath = $MyInvocation.ScriptName
        $argline = "-noprofile -nologo -noexit"
        $argline += " -Command cd `"$current_dir`"; `"$script_fullpath`""

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
}


#--------------------------------------------------
function restart-pending {
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
}


#--------------------------------------------------
function hibernate {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::SetSuspendState("Suspend", $false, $true);
}


#--------------------------------------------------
function jason-to-hashtable {
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)][AllowEmptyString()][string]$json = $(throw "Mandatory parameter not provided: <json>."),
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
}


#--------------------------------------------------
function abspath {
    param(
        [string]$parent = $pwd.Path,
        [switch]$verify
    )

    process {
        if ([System.IO.Path]::IsPathRooted($_)) { $path = $_}
        else { $path = (Join-Path $parent $_) }
        if ($verify) { $path = (Resolve-Path $path -ErrorAction Stop).Path }
        $path
    }
}


#--------------------------------------------------
function which {
    param(
        [string]$executable,
        [switch]$no_errormessage
    )

    if ($no_errormessage) { (gcm $executable -ErrorAction SilentlyContinue).Source }
    else { (gcm $executable -ErrorAction Stop).Source }
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
}


#--------------------------------------------------
function extract-file {
    param(
        [string]$name_filter,
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
}


#--------------------------------------------------
function get-files-with-text {
    param(
        [Parameter(Position = 0)][ValidateNotNullOrEmpty()][string]$search_string = $(throw "Mandatory parameter not provided: <search_string>."),
        [Parameter(Position = 1)][string]$search_dir = $($pwd.path),
        [Parameter()][string]$file_filter = "*",
        [Parameter()][switch]$not_recursevly,
        [Parameter()][switch]$regex,
        [Parameter()][switch]$open,
        [Parameter()][string]$out_file
    )

    $ErrorActionPreference = 'Stop'
    $search_dir = (Resolve-Path $search_dir).Path
    $file_list = (ls $search_dir -Recurse:$(!$not_recursevly.IsPresent) -Filter $file_filter | `
        sls -SimpleMatch:$(!$regex.IsPresent) -Pattern $search_string -List).Path

    if ($open) {
        $text_editor = which notepad++ -no_errormessage
        if (!$text_editor) { $text_editor = 'notepad.exe' }
        $file_list | % { & $text_editor $_ }
    }

    if ($out_file) {
        if ($out_file.trim().Length -eq 0) { $out_file = $(Join-Path $pwd.path 'get_files_with_text_output.txt') }
        if ($out_file -notlike '*.txt') { $out_file += '.txt' }
        $file_list | Out-File $out_file -Force
    }
    else {
        $file_list
    }
}


#--------------------------------------------------
function sha {
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)][AllowEmptyString()][string]$text_to_encrypt = $(throw "Mandatory parameter not provided: <text_to_encrypt>."),
        [parameter()][ValidateSet('256', '384', '512')][string]$algorithm = '256'
    )

    begin {
        $algorithm_name = "SHA$algorithm`Managed"
        $hasher = new-object System.Security.Cryptography.$algorithm_name
    }

    process {
        $byte_array = [System.Text.Encoding]::UTF8.GetBytes($text_to_encrypt)
        $hash_byte_array = $hasher.ComputeHash($byte_array)

        foreach ($byte in $hash_byte_array) {
            $encrypted_text += $byte.ToString()
        }

        $encrypted_text
    }

    end { $hasher = $null }
}


#--------------------------------------------------
function base64 {
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)][AllowEmptyString()][string]$text_to_convert = $(throw "Mandatory parameter not provided: <text_to_convert>."),
        [parameter()][switch]$decrypt
    )

    process {
        if ($decrypt) { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($text_to_convert)) }
        else { [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text_to_convert)) }
    }
}


#--------------------------------------------------
function ss-to-plain {
    param([Parameter(Position = 0, ValueFromPipeline = $true)][System.Security.SecureString]$s_sting = $(throw "Mandatory parameter not provided: <s_sting>."))

    process {
        $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s_sting)
        $plain_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto($pointer)
        return $plain_text
    }
}


#--------------------------------------------------

function run-sql() {
    [cmdletbinding(DefaultParameterSetName = "integrated")]
    Param (
        [Parameter(Mandatory = $false)][Alias("s")][string]$server = '.',
        [Parameter(Mandatory = $true)][Alias("d")][string]$database,
        [Parameter(Mandatory = $true, ParameterSetName = "pscred")][Alias("c")][pscredential]$credential,
        [Parameter(Mandatory = $true, ParameterSetName = "not_integrated")][Alias("u")][string]$user,
        [Parameter(Mandatory = $true, ParameterSetName = "not_integrated")][Alias("p")][securestring]$passw,
        [Parameter(Mandatory = $false, ParameterSetName = "integrated")][switch]$use_win_authentication = $true,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][Alias("q")][string]$query,
        [Parameter(Mandatory = $false)][Alias("t")][int]$timeout = 0,
        [Parameter(Mandatory = $true)][Alias("o")][string]$out_file,
        [Parameter(Mandatory = $false)][Alias("n")][switch]$no_success_message
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
}


#--------------------------------------------------
function run-process {
    param (
        [Parameter()][Alias("e")][string]$executable_path = $(throw "Mandatory parameter not provided: <executable_path>."),
        [Parameter()][Alias("a")][string]$arguments,
        [Parameter()][Alias("w")][string]$working_directory = $PWD.path,
        [Parameter()][Alias("c")][PSCredential]$credential,
        [Parameter()][Alias("nc")][switch]$no_console_output
    )

    $ErrorActionPreference = 'Stop'

    # resolve executable path
    $resolved_exe_path = which $executable_path -no_errormessage
    if ($resolved_exe_path) { $executable_path = $resolved_exe_path }
    else {
        try { $executable_path = $executable_path | abspath -verify }
        catch { throw "Failed to validate parameter <executable_path>: $($_.ToString())" }
    }

    # resolve working_directory
    try { $working_directory = $working_directory | abspath -verify }
    catch { throw "Failed to validate parameter <working_directory>: $($_.ToString())" }

    # build ProcessStartInfo object
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = "$executable_path"
    $ProcessInfo.WorkingDirectory = $working_directory
    $ProcessInfo.CreateNoWindow = $true
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

    if ($no_console_output) { $Process.WaitForExit() }
    else {
        while (!$Process.StandardOutput.EndOfStream) {
            write-host $Process.StandardOutput.ReadLine()
        }
    }

    # create output hashtable
    [hashtable]$output = @{}
    $output.stdout = $Process.StandardOutput.ReadToEnd()
    $output.stderr = $Process.StandardError.ReadToEnd()
    $output.errcode = $Process.ExitCode

    return $output
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
    https://github.com/PavelStsefanovich/lib_powershell
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
Set-Alias -Name confirm -Value request-consent -Force
Set-Alias -Name isrp -Value restart-pending -Force
Set-Alias -Name hib -Value hibernate -Force
Set-Alias -Name wait -Value wait-any-key -Force
Set-Alias -Name fwt -Value get-files-with-text -Force
Set-Alias -Name listmc -Value list-module-commands -Force
Set-Alias -Name sql -Value run-sql -Force
Set-Alias -Name run -Value run-process -Force
Set-Alias -Name unzipf -Value extract-file -Force
Set-Alias -Name listis -Value list-installed-software -Force
Set-Alias -Name sortn -Value dir-natural-sort -Force

Export-ModuleMember -Function * -Alias *
