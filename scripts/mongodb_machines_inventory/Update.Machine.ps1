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
    [hashtable[]]$vm_update_owners,
    [string]$vm_update_DbSaUser,
    [string]$vm_update_DbSaPassw,
    [string]$vm_update_dailyDeployment,

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
        throw "User <$Requester> is not authorized (must be admin or machine's owner)."
    }
}


# UPDATE MACHINE

#- check if machine record exists
$query = New-MdbcQuery -Name name -eq $vm_name
$machine = Get-MdbcData -Collection $Collection -Query $query
if (!$machine) {
    throw "Machine '$vm_name' not found."
}

$update = New-MdbcUpdate

foreach ($parameter in $PSBoundParameters.GetEnumerator()) {
    if ($parameter.Key -like 'vm_update_*') {
        switch ($parameter.Key) {
            "vm_update_owners" {
                if ($PSBoundParameters.($parameter.Key).Keys) {
                    
                    $delete = New-MdbcUpdate
                    $delete.Unset('owners') | Out-Null

                    $newOwners = @()                
                    $Owners = @()

                    #- combine distinct items from request and current owners
                    $PSBoundParameters.($parameter.Key) | %{$newOwners += $_}
                    foreach ($owner in $machine.owners) {
                        if ($owner.name -notin $PSBoundParameters.($parameter.Key).name) {
                            $newOwners += [hashtable]$owner
                        }
                    }

                    #- exclude items marked for deletion
                    foreach ($owner in $newOwners) {
                        if (!($owner.ContainsKey('action') -and ($owner.action -eq 'delete'))) {
                            $Owners += $owner
                        }
                    }

                    #- fail if all owners removed
                    if ($Owners.Count -eq 0) {
                        throw "Can't remove all owners: at least one owner must exist."
                    }

                    $update.AddToSetEach('owners',$Owners) | Out-Null
                }
                break
            }
            "vm_update_DbSaUser" {
                if ([string]::IsNullOrEmpty($PSBoundParameters.($parameter.Key))) {
                    $update.Unset('database_user') | Out-Null
                } else {
                    $update.Set('database_user',$PSBoundParameters.($parameter.Key)) | Out-Null
                }
                break
            }
            "vm_update_DbSaPassw" {
                if ([string]::IsNullOrEmpty($PSBoundParameters.($parameter.Key))) {
                    $update.Unset('database_password')
                } else {
                    $update.Set('database_password',$PSBoundParameters.($parameter.Key))
                }
                break
            }
            "vm_update_dailyDeployment" {
                if ([string]::IsNullOrEmpty($PSBoundParameters.($parameter.Key))) {
                    $update.Unset('daily_deployment')
                } else {
                    $update.Set('daily_deployment',$PSBoundParameters.($parameter.Key))
                }
                break
            }
            default {throw "Unknown parameter: <$($parameter.Key)>."}
        }
    }
}

$update.Set('last_accessed',(get-date -Format "yyyy-MM-ddTHH:mm:ss")) | Out-Null
$update.Set('last_accessed_by',$PSBoundParameters.Requester) | Out-Null
$update.Set('last_operation','update') | Out-Null



#- clean existing arrays
if ($delete) {
    Write-Verbose "<delete> : $delete"
    $machine | Update-MdbcData $delete
}

#- update machine record (mongodb document) in database
$machine = Get-MdbcData -Collection $Collection -Query $query
Write-Verbose "<update> : $update"
$machine | Update-MdbcData $update

Show-Result $scriptName
