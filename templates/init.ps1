[cmdletbinding(HelpUri = "")]
param (
    [string]$parameter1,
    [string]$parameter2
)


##########  INIT  ###############################################

$ErrorActionPreference = 'Stop'
$host.PrivateData.ErrorBackgroundColor = $host.UI.RawUI.BackgroundColor
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$SCRIPT_DIR = $PSScriptRoot
$SCRIPT_NAME = $MyInvocation.MyCommand.Name
$WORKSPACE = $PWD.Path
$IS_VERBOSE = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
if (!$IS_VERBOSE) { $IS_VERBOSE = $false }
