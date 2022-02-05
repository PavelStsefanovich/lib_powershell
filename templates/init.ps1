[cmdletbinding(HelpUri = "")]
param (
    [string]$parameter1 = $(throw "Mandatory parameter not provided: <parameter1>"),
    [string]$parameter2
)



##########  FUNCTIONS  ##########################################

function one {
    param([string] $param1)
    write $param1
}

#--------------------------------------------------
function two {
    param([string] $param1)
    write $param1
}



##########  MAIN  ###############################################

#--------------------------------------------------
# INIT
$ErrorActionPreference = 'Stop'
$STOPWATCH = [diagnostics.stopwatch]::StartNew()
$host.PrivateData.ErrorBackgroundColor = $host.UI.RawUI.BackgroundColor
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$SCRIPT_FULL_PATH = $PSCommandPath
$SCRIPT_DIR = $PSScriptRoot
$SCRIPT_NAME = $MyInvocation.MyCommand.Name
$SCRIPT_BASE_NAME = $(gi $PSCommandPath).BaseName
$WORKSPACE = $PWD.Path
$IS_VERBOSE = [bool]($PSCmdlet.MyInvocation.BoundParameters.Verbose)
$IS_INTERACTIVE = (Get-CimInstance win32_process -Filter "ProcessID=$PID" | `
        ? { $_.processname -eq "powershell.exe" }).CommandLine -notlike "*-NonI*"


#--------------------------------------------------
# DO SOMETHING


#--------------------------------------------------
# ELAPSED TIME
"SCRIPT FINISHED in $($STOPWATCH.Elapsed.Minutes) Minutes $($STOPWATCH.Elapsed.Seconds) Seconds."
