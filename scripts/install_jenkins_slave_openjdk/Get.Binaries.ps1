param (
    [switch]$java,
    [switch]$winsw,
    [string]$downloadFolder
)

Write-Host ("`n(script) " + $MyInvocation.MyCommand.Name + "`n(args)")
Write-Host ("  java:`t`t`t$java")
Write-Host ("  winsw:`t`t$winsw")
Write-Host ("  downloadFolder:`t$downloadFolder")


throw "(ps) this script under construction"