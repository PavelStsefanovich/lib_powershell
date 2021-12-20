# WinRegistry
*Simplified operations for Windows Registry*

### Installation
    Install-Module -Name WinRegistry
	Import-Module WinRegistry

or force-install:

    Install-Module -Name WinRegistry -Force -AllowClobber
	Import-Module WinRegistry -Force -DisableNameChecking

### Upgrade
    Remove-Module WinRegistry -force -ea SilentlyContinue; Uninstall-Module WinRegistry -allv -force -ea SilentlyContinue; Install-Module -n WinRegistry -force -allowc -ea Stop; Import-Module WinRegistry -force -d -ea Stop

### Powershell Gallery
https://www.powershellgallery.com/packages/WinRegistry

### Module Content

| Function  | Alias | Description |
| ------------- | ------------- | ------------- |
| Get-RegKeyProperties |  | Lists properties of the target Registry key |
| Get-RegKeyPropertyValue |  | Returns value of specific Registry key property |
| New-RegKey |  | Creates new Registry key, if it does not exist already |
| Remove-RegKey |  | Deletes target Registry key and all its children (subkeys and properties) |
| Remove-RegKeyProperty |  | Deletes specific Registry key property |
| Set-RegKeyPropertyValue |  | Sets value of specific Registry key property. Creates new property, if does not exist already. |
| Show-RegKey |  | Lists subkeys and properties of the target Registry key |

### Module Commands Manuals
Run the following in the console to get details about a command:

    help <command-name> -Full
