[CmdletBinding()]
param (

    [string]$Requester = $(throw "Mandatory argument not provided: <Requester>."),

    [string]$mongoServer = $(throw "Mandatory argument not provided: <mongoServer>."),
    [string]$mongoUser = $(throw "Mandatory argument not provided: <mongoUser>."),
    [string]$mongoPassw = $(throw "Mandatory argument not provided: <mongoPassw>."),
    [string]$mongoDB = $(throw "Mandatory argument not provided: <mongoDB>."),
    [string]$mongoColl = 'machines',
    [string]$mongoColl_Admins = 'machines_admins',
    [switch]$mongoReplaceIfExists,

    [string]$vm_name = $(throw "Mandatory argument not provided: <vm_name>."),
    [string]$vm_purpose = $(throw "Mandatory argument not provided: <vm_purpose>."),
    [hashtable[]]$vm_owners = $(throw "Mandatory argument not provided: <vm_owners>."),
    [string]$vm_DbSaUser,
    [string]$vm_DbSaPassw,
    [string]$vm_dailyDeployment,

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

$validationError = Confirm-Parameters $scriptName $PSBoundParameters -failOnNoConnection
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
    $currentUser = isOwner $Requester $vm_owners -Verbose:($PSBoundParameters['Verbose'] -eq $true)
    if (!$currentUser) {
        throw "User <$Requester> is not authorized (must be admin or machine's owner)."
    }
}


# ADD MACHINE

#- check if machine record exists
$query = New-MdbcQuery -Name name -eq $vm_name
$machine = Get-MdbcData -Collection $Collection -Query $query
if ($machine) {
    if (!$mongoReplaceIfExists) {
        throw "Cannot add machine '$vm_name': already exists."
    } else {
        Write-Warning "Machine '$vm_name' exists already, replacing (<mongoReplaceIfExists> : true)"
        $machine | Remove-MdbcData
    }
}

#- construct new machine record (mongodb document)
$machine = New-MdbcData

foreach ($parameter in $PSBoundParameters.GetEnumerator()) {
    if ($parameter.Key -like 'vm_*') {
        switch ($parameter.Key) {
            "vm_name" {$machine.name = $PSBoundParameters.($parameter.Key); break}
            "vm_purpose" {$machine.purpose = $PSBoundParameters.($parameter.Key); break}
            "vm_owners" {
                $machine.owners = [System.Collections.ArrayList]$PSBoundParameters.($parameter.Key)
                break
            }
            "vm_DbSaUser" {$machine.database_user = $PSBoundParameters.($parameter.Key); break}
            "vm_DbSaPassw" {$machine.database_password = $PSBoundParameters.($parameter.Key); break}
            "vm_dailyDeployment" {$machine.daily_deployment = $PSBoundParameters.($parameter.Key); break}
            default {throw "Unknown parameter: <$($parameter.Key)>."}
        }
    }
}

$machine.created = get-date -Format "yyyy-MM-ddTHH:mm:ss"
$machine.last_accessed = get-date -Format "yyyy-MM-ddTHH:mm:ss"
$machine.last_accessed_by = $PSBoundParameters.Requester
$machine.last_operation = 'create'

Write-Verbose "<machine> : $machine"

#- add new machine record (mongodb document) to database
$machine | Add-MdbcData

Show-Result $scriptName
