<#
.SYNOPSIS
See full description below
.Description
Lists software records found under following registry keys:
- HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
- HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
- HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
By default lists all records.
By default shows only DisplayName property.
All parameters are optional.
.PARAMETER name_filter
Filters results by DisplayName. Accepts wildcards '*'. Example: -name_filter *Java*
.PARAMETER version_filter
Filters results by DisplayVersion. Accepts wildcards '*'. Example: -version_filter 2.1.*
.PARAMETER publisher_filter
Filters results by Publisher. Accepts wildcards '*'. Example: -publisher_filter Micro*
.PARAMETER hive_filter
Filters results by PSDrive (which corresponds to the registry hives). Accepts wildcards '*'. Example: -hive_filter hklm
.PARAMETER properties
List properties (comma-separated) to be displayed on the result set. Accepted values: 'name', 'version', 'publisher', 'install_location', 'uninstall_string', 'hive', 'all'.
If 'all' specified, all supported properties will be displayed, no need to specify them explicitely.
Example: -properties name, version, publisher
.PARAMETER out_file_path
Result set output file path. If not specified, result set is displayed in console instead. Example: -out_file_path app_list.txt
.LINK
https://github.com/PavelStsefanovich/lib_powershell
#>

param (
    [string]$name_filter = '*',
    [string]$version_filter = '*',
    [string]$publisher_filter = '*',
    [string]$hive_filter = '*',
    [string[]]$properties = @('name'),
    [string]$out_file_path
)


$uninstallKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')

$registryAlias = @{
    'HKEY_LOCAL_MACHINE' = 'HKLM:'
    'HKEY_CURRENT_USER'  = 'HKCU:'
}

$accepted_properties = @{
    'name'             = 'DisplayName'
    'version'          = 'DisplayVersion'
    'publisher'        = 'Publisher'
    'install_location' = 'InstallLocation'
    'uninstall_string' = 'UninstallString'
    'hive'             = 'PSDrive'
}

$all_software = @()

foreach ($key in $uninstallKeys) {
    $software = [array](gp $key\* -ErrorAction SilentlyContinue)
    if ($software) {
        $all_software += $software
    }
}

$filtered_result_set = $all_software |
    ? { $_.DisplayName.length -gt 0 } |
    ? { $_.DisplayName -like $name_filter } |
    ? { $_.DisplayVersion -like $version_filter } |
    ? { $_.Publisher -like $publisher_filter } |
    ? { $_.PSDrive -like $hive_filter }

$sorted_result_set = $filtered_result_set | sort -Property DisplayName

$optimized_properties = @('DisplayName')

foreach ($property in $properties) {
    if ($property -eq 'all') {
        $optimized_properties = @('DisplayName', 'DisplayVersion', 'Publisher', 'InstallLocation', 'UninstallString', 'PSDrive')
        break
    }
    $prop_name = $accepted_properties.$property
    if ($prop_name) {
        if ($prop_name -notin $optimized_properties) {
            $optimized_properties += $prop_name
        }
    }
    else {
        Write-Warning "skipping unknown property '$property'"
    }
}

$final_result_set = $sorted_result_set | select $optimized_properties

if ($out_file_path) {
    $final_result_set | Out-File $out_file_path -Force -Encoding utf8
}
else {
    $final_result_set
}