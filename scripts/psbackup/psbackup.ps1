[cmdletbinding(
    HelpUri = "",
    DefaultParameterSetName = "run"
)]
param (
    [Parameter(ParameterSetName = "run")]
    [switch]$run_backup,

    [Parameter(ParameterSetName = "install")]
    [switch]$set_scheduled_task,

    [Parameter(ParameterSetName = "uninstall")]
    [switch]$unset_scheduled_task
)



##########  MAIN  ###############################################

#--------------------------------------------------
# INIT
$ErrorActionPreference = 'Stop'
$host.PrivateData.ErrorBackgroundColor = $host.UI.RawUI.BackgroundColor
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$SCRIPT_FULL_PATH = $PSCommandPath
$backup_config_file_name = '.psbkp.yaml'
$backup_prefix = 'psbkp-'
$scheduled_task_name = 'psbackup-3dc85598-4690-4337-b053-4087151c4de6'
$current_title = (Get-Host).UI.RawUI.WindowTitle.Clone()
(Get-Host).UI.RawUI.WindowTitle = " PSBACKUP    v0.1.0    https://github.com/PavelStsefanovich/lib_powershell"
if (! ($set_scheduled_task -or $unset_scheduled_task )) {
    $sound = New-Object System.Media.SoundPlayer
    $sound.SoundLocation = 'C:\Windows\Media\Windows Background.wav'
    try { $sound.Play() } catch {}
}


#--------------------------------------------------
# CHECK USER PRIVILIGES
if (! (isadmin)) {
    newline
    error "This script must run as administrator."
    exit 1
}


#--------------------------------------------------
# DEPENDENCIES
$dependencies = @{
    'UtilityFunctions' = 'https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions';
    'powershell-yaml' = 'https://www.powershellgallery.com/packages/powershell-yaml'
}

foreach ($module_name in $dependencies.Keys) {
    try {Import-Module $module_name -DisableNameChecking -Force -ErrorAction Stop }
    catch {
        write-host " "
        $warning  = "Dependency module not found: `"$module_name`"`n"
        $warning += "You can install it with the following command (must run as admin):`n"
        $warning += " > Install-Module `"$module_name`" -SkipPublisherCheck -Force"
        write-warning $warning
        Write-Host  "More info about the module can be found here:"
        Write-Host  " $($dependencies.$module_name)`n"
        exit 1
    }
}


#--------------------------------------------------
# CONFIRMATION TO PROCEED WITH BACKUP
if (! ($set_scheduled_task -or $unset_scheduled_task )) {
    newline
    info "Starting PS Backup."
    info " - connect your Backup Drive" -sub
    info " - make sure file `"$backup_config_file_name`" is located in the root of the Backup Drive" -sub
    info " - hit 'y' when ready" -sub
    if (! (confirm "Run backup?")) {
        warning "cancelled by user"
        exit 0
    }
    newline 50
}


#--------------------------------------------------
# READ CONFIG
newline
info "Looking for the Backup Drive..."

$disks = (Get-PSDrive | ? {$_.Provider.Name -eq 'FileSystem'} | sort Name).Root

foreach ($disk in $disks) {
    if ( Test-Path (Join-Path $disk $backup_config_file_name) ) {
        $bkp_disk = $disk
        $bkp_config_file_path = Join-Path $disk $backup_config_file_name
        break
    }
}

if (! $bkp_config_file_path) {
    error "Backup config file `"$backup_config_file_name`" could not be found in the root of any disk. Is your Backup Drive connected?"
    exit 1
}

$bkp_config = cat $bkp_config_file_path -Raw | ConvertFrom-Yaml -Ordered
info "using `"$bkp_disk`" as a Backup Drive" -sub


#--------------------------------------------------
# SET SCHEDULED TASK
if ( $set_scheduled_task ) {
    # validate config
    newline
    info "Validating config file `"$backup_config_file_name`"..."
    $accepted_shedule_types = @('daily', 'weekly')
    $accepted_weekdays = @('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')
    if ( $bkp_config.schedule.type -notin $accepted_shedule_types ) {
        error "Unknown schedule type `"$($bkp_config.schedule.type)`"."
        exit 1
    }
    if ( $bkp_config.schedule.type -eq 'weekly' ) {
        if ( $bkp_config.schedule.day_of_the_week -notin $accepted_weekdays ) {
            error "Unknown weekday `"$($bkp_config.schedule.day_of_the_week)`"."
            exit 1
        }
    }
    if ((! $bkp_config.schedule.interval) -or ($bkp_config.schedule.interval -lt 1)) {
        $bkp_config.schedule.interval = 1
    }
    "checking time"
    if ( $bkp_config.schedule.time -notmatch '^([0-1]\d|2[0-4])\:[0-5]\d$' ) {
        error "Format of <time> is invalid: `"$($bkp_config.schedule.time)`""
        exit 1
    }

    $existing_task = Get-ScheduledTask $scheduled_task_name -ErrorAction SilentlyContinue
    if ( $existing_task ) {
        newline
        warning "Found existing scheduled task `"$scheduled_task_name`"."
        if (! (confirm "Delete existing task?")) {
            warning "cancelled by user"
            exit 0
        }
        $existing_task | Unregister-ScheduledTask -Confirm:$false
    }

    newline
    info "Setting Up Scheduled Task"
    info " task name: `"$scheduled_task_name`"" -sub
    info " script path: `"$SCRIPT_FULL_PATH`"" -sub
    info " schedule type: `"$($bkp_config.schedule.type)`"" -sub
    if ( $bkp_config.schedule.type -eq 'weekly' ) {
        info " day of week: `"$($bkp_config.schedule.day_of_the_week)`"" -sub
    }
    info " time: `"$($bkp_config.schedule.time)`"" -sub
    if (! (confirm "Proceed?") ) {
        warning "cancelled by user"
        exit 0
    }

    $argstring = "-NoProfile -NoLogo -ExecutionPolicy Bypass -Command `"& '$SCRIPT_FULL_PATH'`""
    $action = New-ScheduledTaskAction -Execute (gcm powershell).Source -Argument $argstring
    $user = $env:USERDOMAIN, $env:USERNAME -join ('\')
    $principal = New-ScheduledTaskPrincipal -UserId $user -RunLevel Highest -LogonType Interactive

    switch ($bkp_config.schedule.type) {
        'daily' {
            $trigger = New-ScheduledTaskTrigger `
                        -Daily `
                        -DaysInterval $bkp_config.schedule.interval `
                        -At $bkp_config.schedule.time
        }
        'weekly' {
            $trigger = New-ScheduledTaskTrigger `
                        -Weekly `
                        -DaysOfWeek $bkp_config.schedule.day_of_the_week `
                        -WeeksInterval $bkp_config.schedule.interval `
                        -At $bkp_config.schedule.time
        }
        Default {
            error "Invalid schedule type `"$($bkp_config.schedule.type)`""
            exit
        }
    }

    $settings = New-ScheduledTaskSettingsSet `
                    -Compatibility Win8 `
                    -AllowStartIfOnBatteries `
                    -DontStopIfGoingOnBatteries `
                    -RestartCount 2 `
                    -RestartInterval (New-TimeSpan -Minutes 1) `
                    -StartWhenAvailable

    $task = New-ScheduledTask `
                -Action $action `
                -Trigger $trigger `
                -Principal $principal `
                -Settings $settings

    Register-ScheduledTask $scheduled_task_name -InputObject $task | out-null

    info "done" -success
    exit 0
}


#--------------------------------------------------
# UNSET SCHEDULED TASK
if ( $unset_scheduled_task ) {
    newline
    info "Removing Scheduled Task `"$scheduled_task_name`"..."
    $existing_task = Get-ScheduledTask $scheduled_task_name -ErrorAction SilentlyContinue
    if ( $existing_task ) {
        $existing_task | Unregister-ScheduledTask -Confirm:$false
        info "done`n" -success
    }
    else {
        warning "No such scheduled task: `"$scheduled_task_name`". Already removed?`n"
    }
    exit 0
}


#--------------------------------------------------
# RUN BACKUP

# validate config
newline
info "Validating config file `"$backup_config_file_name`"..."
if ((! $bkp_config.retention.backups_to_keep) -or ($bkp_config.retention.backups_to_keep -lt 1)) {
    $bkp_config.retention.backups_to_keep = 1
}
if ( $bkp_config.retention.min_free_space -notmatch '^\d+(gb|mb)$' ) {
    error "Format of <min_free_space> is invalid: `"$($bkp_config.retention.min_free_space)`""
    exit 1
}

# check free space on backup drive
newline
info "Checking available free space on Backup Drive..."
if ( ((Get-PSDrive | ? {$_.Root -eq $bkp_disk}).Free / $bkp_config.retention.min_free_space) -lt 1 ) {
    error "Backup Drive `"$bkp_disk`" has less free space than the minimum set ($($bkp_config.retention.min_free_space))"
    exit 1
}
info "requirement satisfied (parameter <min_free_space> is set to `"$($bkp_config.retention.min_free_space)`")" -sub

# run backup
newline
info "Running Backup..."
$STOPWATCH = [diagnostics.stopwatch]::StartNew()

$bkp_root_dir = Join-Path $bkp_disk $bkp_config.bkp_root_dir
while ( $true ) {
    $guid = [guid]::NewGuid().Guid.split('-')[0..1] -join('')
    $bkp_dir = Join-Path $bkp_root_dir "$backup_prefix$guid"
    if (! (Test-Path $bkp_dir)) { break }
}

foreach ( $bkp_item in $bkp_config.bkp_items ) {
    $source = $bkp_item.source
    $destination = Join-Path $bkp_dir $bkp_item.destination
    $include = $bkp_item.include -join "','"
    $exclude_system_dirs = "'System Volume Information','`$RECYCLE.BIN'"
    $exclude = $bkp_item.exclude -join "','"

    newline
    info " copying `"$source`" to `"$destination`"" -sub
    mkdir $destination -Force | Out-Null

    $command = "cp -Path '$source*' -Destination '$destination'"
    $command += " -Recurse -Force -ErrorAction Continue"

    # include
    if ( $include ) {
        $include = "'$include'"
        info " include: $include" -sub
        $command += " -Include $include"
    }

    # exclude
    if ( $exclude ) {
        $exclude = "'$exclude'"
        info " exclude: $exclude" -sub
        $exclude = $exclude_system_dirs + ",$exclude"
    }
    else {
        $exclude = $exclude_system_dirs
    }
    $command += " -Exclude $exclude"

    # run cp command
    $scriptblock = [Scriptblock]::Create($command)
    icm -ScriptBlock $scriptblock
}


#--------------------------------------------------
# DELETE OLD BACKUPS
newline
info "Deleting old Backups..."
info "parameter <backups_to_keep> is set to `"$($bkp_config.retention.backups_to_keep)`"" -sub
$all_backups = ls $bkp_root_dir -Filter "$backup_prefix*" | sort CreationTime -Descending
if ( $all_backups -and ($all_backups.Length -gt $bkp_config.retention.backups_to_keep)) {
    $old_backups = $all_backups[$bkp_config.retention.backups_to_keep..($all_backups.Length - 1)]
}
if ( $old_backups ) {
    $old_backups | rm -Force -Recurse
}


#--------------------------------------------------
# ELAPSED TIME
newline
info "Backup finished successfully in $($STOPWATCH.Elapsed.Minutes) Minutes $($STOPWATCH.Elapsed.Seconds) Seconds." -success
newline
warning "Press any key to exit..." -noprefix
wait-any-key
(Get-Host).UI.RawUI.WindowTitle = $current_title
exit 0
