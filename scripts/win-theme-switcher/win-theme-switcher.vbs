Set WshShell = CreateObject("WScript.Shell")
' Run PowerShell script hidden. The 0 window style hides the window and False returns immediately.
' The PowerShell script path is built dynamically from this VBS file's folder, so files may be moved.

' Create FileSystemObject to compute paths
Set fso = CreateObject("Scripting.FileSystemObject")
vbsFullPath = WScript.ScriptFullName
vbsFolder = fso.GetParentFolderName(vbsFullPath)
psPath = fso.BuildPath(vbsFolder, "win-theme-switcher.ps1")

psCmd = "powershell.exe -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & psPath & """"
WshShell.Run psCmd, 0, False
