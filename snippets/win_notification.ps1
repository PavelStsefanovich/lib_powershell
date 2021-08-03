[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon

$objNotifyIcon.Icon = "E:\GoogleDrive\stse.pavell\Collections\WindowsCustomization\Icons\clock.ico"
$objNotifyIcon.BalloonTipIcon = "Info"
$objNotifyIcon.BalloonTipText = "A file needed to complete the operation could not be found."
$objNotifyIcon.BalloonTipTitle = "File Not Found"

$objNotifyIcon.Visible = $True
$objNotifyIcon.ShowBalloonTip(5000)
$objNotifyIcon.Visible = $false
