# To find the Version, Culture and PublicKeyToken of an Assembly:
$dll_path = "AtHoc.Scheduling.dll"
([system.reflection.assembly]::loadfile($dll_path)).FullName


# To Add assembly to GAC:
$dll_path = "AtHoc.Scheduling.dll"
[System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
$publish = New-Object System.EnterpriseServices.Internal.Publish
$publish.GacInstall($dll_path)


# To Remove assembly from GAC:
$assembly_name = "AtHoc.Scheduling"
[System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
$publish = New-Object System.EnterpriseServices.Internal.Publish
$publish.GacRemove($assembly_name)
