[CmdletBinding()]
param (

    [string]$Requester = $(throw "Mandatory argument not provided: <Requester>."),

    [string]$mongoServer = $(throw "Mandatory argument not provided: <mongoServer>."),
    [string]$mongoUser = $(throw "Mandatory argument not provided: <mongoUser>."),
    [string]$mongoPassw = $(throw "Mandatory argument not provided: <mongoPassw>."),
    [string]$mongoDB = $(throw "Mandatory argument not provided: <mongoDB>."),
    [string]$mongoColl = 'machines',
    [string]$mongoColl_Admins = 'machines_admins',

    [string[]]$where_name,
    [string[]]$where_purpose,
    [string[]]$where_owners,
    [string[]]$where_DbSaUser,
    [string[]]$where_DbSaPassw,
    [string[]]$where_dailyDeployment,

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


# GET MACHINE(s)

$QUERY_array = @()

if ('where_name' -in $PSBoundParameters.keys) {
    if ($where_name) {
        $hashArray = @()
        $where_name | %{$hashArray += @{'name' = $_}}
        $QUERY_array += New-MdbcQuery -Or $hashArray
    }
}

if ('where_purpose' -in $PSBoundParameters.keys) {
    if ($where_purpose) {
        $hashArray = @()
        $where_purpose | %{$hashArray += @{'purpose' = $_}}
        $QUERY_array += New-MdbcQuery -Or $hashArray
    }
}

if ('where_owners' -in $PSBoundParameters.keys) {
    if ($where_owners) {
        $hashArray = @()
        $where_owners | %{$hashArray += (New-MdbcQuery -Where "function() {for (var i=0; i< this.owners.length; i++) {if (this.owners[i].name == '$_') {return this;}}}")}
        $QUERY_array += New-MdbcQuery -Or $hashArray
    }
}

if ('where_DbSaUser' -in $PSBoundParameters.keys) { #(ps)
    if ($where_DbSaUser) {
        $hashArray = @()
        $where_DbSaUser | %{$hashArray += @{'database_user' = $_}}
        $QUERY_array += New-MdbcQuery -Or $hashArray
    } else {
        $QUERY_array += New-MdbcQuery -Exists 'database_user'
    }
}

if ('where_DbSaPassw' -in $PSBoundParameters.keys) {
    if ($where_DbSaPassw) {
        $hashArray = @()
        $where_DbSaPassw | %{$hashArray += @{'database_password' = $_}}
        $QUERY_array += New-MdbcQuery -Or $hashArray
    } else {
        $QUERY_array += New-MdbcQuery -Exists 'database_password'
    }
}

if ('where_dailyDeployment' -in $PSBoundParameters.keys) {
    if ($where_dailyDeployment) {
        $hashArray = @()
        $where_dailyDeployment | %{$hashArray += @{'daily_deployment' = $_}}
        $QUERY_array += New-MdbcQuery -Or $hashArray
    } else {
        $QUERY_array += New-MdbcQuery -Exists 'daily_deployment'
    }
}

if ($QUERY_array) {
    $QUERY = New-MdbcQuery -And $QUERY_array
} else {
    $QUERY = @{}
}

#- run query
$machines_unrestricted = Get-MdbcData $QUERY
if (!$machines_unrestricted) {
    Write-Warning "No documents found that match provided criteria."
    exit
}

#- check against owners list
$machines_final = @()

foreach ($machine in $machines_unrestricted) {

    $currentUser = isOwner $Requester $machine.owners -Verbose:($PSBoundParameters['Verbose'] -eq $true)
    if ($admin -or $currentUser) {
        $machineNew = @{}
        foreach ($key in $machine.keys) {
            if ($key -ne '_id') {$machineNew.Add($key,$machine.$key)}
        }
    } else {
        $machineNew = @{'name' = $machine.name; 'owners' = $machine.owners; 'purpose' = $machine.purpose; 'restricted' = 'true'}
    }
    $machines_final += $machineNew
}

#- return or display machine info
if ($return) {
    Show-Result $scriptName
    return $machines_final
} else {
    $machines_final.Keys | %{
        $line = $_.toString()
        $line += (" " * (25 - $line.length))
        $line += ": "
        $line += $machines_final.$_
        Write-Host $line
    }
    Show-Result $scriptName
}