# START MENU

# Create
$objShell = New-Object -ComObject ("WScript.Shell")
$objShortCut = $objShell.CreateShortcut((Join-Path $env:USERPROFILE "Start Menu\Programs\<app_name>.lnk"))
$objShortCut.TargetPath = "<path_to_executable>"
$objShortCut.Save()

# Remove
rm (Join-Path $env:USERPROFILE "Start Menu\Programs\<app_name>.lnk") -Force


# UPDATE EXISTING SHORTCUT
$obj = New-Object -ComObject ("WScript.Shell")
$ps_link_path = 'C:\Users\Pavel\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk'
$link = $obj.CreateShortcut($ps_link_path)
$link.Arguments = "-nologo"
$link.Save()
