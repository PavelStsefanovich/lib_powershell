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
$host.PrivateData.ErrorBackgroundColor = $host.UI.RawUI.BackgroundColor
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$SCRIPT_DIR = $PSScriptRoot
$SCRIPT_NAME = $MyInvocation.MyCommand.Name
$WORKSPACE = $PWD.Path
$IS_VERBOSE = [bool]($PSCmdlet.MyInvocation.BoundParameters.Verbose)
$IS_INTERACTIVE = $cmd = (Get-CimInstance win32_process -Filter "ProcessID=$PID" | `
    ? { $_.processname -eq "powershell.exe" }).CommandLine -like  "*-NonI*"


#--------------------------------------------------
# DO SOMETHING
