$message_padding = "  "


#--------------------------------------------------
function error {
    param([string]$message)
    Write-Host ($message_padding + "ERROR: $message`n") -ForegroundColor Red
}


#--------------------------------------------------
function info {
    param(
        [string]$message,
        [switch]$no_newline
    )
    Write-Host ($message_padding + $message) -ForegroundColor Gray -NoNewline:$no_newline
}


#--------------------------------------------------
function newline {
    param([int]$count = 1)
    Write-Host ("$message_padding`n" * $count).TrimEnd()
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
function confirm {
    param(
        [string]$message,
        [switch]$no_newline
    )
    Write-Host ($message_padding + $message) -ForegroundColor Green -NoNewline:$no_newline
}


#--------------------------------------------------
function request_consent {
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
function wait_anykey {
    [System.Console]::ReadKey("NoEcho").key | Out-Null
}


#--------------------------------------------------
function isadmin {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole] "Administrator")
}


#--------------------------------------------------
function restart_elevated {
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
function restart_pending {
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
function jason_to_hsht {
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [String]$json,

        [Parameter()]
        [Switch]$large
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
function zip {
    param(
        [string]$from_dir,
        [string]$zip_path,
        [switch]$create_path,
        [parameter()][ValidateSet('Optimal','Fastest','NoCompression')][string]$compression = 'Optimal',
        [switch]$include_basedir
    )

    $from_dir = $from_dir | abspath
    $zip_path = $zip_path | abspath -verify:$(!$create_path.IsPresent)
    if ($create_path) { mkdir (Split-Path $zip_path) -Force | Out-Null }
    Add-Type -AssemblyName "system.io.compression.filesystem"
    [io.compression.zipfile]::CreateFromDirectory($from_dir, $zip_path, $compression, $include_basedir.IsPresent)
}


#--------------------------------------------------
function unzip {
    param(
        [string]$zip_path,
        [string]$to_dir,
        [switch]$create_path
    )

    $zip_path = $zip_path | abspath
    $to_dir = $to_dir | abspath -verify:$(!$create_path.IsPresent)
    Add-Type -AssemblyName "system.io.compression.filesystem"
    [io.compression.zipfile]::ExtractToDirectory($zip_path, $to_dir)
}


#--------------------------------------------------
function get_files_with_text {
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$search_string,

        [Parameter(
            Mandatory = $false,
            Position = 1)]
        [string]$search_dir = $($pwd.path),

        [Parameter()][string]$file_filter = "*",
        [Parameter()][switch]$not_recursevly,
        [Parameter()][switch]$regex,
        [Parameter()][switch]$open,
        [Parameter()][string]$dump_file
    )

    $ErrorActionPreference = 'Stop'
    $search_dir = (Resolve-Path $search_dir).Path
    $file_list = (ls $search_dir -Recurse:$(!$not_recursevly.IsPresent) -Filter $file_filter | `
        sls -SimpleMatch:$(!$regex.IsPresent) -Pattern $search_string -List).Path
    
    if ($open) {
        $text_editor = 'notepad.exe'
        if (Test-Path 'C:\Program Files\Notepad++\notepad++.exe') { $text_editor = 'C:\Program Files\Notepad++\notepad++.exe' }
        $file_list | % { & $text_editor $_ }
    }
    
    if ($dump_file) {
        if ($dump_file.trim().Length -eq 0) { $dump_file = $(Join-Path $pwd.path 'get_files_with_text_output.txt') }
        if ($dump_file -notlike '*.txt') { $dump_file += '.txt' }
        $file_list | Out-File $dump_file -Force -Encoding ascii
    }
    else {
        $file_list
    }
}


#--------------------------------------------------
function sha {
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [String] $text_to_encrypt,

        [parameter(Mandatory = $false)]
        [ValidateSet('256', '384', '512')]
        [string]$algorithm = '256'
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
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [String] $text_to_convert,

        [parameter(Mandatory = $false)]
        [switch]$decrypt
    )

    begin {}

    process {
        if ($decrypt) { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($text_to_convert)) }
        else { [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text_to_convert)) }
    }

    end {}
}





# Set-Alias -Name ics -Value Invoke-ComputerSleep
# Set-Alias -Name isr -Value Test-RestartRequired
# Set-Alias -Name ask -Value Request-Consent
# Set-Alias -Name wait -Value Wait-AnyKey
# Set-Alias -Name abspath -Value Get-AbsolutePath

# Export-ModuleMember -Function * -Alias *