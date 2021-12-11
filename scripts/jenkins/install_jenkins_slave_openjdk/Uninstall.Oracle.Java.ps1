$Source = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*
$Uninstall = $Source | Where-Object {($_.Publisher -like '*Oracle*')-and ($_.DisplayName -like 'Java*')} | select UninstallString
$UninstallStrings = $Uninstall.UninstallString -replace "MsiExec.exe ","MsiExec.exe /qn " -replace "/I","/X"
if($UninstallStrings)
{
	ForEach($UninstallString in $UninstallStrings){& cmd /c "$UninstallString /norestart"}
}