# UtilityFunctions
*Common operations and standardized console output messages*

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
| abspath |  | Convert path to absolute path |
| base64 |  | Encrypt/Decrypt text with base64 |
| dir-natural-sort | dsort | Sort numbered directory content naturally |
| error |  | Print error message into console |
| extract-file | unzipf | Extract specific files from .zip archive |
| file-hex-dump |  | Generate HEX table for a file |
| file-tabs-to-spaces |  | Replace tabs with spaces in a file |
| get-files-with-text | fwt | Print (or open) texfiles that contain search string |
| hibernate | hib | Put computer to sleep |
| info |  | Print info message into console |
| isadmin |  | Check if current console/script is running as admin |
| is-restart-pending | isrp | Check if system restart pending |
| json-to-hashtable | jth | Convert json into hashtable |
| list-installed-software | listis | List apps that appear in 'Uninstall Programs' |
| list-module-commands | listmc | List module commands with aliases |
| newline | lf | Print newline(s) into console |
| request-consent | confirm | Ask user for confirmation (y/n) |
| restart-elevated |  | Restart script as administrator |
| run-process | run | Run external process and return standard streams & exit code |
| run-sql | sql | Execute SQL query and return result |
| sha |  | Encrypt text with SHA- algorithms  |
| ss-to-plain | sstp | Convert SecureString into plain text |
| unzip |  | Extract .zip archive into directory |
| wait-any-key | wait | Wait for user to press any key |
| warning |  | Print warning message into console |
| which |  | Print command source path |
| zip |  | Compress directory into .zip archive |

### Module Commands Manuals
Run the following in the console to get details about a command:

    help <command-name> -Full
