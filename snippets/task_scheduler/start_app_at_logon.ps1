[CmdletBinding()]
param (
    [string]$executable_path,
    [string]$task_name
)

# This requires admin privileges.
# Otherwise change: "-Runlevel Limited"

$action = New-ScheduledTaskAction -Execute $executable_path
$settings = New-ScheduledTaskSettingsSet -Compatibility Win8 `
                                         -AllowStartIfOnBatteries `
                                         -DontStopIfGoingOnBatteries `
                                         -DisallowDemandStart `
                                         -RestartCount 1 `
                                         -RestartInterval (New-TimeSpan -Minutes 1) `
                                         -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
                                         -StartWhenAvailable
$current_user = $env:USERDOMAIN, $env:USERNAME -join ('\')
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $current_user
$principal = New-ScheduledTaskPrincipal -UserId $current_user -RunLevel Highest -LogonType Interactive

# check if scheduled task exists already
$task = Get-ScheduledTask $task_name -ErrorAction SilentlyContinue
if ($task) {
    # Options:
    # throw "Task `"$task_name`" already registered."
    Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
}

$new_task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings
Register-ScheduledTask $task_name -InputObject $new_task | Out-Null
