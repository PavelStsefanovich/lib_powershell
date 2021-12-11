# [CmdletBinding()]
# param ()



########## FUNCTIONS
function Quit ($exit_code = 0) {
    Write-Log '==> END OF LOG <=='
    $logpath = (Get-LoggingTarget File).Path
    Wait-Logging
    Remove-Module Logging -Force
    Write-Host "Log path: '$logpath'" -ForegroundColor Yellow
    if ($exit_code -ne 0) { notepad $logpath }
    exit $exit_code
}



########## MAIN
$ErrorActionPreference = 'stop'
$script:start_time = Get-Date


## Init Logger
Write-Host "initializing logger" -ForegroundColor DarkGray
$log_file_name = (get-date $script:start_time -f 'yyyy-MM-ddTHH-mm-ss'), ((gi $PSCommandPath).BaseName + '.log') -join ('_')
$log_file_path = Join-Path (mkdir (Join-Path $PSScriptRoot 'logs') -Force).FullName $log_file_name
if (!(Get-Module Logging)) {
    if (!(Get-Module Logging -ListAvailable)) {
        Install-Module Logging -Force -Scope CurrentUser
    }
    Import-Module Logging -DisableNameChecking
}
Add-LoggingTarget -Name Console -Configuration @{
    Level        = 'INFO'
    Format       = '[%{filename:15}] %{level:7}: %{message}'
    ColorMapping = @{DEBUG = 'BLUE'; INFO = 'White' ; WARNING = 'Yellow'; ERROR = 'Red'}
}
Add-LoggingTarget -Name File -Configuration @{
    Level        = 'DEBUG'
    Format       = '[%{timestamp}] [%{filename:15}] [%{lineno:3}] [%{level:7}] %{message}'
    Path         = $log_file_path
}
Write-Log -Level info 'Logger is up'


# Uncomment to see logging of exceptions:
# try {
#     gi x
# }
# catch {
#     Write-Log -Level ERROR -Message $_.Exception.Message
#     Write-Log -Level DEBUG -Message $_.InvocationInfo.PositionMessage
#     Quit 1
# }

& .\child_script.ps1

Quit
