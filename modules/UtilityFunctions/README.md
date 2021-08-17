# UtilityFunctions
*Common console operations and standartized console output messaging*

### Installation
    Install-Module -Name UtilityFunctions
	Import-Module UtilityFunctions

or force-install:

    Install-Module -Name UtilityFunctions -Force -AllowClobber
	Import-Module UtilityFunctions -Force -DisableNameChecking

### Powershell Gallery
https://www.powershellgallery.com/packages/UtilityFunctions

### Module Content


| Function  | Alias | Description |
| ------------- | ------------- | ------------- |
| newline |  | Print newline into console |
| error |  | Print error message into console |
| info |  | Print info message into console |
| warning |  | Print warning message into console |
| request_consent | confirm | Ask user for confirmation (y/n) |
| wait_any_key | wait | Wait for user to press any key |
| isadmin |  | Check if current console is running as admin |
| restart_elevated |  | Restart script as administrator |
| restart_pending | isr | Check if system restart pending |
| hibernate | hib | Put computer to sleep |
| jason_to_hsht |  | Convert json object to hashtable |
| abspath |  | Convert path to absolute path |
| which |  | Print file source path |
| zip |  | Compress directory into .zip archive |
| unzip |  | Extract .zip archive into directory |
| get_files_with_text | fwt | Print (or open) filepaths that contain search text |
| sha |  | Encrypt text with SHA- algorithms  |
| base64 |  | Encrypt/Decrypt text with base64 |
| ss_to_plain |  | Convert SecureString into plain text |
