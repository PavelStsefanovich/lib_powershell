[cmdletbinding()]
param (
    [string]$parameter1,
    [string]$parameter2
)


##########  INIT  ###############################################

$ErrorActionPreference = 'Stop'
$SCRIPT_DIR = $PSScriptRoot
$SCRIPT_NAME = $MyInvocation.MyCommand.Name
$WORKSPACE = $PWD.Path
$IS_VERBOSE = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
if (!$IS_VERBOSE) { $IS_VERBOSE = $false }
