function continue_after_restart {
    param(
        [string]$scriptpath,
        [hashtable]$arguments,
        [string]$working_directory,
        [string]$task_name
    )

    $ErrorActionPreference = 'stop'

    try {
        if (!$task_name) {
            $task_name = "runafterrestart", (Split-Path $scriptpath -Leaf) -join('_')
        }

        Unregister-ScheduledTask -TaskName $task_name -Confirm:$false -ErrorAction SilentlyContinue

        $argstring = "-NoProfile -NoLogo -NoExit -ExecutionPolicy Bypass -Command `"& '$scriptpath'"
        $arguments.GetEnumerator() | % { $argstring += " -$($_.key) '$($_.value)'" }
        $argstring += '"'

        if ($working_directory) {
            $action = New-ScheduledTaskAction -Execute (gcm powershell).Source -Argument $argstring -WorkingDirectory $working_directory
        }
        else {
            $action = New-ScheduledTaskAction -Execute (gcm powershell).Source -Argument $argstring
        }

        $user = $env:USERDOMAIN, $env:USERNAME -join ('\')
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $user
        $principal = New-ScheduledTaskPrincipal -UserId $user -RunLevel Highest -LogonType Interactive
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings
        Register-ScheduledTask $task_name -InputObject $task | out-null

        return $task_name
    }
    catch {
        Write-Error "ERROR: Failed to register scheduled task."
        throw $_
    }
}