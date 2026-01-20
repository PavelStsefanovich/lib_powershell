$sw = [System.Diagnostics.Stopwatch]::StartNew()
while ($sw.Elapsed.TotalSeconds -lt 30) {
    if (Test-Path "C:\temp\ready.txt") { break }
    Start-Sleep -Seconds 5
}
$sw.Stop()
