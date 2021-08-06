[CmdletBinding()]
param (
    [Parameter(mandatory=$true)]
    [string]
    $app_name
)


$ErrorActionPreference = 'stop'

$app_package_metadata = get-appxpackage -name *$app_name*

if (!$app_package_metadata) {
    write-warning "No packages found that match provided name '$app_name'"
}

if ($app_package_metadata -is [array]) {
    $app_package_metadata | %{ write-host " - $($_.name)" -foregroundcolor darkgray}
    write-warning "More than one package found that matches provided name '$app_name'"
    write-warning "Please narrow your search and try again`n"
    exit
}

$app_package_family_name = $app_package_metadata.PackageFamilyName
[xml]$app_manifest = cat (Join-Path $app_package_metadata.InstallLocation 'AppxManifest.xml')
$app_id = $app_manifest.Package.Applications.Application.Id

$command = "explorer.exe shell:appsFolder\$app_package_family_name!$app_id"

$command
