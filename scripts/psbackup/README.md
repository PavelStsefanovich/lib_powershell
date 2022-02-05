# PSBackup
*Simple backup utility script*

### Dependencies
- UtilityFunctions (https://www.powershellgallery.com/packages/UtilityFunctions)
- powershell-yaml	(https://www.powershellgallery.com/packages/powershell-yaml)

### Usage
- Edit `.psbkp.yaml` file for your desired backup configuration.
- Make sure the drive you want to use as Backup Drive is connected.
- Copy `.psbkp.yaml` file to the root of the Backup Drive.

To run backup manually, run `psbackup.ps1` script with no arguments:

    .\psbackup.ps1

To set up scheduled task to run backup periodically, run `psbackup.ps1` script with *-set_scheduled_task* parameter:

    .\psbackup.ps1 -set_scheduled_task

To delete scheduled task, run `psbackup.ps1` script with *-unset_scheduled_task* parameter:

    .\psbackup.ps1 -unset_scheduled_task
