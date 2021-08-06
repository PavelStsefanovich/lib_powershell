# Create
$objShell = New-Object -ComObject ("WScript.Shell")
$objShortCut = $objShell.CreateShortcut((Join-Path $env:USERPROFILE "Start Menu\Programs\<app_name>.lnk"))
$objShortCut.TargetPath = "<path_to_executable>"
$objShortCut.Save()


# Remove
rm (Join-Path $env:USERPROFILE "Start Menu\Programs\<app_name>.lnk") -Force
