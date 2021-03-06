[CmdletBinding()]
param (

    [string]$Requester = $(throw "Mandatory argument not provided: <Requester>."),

    [string]$mongoServer = $(throw "Mandatory argument not provided: <mongoServer>."),
    [string]$mongoUser = $(throw "Mandatory argument not provided: <mongoUser>."),
    [string]$mongoPassw = $(throw "Mandatory argument not provided: <mongoPassw>."),
    [string]$mongoDB = $(throw "Mandatory argument not provided: <mongoDB>."),
    [string]$mongoColl = 'machines',
    [string]$mongoColl_Admins = 'machines_admins',

    [string]$vm_name = $(throw "Mandatory argument not provided: <vm_name>."),
    [switch]$vm_get_purpose,
    [switch]$vm_get_owners,
    [switch]$vm_get_DbSaUser,
    [switch]$vm_get_DbSaPassw,
    [switch]$vm_get_dailyDeployment,

    [switch]$return,

    [string]$mdbcModulePath,
    [string]$mongoHelperModulePath
)


$ErrorActionPreference = 'Stop'
$scriptName = $MyInvocation.MyCommand.Name


# MODULES

#- import mdbc module
if($mdbcModulePath) {
    if (Resolve-Path $mdbcModulePath) {
        Import-Module -Name $mdbcModulePath -Scope Local -Force -DisableNameChecking
    }
} else {
    Import-Module Mdbc -Scope Local -Force -DisableNameChecking
}

#- import mdbc module
if($mongoHelperModulePath) {
    if (Resolve-Path $mongoHelperModulePath) {
        Import-Module -Name $mongoHelperModulePath -Scope Local -Force -DisableNameChecking
    }
} else {
    Import-Module "$($PWD.Path)\Machines.Helper.Methods.psm1" -Scope Local -Force -DisableNameChecking
}


# VALIDATE INPUT PARAMETERS

$validationError = Confirm-Parameters $scriptName $PSBoundParameters
if ($validationError) {
    throw $validationError
}
$connectionString = Get-ConnectionString $PSBoundParameters -Verbose:($PSBoundParameters['Verbose'] -eq $true)


# CHECK PERMISSIONS

#- check against admins db
Connect-Mdbc -ConnectionString $connectionString -DatabaseName $mongoDB -CollectionName $mongoColl_Admins
$admin = $null
if ($Requester -in (Get-MdbcData -Collection $Collection).name) {
    $admin = $true
}

#- connect to database
Connect-Mdbc -ConnectionString $connectionString -DatabaseName $mongoDB -CollectionName $mongoColl

#- check against owners list
if (!$admin) {
    $currentOwners = (Get-MdbcData -Collection $Collection -Query (New-MdbcQuery -Name name -eq $vm_name)).owners
    $currentUser = isOwner $Requester $currentOwners -Verbose:($PSBoundParameters['Verbose'] -eq $true)
    if (!$currentUser) {
        Write-Warning "User <$Requester> is not an owner and only allowed to see a purpose and list of owners for this machine."
        $restricted = $true
    }
}


# GET MACHINE

#- check if machine record exists
$query = New-MdbcQuery -Name name -eq $vm_name
$machine = Get-MdbcData -Collection $Collection -Query $query
if (!$machine) {
    throw "Machine '$vm_name' not found."
}

#- determine fields to display
$showAll = $true

if ($restricted`
-or $vm_get_purpose`
-or $vm_get_owners`
-or $vm_get_DbSaUser`
-or $vm_get_DbSaPassw`
-or $vm_get_dailyDeployment)
{
    $showAll = $false
}

#- display machine info
$machineInfo = @{}

if ($restricted) {
    $machineInfo.name = $machine.name
    $machineInfo.owners = $machine.owners
    $machineInfo.purpose = $machine.purpose

} elseif ($showAll) {
    foreach ($key in $machine.keys) {
        if ($key -ne '_id') {
            $machineInfo.Add($key,$machine.$key)
        }
    }

} else {
    foreach ($key in $machine.keys) {
        switch ($key) {
            "name" {
                $machineInfo.name = $machine.name
                break
            }
            "purpose" {
                $machineInfo.purpose = $machine.purpose
                break
            }
            "owners" {
                if ($vm_get_owners) {
                    $machineInfo.owners = $machine.owners
                }
                break
            }
            "database_user" {
                if ($vm_get_DbSaUser) {
                    $machineInfo.database_user = $machine.database_user
                }
                break
            }
            "database_password" {
                if ($vm_get_DbSaPassw) {
                    $machineInfo.database_password = $machine.database_password
                }
                break
            }
            "daily_deployment" {
                if ($vm_get_dailyDeployment) {
                    $machineInfo.daily_deployment = $machine.daily_deployment
                }
                break
            }
        }
    }
}

#- return or display machine info
if ($return) {
    Show-Result $scriptName
    return $machineInfo
} else {
    $machineInfo.Keys | %{
        $line = $_.toString()
        $line += (" " * (25 - $line.length))
        $line += ": "
        $line += $machineInfo.$_
        Write-Host $line
    }
    Show-Result $scriptName
}
