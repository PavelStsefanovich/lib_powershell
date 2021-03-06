function Confirm-Parameters
{
    [CmdletBinding()]
    param (
        [parameter(Position=0)]
        $scriptName = $(throw "Mandatory argument not provided: <scriptName>."),
        [parameter(Position=1)]
        $input_parameters = $(throw "Mandatory argument not provided: <input_parameters>."),
        [parameter(Position=2)]
        [switch]$failOnNoConnection
    )

    $ErrorActionPreference = 'Stop'
    $errorMessage = "Invalid input parameter(s)."
    $err = "`t(!) Invalid value!"
    $result = $null

    Write-Host "`n:$scriptName"

    $printParams = @()
    $printParams += ("_"*60)
    $printParams += "INPUT PARAMETERS"
    $printParams += " "
    $spacer = $false

    #- instance-related parameters

    if ($input_parameters.Requester) {
        $printLine = "Requester:`t`t`t$($input_parameters.Requester)"
        if ($input_parameters.Requester -notmatch '^[a-z]+$') {
            $result = $errorMessage
            $printLine += $err
        }
        $printParams += $printLine
        $spacer = $true  
    }
    if ($input_parameters.mongoServer) {
        $printLine = "mongoServer:`t`t`t$($input_parameters.mongoServer)"
        if ($input_parameters.mongoServer -notmatch '^[a-zA-Z0-9]+\.[a-zA-Z0-9]+\.[a-zA-Z0-9]+$') {
            $result = $errorMessage
            $printLine += $err
        }
        $printParams += $printLine
        $spacer = $true        
    }
    if ($input_parameters.mongoUser) {
        $printLine = "mongoUser:`t`t`t$($input_parameters.mongoUser)"
        if ($input_parameters.mongoUser -notmatch '^[\w\.]+(\\\\)*\w+$') {
            $result = $errorMessage
            $printLine += $err
        }
        $printParams += $printLine
        $spacer = $true  
    }
    if ($input_parameters.mongoPassw) {
        $printParams += "mongoPassw:`t`t`t*****"
        $spacer = $true
    }
    if ($input_parameters.mongoDB) {
        $printLine = "mongoDB:`t`t`t$($input_parameters.mongoDB)"
        if ($input_parameters.mongoDB -match '[\/\\\.\s\"\$\*\<\>\:\|\?]') {
            $result = $errorMessage
            $printLine += $err
        }
        $printParams += $printLine
        $spacer = $true
    }
    if ($input_parameters.mongoColl) {
        $printLine = "mongoColl:`t`t`t$($input_parameters.mongoColl)"
        if ($input_parameters.mongoColl -notmatch '^[_|a-zA-Z][_a-zA-Z0-9]+$') {
            $result = $errorMessage
            $printLine += $err
        }
        $printParams += $printLine
        $spacer = $true
    }
    if ($input_parameters.mongoReplaceIfExists) {
        $printParams += "mongoReplaceIfExists:`t`t$($input_parameters.mongoReplaceIfExists)"
        $spacer = $true
    }
    if ($spacer) {
        $printParams += " "
        $spacer = $false
    }

    #- machine-related parameters

    if ($input_parameters.vm_name) {
        $printLine = "vm_name:`t`t`t$($input_parameters.vm_name)"
        if ($input_parameters.vm_name -notmatch '^[_\-a-zA-Z0-9]+$') {
            $result = $errorMessage
            $printLine += $err
        }
        $printParams += $printLine
        $spacer = $true
    }

    #- machine-related parameters (Add)

    if ($input_parameters.vm_purpose) {
        $printLine = "vm_purpose:`t`t`t$($input_parameters.vm_purpose)"
        if ($input_parameters.vm_purpose -notmatch '^.*$') { # (ps) currently no restrictions
            $result = $errorMessage
            $printLine += $err
        }
        $printParams += $printLine
        $spacer = $true
    }
    if ($input_parameters.vm_owners) { 
        $input_parameters.vm_owners | %{
            if ($_.name -notmatch '^[a-z]+$') {
                $owners += "$($_.name) ($($_.email))$err`n`t`t`t`t"
                $result = $errorMessage
            } else {
                $owners += "$($_.name) ($($_.email))`n`t`t`t`t"
            }
        }
        $printParams += "vm_owners:`t`t`t$owners"
        $spacer = $true
    }
    if ($input_parameters.vm_DbSaUser) {
        $printLine = "vm_DbSaUser:`t`t`t$($input_parameters.vm_DbSaUser)"
        if ($input_parameters.vm_DbSaUser -notmatch '^[\w\.]+(\\\\)*\w+$') {
            $result = $errorMessage
            $printLine += $err
        }
        $printParams += $printLine
        $spacer = $true
    }
    if ($input_parameters.vm_DbSaPassw) {
        $printParams += "vm_DbSaPassw:`t`t`t*****"
        $spacer = $true
    }
    if ($input_parameters.vm_dailyDeployment) {
        $printLine = "vm_dailyDeployment:`t`t$($input_parameters.vm_dailyDeployment)"
        if ($input_parameters.vm_dailyDeployment -notmatch '^([01]?[0-9]|2[0-3]):[0-5][0-9]$') {
            $result = $errorMessage
            $printLine += $err
        }
        $printParams += $printLine
        $spacer = $true
    }

    #- machine-related parameters (Update)

    if ($input_parameters.vm_update_owners -and $input_parameters.vm_update_owners.keys) {
        $input_parameters.vm_update_owners | %{
            if ($_.name -notmatch '^[a-z]+$') {
                $owners += "$($_.name) ($($_.email))$err`n`t`t`t`t"
                $result = $errorMessage
            } else {
                $owners += "$($_.name) ($($_.email))`n`t`t`t`t"
            }
        }
        $printParams += "vm_owners:`t`t`t$owners"
        $spacer = $true
    }
    if ($input_parameters.vm_update_DbSaUser -and !([string]::IsNullOrEmpty($input_parameters.vm_update_DbSaUser))) {
        $printLine = "vm_update_DbSaUser:`t`t`t$($input_parameters.vm_update_DbSaUser)"
        if ($input_parameters.vm_update_DbSaUser -notmatch '^[\w\.]+(\\\\)*\w+$') {
            $result = $errorMessage
            $printLine += $err
        }
        $printParams += $printLine
        $spacer = $true
    }
    if ($input_parameters.vm_update_DbSaPassw) {
        $printParams += "vm_update_DbSaPassw:`t`t`t*****"
        $spacer = $true
    }
    if ($input_parameters.vm_update_dailyDeployment -and !([string]::IsNullOrEmpty($input_parameters.vm_update_dailyDeployment))) {
        $printLine = "vm_update_dailyDeployment:`t`t$($input_parameters.vm_update_dailyDeployment)"
        if ($input_parameters.vm_update_dailyDeployment -notmatch '^([01]?[0-9]|2[0-3]):[0-5][0-9]$') {
            $result = $errorMessage
            $printLine += $err
        }
        $printParams += $printLine
        $spacer = $true
    }

    #- machine-related parameters (Where)

    if ($input_parameters.where_name) {
        $printLine = ("where_name:`t`t`t" + ($input_parameters.where_name -join ','))
        $printParams += $printLine
        $spacer = $true
    }
    if ($input_parameters.where_purpose) {
        $printLine = ("where_purpose:`t`t`t" + ($input_parameters.where_purpose -join ','))
        $printParams += $printLine
        $spacer = $true
    }
    if ($input_parameters.where_owners) {
        $printLine = ("where_owners:`t`t`t" + ($input_parameters.where_owners -join ','))
        $printParams += $printLine
        $spacer = $true
    }
    if ($input_parameters.where_DbSaUser) {
        $printLine = ("where_DbSaUser:`t`t`t" + ($input_parameters.where_DbSaUser -join ','))
        $printParams += $printLine
        $spacer = $true
    }
    if ($input_parameters.where_DbSaPassw) {
        $printLine = ("where_DbSaPassw:`t`t`t" + ($input_parameters.where_DbSaPassw -join ','))
        $printParams += $printLine
        $spacer = $true
    }
    if ($input_parameters.where_dailyDeployment) {
        $printLine = ("where_dailyDeployment:`t`t`t" + ($input_parameters.where_dailyDeployment -join ', '))
        $printParams += $printLine
        $spacer = $true
    }

    #- display parameters

    $printParams += ("_"*60)

    if ($input_parameters.Verbose) {
        $printParams | %{Write-Host $_}
    }

    if ($input_parameters.vm_name) {
        Try {
            Test-Connection ($input_parameters.vm_name) -Count 1 -ErrorAction Stop | Out-Null
        } catch {
            $noConnectionMessage = "Connection to machine '$($input_parameters.vm_name)' failed."
            if ($failOnNoConnection) {
                throw $noConnectionMessage
            } else {
                Write-Warning $noConnectionMessage
            }
        }
    }

    return $result
}

function Get-ConnectionString
{
    [CmdletBinding()]
    param (
        [parameter(Position=0)]
        $input_parameters = $(throw "Mandatory argument not provided: <input_parameters>.")
    )

    $ErrorActionPreference = 'Stop'
    $connectionString = "mongodb://"
    $connectionString += $input_parameters.mongoUser
    $connectionString += ":"
    $connectionString += $input_parameters.mongoPassw
    $connectionString += "@"
    $connectionString += $input_parameters.mongoServer
    $connectionString += "/"
    $connectionString += $input_parameters.mongoDB
    Write-Verbose ("<connectionString> : " + ($connectionString -replace (':[^\/].*@',':******@')))

    return $connectionString
}

function isOwner
{
    [CmdletBinding()]
    param (
        [parameter(Position=0)]
        $Requester = $(throw "Mandatory argument not provided: <Requester>."),
        [parameter(Position=1)]
        $Owners = $(throw "Mandatory argument not provided: <Owners>.")
    )

    $ErrorActionPreference = 'Stop'

    foreach ($owner in $Owners) {
        if ($Requester -eq $owner.name) {
            return $true
        }
    }
}

function Show-Result
{
    [CmdletBinding()]
    param (
        [parameter(Position=0)]
        $scriptName = $(throw "Mandatory argument not provided: <scriptName>.")
    )

    Write-Host ":$scriptName`: done`n"
}