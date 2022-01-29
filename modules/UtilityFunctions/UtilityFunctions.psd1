#
# Module manifest for module 'UtilityFunctions'
#
# Generated by: Pavel Stsefanovich
#
# Generated on: 1/29/2022
#

@{

# Script module or binary module file associated with this manifest.
RootModule = './UtilityFunctions.psm1'

# Version number of this module.
ModuleVersion = '0.4.8'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '84641819-e182-4270-813a-b6198b44ce26'

# Author of this module
Author = 'Pavel Stsefanovich'

# Company or vendor of this module
CompanyName = 'Pavel Stsefanovich'

# Copyright statement for this module
Copyright = '(c) 2022 Pavel Stsefanovich. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Common utilities and standardized console output messages for PowerShell admins.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'newline', 'error', 'info', 'warning', 'request-consent', 'wait-any-key', 
               'isadmin', 'restart-elevated', 'is-restart-pending', 'hibernate', 
               'json-to-hashtable', 'abspath', 'which', 'list-module-commands', 'zip', 
               'unzip', 'extract-file', 'get-files-with-text', 'sha', 'base64', 
               'ss-to-plain', 'run-sql', 'run-process', 'list-installed-software', 
               'file-tabs-to-spaces', 'file-hex-dump', 'll', 'unblock-downloaded', 
               'get-dotnet-fwk-version'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = 'lf', 'confirm', 'jth', 'sstp', 'isrp', 'hib', 'wait', 'fwt', 'listmc', 'sql', 'run', 
               'unzipf', 'listis', 'dsort', 'unb', 'netfwk'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'windows','common','console','utilities'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PavelStsefanovich/lib_powershell/blob/main/modules/UtilityFunctions/LICENSE.txt'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions'

        # A URL to an icon representing this module.
        IconUri = 'https://raw.githubusercontent.com/PavelStsefanovich/lib_powershell/5ecc43ec43a7552e3e51de0f31fde834085f632e/modules/UtilityFunctions/favicon.ico'

        # ReleaseNotes of this module
        ReleaseNotes = 'Bug fixes'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

 } # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://github.com/PavelStsefanovich/lib_powershell/blob/main/modules/UtilityFunctions/README.md'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

