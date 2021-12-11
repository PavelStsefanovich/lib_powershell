[CmdletBinding()]
param (
    [string]$computer_name = $(throw 'Mandatory parameter not provided: <computer_name>'),
    [string]$user,
    [string]$passw,
    [string]$scheduled_task_name = $(throw 'Mandatory parameter not provided: <scheduled_task_name>')
)

$ErrorActionPreference = 'stop'

$scheduled_task_file_name = $scheduled_task_name + '.xml'
$scheduled_task_file_path = (ls $PSScriptRoot -Recurse -Include $scheduled_task_file_name).Fullname

if (!$scheduled_task_file_path)
{
    throw "Scheduled task config xml '$scheduled_task_file_name' not found in current directory or it's children"
}

if ($scheduled_task_file_path -is [array])
{
    write-warning "More than one config xml found for scheduled task '$scheduled_task_name':"
    $scheduled_task_file_path | %{
        write-warning "  $_"
    }
    write-warning "Exiting"
    exit
}

$task_config = cat $scheduled_task_file_path | out-string
write-verbose "<scheduled_task_file_path> : '$scheduled_task_file_path'"

$computer_name = $computer_name.replace('.athocdevo.com','') + '.athocdevo.com'
write-verbose "<computer_name> : '$computer_name'"

write "Registering task '$scheduled_task_name' on target machine: '$computer_name'"

try
{
    if ($user -and $passw)
    {
        write-verbose "<user> : '$user'"
        write-verbose "<password : '********'"
        Invoke-Command -ComputerName $computer_name -ScriptBlock {Register-ScheduledTask -Xml $args[0] -TaskName $args[1] -User $args[2] -Password $args[3]} -ArgumentList @($task_config, $scheduled_task_name, $user, $passw)
    }
    else
    {
        write-verbose "<user> or <passw> not specified; running without credentials"
        Invoke-Command -ComputerName $computer_name -ScriptBlock {Register-ScheduledTask -Xml $args[0] -TaskName $args[1]} -ArgumentList @($task_config, $scheduled_task_name)
    }
}
catch
{
    if ($_.CategoryInfo.Category -eq 'ResourceExists')
    {
        write-warning "Scheduled task '$scheduled_task_name' already registered on target machine: '$computer_name'"
        write-warning "Exiting"
        exit
    }

    throw $_
}