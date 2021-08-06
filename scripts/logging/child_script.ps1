$Level = 'DEBUG', 'INFO', 'WARNING', 'ERROR'
foreach ($i in 1..10) {
    Write-Log -Level ($Level | Get-Random) -Message 'Message n. {0}' -Arguments $i
    Start-Sleep -Milliseconds (Get-Random -Min 100 -Max 1000)
}
