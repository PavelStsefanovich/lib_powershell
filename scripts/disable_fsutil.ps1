$os = (Get-WMIObject win32_operatingsystem).name
if ($os -like '*Server 2012*') {
    fsutil behavior set DisableDeleteNotify 1
}
elseif ($os -like '*Server 2016*') {
    fsutil behavior set DisableDeleteNotify NTFS 1
    fsutil behavior set DisableDeleteNotify ReFS 1
}
else {
    Write-Warning "Not supported OS: $os"
}
