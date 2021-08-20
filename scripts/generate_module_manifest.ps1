[CmdletBinding()]
Param (
    [Parameter(
        Position = 0)]
    [string] $module_dir_path = $(throw "Mandatory parameter not provided: <module_dir_path>")
)



##########  FUNCTIONS  ##########################################





##########  INIT  ###############################################

$ErrorActionPreference = 'Stop'
$host.PrivateData.ErrorBackgroundColor = $host.UI.RawUI.BackgroundColor
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
if (!(Get-Module UtilityFunctions)) { Import-Module UtilityFunctions -Force -DisableNameChecking }



##########  MAIN  ###############################################

info "verifying module location: " -no_newline
$MODULE_PATH = $module_dir_path | abspath -verify
$MODULE_NAME = Split-Path $MODULE_PATH -Leaf
info "found" -success


#--------------------------------------------------
info "looking if for module manifest file (.psd1): " -no_newline
$MODULE_MANIFEST_PATH = Join-Path $MODULE_PATH "$MODULE_NAME.psd1"
$NEW_MANIFEST = $true
if (Test-Path $MODULE_MANIFEST_PATH) {
    $NEW_MANIFEST = $false
    info "found" -success
}


#--------------------------------------------------
# CREATE NEW MANIFEST
if ($NEW_MANIFEST) {

}


#--------------------------------------------------
# UPDATE EXISTING MANIFEST
else {

}