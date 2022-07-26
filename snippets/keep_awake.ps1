function Show-Process($Process, [Switch]$Maximize)
{
    $sig = '
    [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern int SetForegroundWindow(IntPtr hwnd);
  '

    if ($Maximize) { $Mode = 3 } else { $Mode = 4 }
    $type = Add-Type -MemberDefinition $sig -Name WindowAPI -PassThru
    $hwnd = $process.MainWindowHandle
    $null = $type::ShowWindowAsync($hwnd, $Mode)
    $null = $type::SetForegroundWindow($hwnd)
}

function awake {
    $WShell = New-Object -Com "Wscript.Shell"
    while ($true) {
        Show-Process -Process (Get-Process -Id $PID)
        Write-Host "AWAKE MODE IS ON!" -ForegroundColor Red
        $WShell.SendKeys("!")
        Start-Sleep -Seconds 60
    }
}
