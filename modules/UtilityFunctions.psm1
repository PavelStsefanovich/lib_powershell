$message_padding = "  "


#--------------------------------------------------
function error {

    param(
        [string]$message
    )

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

    param(
        [int]$count = 1
    )

    Write-Host ("$message_padding`n" * $count).TrimEnd()
}


#--------------------------------------------------
function warning {

    param(
        [string]$message,
        [switch]$no_newline,
        [switch]$no_prefix
    )

    if ($no_prefix) {
        Write-Host ($message_padding + $message) -ForegroundColor Yellow -NoNewline:$no_newline
    }
    else {
        Write-Host ($message_padding + "WARNING: $message") -ForegroundColor Yellow -NoNewline:$no_newline
    }
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

    param(
        [string]$question
    )

    do {
        warning (" (?) $question ( Y: yes / N: no): ") -no_prefix
        $key = [System.Console]::ReadKey("NoEcho").key

        if ($key -notin 'Y', 'N') {
            error "It's a yes/no question."
        }
    }
    while ($key -notin 'Y', 'N')

    switch ($key) {
        'Y' { info "<yes>"; return $true }
        'N' { info "<no>"; return $false }
    }
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

    if ($MyInvocation.ScriptName -eq "") {
        throw 'Script must be saved as a .ps1 file.'
    }

    if (isadmin) {
        return $null
    }

    try {
        $script_fullpath = $MyInvocation.ScriptName

        $argline = "-noprofile -nologo -noexit"
        $argline += " -Command cd `"$current_dir`"; `"$script_fullpath`""

        if ($script_args) {
            $script_args.GetEnumerator() | % {

                if ($_.Value -is [boolean]) {
                    $argline += " -$($_.key) `$$($_.value)"
                }

                elseif ($_.Value -is [switch]) {
                    $argline += " -$($_.key)"
                }

                else {
                    $argline += " -$($_.key) `"$($_.value)`""
                }
            }
        }

        $p = Start-Process "$PSHOME\powershell.exe" -Verb Runas -ArgumentList $argline -PassThru -ErrorAction 'stop'

        if ($kill_original) {
            [System.Diagnostics.Process]::GetCurrentProcess() | Stop-Process -ErrorAction Stop
        }

        info "Elevated process id: $($p.id)"
        exit
    }
    catch {
        error "Failed to restart script with elevated premissions."
        throw $_
    }
}


#--------------------------------------------------
function jason_to_hash {
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [String] $json,

        [Parameter()]
        [Switch]$large
    )

    begin {
        try {
            Add-Type -AssemblyName "System.Web.Extensions, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" -ErrorAction Stop
        }
        catch {
            error "Unable to locate the System.Web.Extensions namespace from System.Web.Extensions.dll. Are you using .NET 4.5 or greater?"
            throw $_
        }

        $jsSerializer = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer

        if ($large) {
            $jsSerializer.MaxJsonLength = 104857600
        }
    }

    process {
        $jsSerializer.Deserialize($json, 'Hashtable')
    }

    end {
        $jsSerializer = $null
    }
}
