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


# DELETE MACHINE

#- check if machine record exists
$query = New-MdbcQuery -Name name -eq $vm_name
$machine = Get-MdbcData -Collection $Collection -Query $query
if (!$machine) {
    throw "Machine '$vm_name' not found."
}

#- delete machine
Remove-MdbcData -Collection $Collection -Query $query

write-host ("`n (!) Machine record deleted: '" + $machine.name + "'`n")
