$ErrorActionPreference = 'Stop'

$hives = @{
    'HKCR' = 'HKEY_CLASSES_ROOT';
    'HKCU' = 'HKEY_CURRENT_USER';
    'HKLM' = 'HKEY_LOCAL_MACHINE';
    'HKU'  = 'HKEY_USERS';
    'HKCC' = 'HKEY_CURRENT_CONFIG'
}

$types = @{
    'REG_SZ'        = 'STRING';
    'REG_EXPAND_SZ' = 'EXPANDSTRING';
    'REG_MULTI_SZ'  = 'MULTISTRING';
    'REG_DWORD'     = 'DWORD';
    'REG_QWORD'     = 'QWORD';
    'REG_BINARY'    = 'BINARY'
}

$registryDrives = (Get-PSDrive | ? { $_.Provider.name -eq 'Registry' }).Name

foreach ($hive in $hives.Keys) {
    if ($hive -notin $registryDrives) {
        New-PSDrive -Name $hive -PSProvider Registry -Root $hives.$hive | Out-Null
    }
}



#--------------------------------------------------
function Convert-RegPath {
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$RegPath
    )

    process {
        # replace slashes with backslashes
        $RegPath = $RegPath.Replace('/', '\')

        # remove prefix 'Computer'
        $RegPath = $RegPath -replace '^Computer\\', ''

        # replace long-formatted name with abbreviation
        if ($RegPath.StartsWith('HKEY_')) {
            if ($RegPath -match '(^HKEY_[a-zA-Z_]+)\\') {
                $hiveLongName = $Matches[1]
                $hive = ($hives.GetEnumerator() | ? { $_.value -eq $hiveLongName }).name
                $RegPath = $RegPath.Replace($hiveLongName, $hive)
            }
        }

        # convert to PS provider path
        foreach ($hive in $hives.Keys) {
            if ($RegPath.ToUpper().StartsWith($hive)) {

                # only Registry-specific paths are validated
                $regPathValidated = $true

                if ($RegPath -notmatch '^[a-zA-Z]+:\\\.*') {
                    $RegPath = $RegPath -replace "^$hive", "$hive`:"
                }

                break
            }
        }

        if (!$regPathValidated) { throw "Failed to convert path `"$RegPath`"" }

        # send result to pipeline
        $RegPath
    }
}

#--------------------------------------------------
function New-RegKey {
    param (
        [Parameter(Position = 0)]
        [string]$RegPath = $(throw "Required argument not provided: <RegPath>."),

        [Parameter(Position = 1)]
        [switch]$Force
    )

    if (!$Force) { throw "Parameter -Force is required to confirm this operation." }

    $RegPath = Convert-RegPath $RegPath
    $paths = @()

    while (!(Test-Path $RegPath)) {
        $paths += , $RegPath
        $RegPath = $RegPath | Split-Path
    }
    try {
        $paths[($paths.Length - 1)..0] | % { New-Item $_ | Out-Null }
    }
    catch {
        if ($_.Exception -like "*Requested registry access is not allowed*") {
            throw "Access denied. Are you running as administrator?"
        }

        throw $_
    }
}

#--------------------------------------------------
function Show-RegKey {
    param (
        [Parameter(Position = 0)]
        [string]$RegPath = $(throw "Required argument not provided: <RegPath>."),

        [Parameter(Position = 1)]
        [switch]$SubKeys
    )

    $RegPath = Convert-RegPath $RegPath

    if ($SubKeys) {
        $keys = (Get-ChildItem $RegPath).name | sort | Split-Path -Leaf
        $keys
    }
    else {
        $keys = (Get-ChildItem $RegPath).name | sort
        $properties = (Get-Item $RegPath).property | sort
        $keys
        $properties
    }
}

#--------------------------------------------------
function Get-RegKeyProperties {
    param (
        [Parameter(Position = 0)]
        [string]$RegPath = $(throw "Required argument not provided: -RegPath."),

        [Parameter(Position = 1)]
        [string]$Filter = '*',

        [Parameter(Position = 2)]
        [switch]$Detailed,

        [Parameter(ParameterSetName = "detailed", Position = 3)]
        [ValidateScript({
                if (!$Detailed) { throw "Parameter -AsHashtable can only be used after -Detailed." }
                $true
            })]
        [switch]$AsHashtable
    )

    $RegPath = Convert-RegPath $RegPath
    $propNames = (Get-Item $RegPath).property | ? { $_ -like $Filter } | sort
    $propNameMaxLength = ($propNames | % { $_.length } | Measure-Object -Maximum).Maximum

    # return only properties names
    if (!$Detailed) { return $propNames }

    $properties = [ordered]@{}

    foreach ($prop in $propNames) {
        $propValue = Get-ItemProperty $RegPath | Select-Object -ExpandProperty $prop
        $propType = ([string](gi $RegPath).getvaluekind($prop)).toUpper()
        $properties.Add($prop, @{ 'value' = $propValue; 'type' = $propType })
    }

    # return null if no properties found
    if ($properties.Count -eq 0) { return $null }

    # return results as hashtable
    if ($AsHashtable) { return $properties }

    # return results as array of formatted strings
    if ($propNameMaxLength -gt 36) { $propNameMaxLength = 36 }
    $spacing = " " * 4
    $padName = $propNameMaxLength
    $padType = 12

    $output = @('Name'.PadRight($padName), 'Type'.PadRight($padType), 'Value' -join $spacing)
    $output += , ('----'.PadRight($padName), '----'.PadRight($padType), '----' -join $spacing)

    foreach ($prop in $properties.keys) {
        $propName = $prop
        if ($propName.length -gt $padName) { $propName = $propName.SubString(0, $padName - 3) + '...' }
        $output += , ($propName.PadRight($padName), $properties.$prop.type.PadRight($padType), $properties.$prop.value -join $spacing)
    }

    return $output
}

#--------------------------------------------------
function Get-RegKeyPropertyValue {
    param (
        [Parameter(Position = 0)]
        [string]$RegPath = $(throw "Required argument not provided: -RegPath."),

        [parameter(Position = 1)]
        [string]$Property = $(throw "Required argument not provided: -Property."),

        [parameter(Position = 2)]
        [switch]$GetType
    )

    $RegPath = Convert-RegPath $RegPath

    # return property value type
    if ($GetType) {
        $valueType = ([string](Get-Item $RegPath).getvaluekind($Property)).toUpper()
        if ($valueType -notin $types.Values) {
            throw "Uncknown value type `"$valueType`"."
        }
        return $valueType
    }

    # return property value
    $value = Get-ItemProperty $RegPath | Select-Object -ExpandProperty $Property
    return $value
}

#--------------------------------------------------
function Set-RegKeyPropertyValue {
    param (
        [parameter(Position = 0)]
        [string]$RegPath = $(throw "Required argument not provided: -RegPath."),

        [parameter(Position = 1)]
        [string]$Property = $(throw "Required argument not provided: -Property."),

        [parameter(Position = 2)]
        [string]$Value = $null,

        [parameter(Position = 3)]
        [ValidateSet('STRING', 'EXPANDSTRING', 'MULTISTRING', 'DWORD', 'QWORD', 'BINARY',
            'REG_SZ', 'REG_EXPAND_SZ', 'REG_MULTI_SZ', 'REG_DWORD', 'REG_QWORD', 'REG_BINARY',
            $null)]
        [string]$ValueType = $null,

        [parameter(Position = 4)]
        [switch]$Force
    )

    if (!$Force) { throw "Parameter -Force is required to confirm this operation." }

    $RegPath = Convert-RegPath $RegPath

    # if value type not explicitly specified, then check current type (if target property exists)
    if (!$ValueType) {
        try { $ValueType = Get-RegKeyPropertyValue $RegPath $Property -GetType }
        catch {}
    }

    # set default value type
    if (!$ValueType) {
        $ValueType = 'STRING'
    }

    # convert type name into PowerShell-accepted format
    if ($ValueType.StartsWith('REG_')) {
        $ValueType = $types.$ValueType
    }

    # create missing children directories in $RegPath
    New-RegKey $RegPath -Force:$Force

    # create key property with value
    try {
        New-ItemProperty $RegPath -Name $Property -PropertyType $ValueType -Value $Value -Force | Out-Null
    }
    catch {
        if ($_.Exception -like "*Cannot convert value * to type*") {
            $currentType = Get-RegKeyPropertyValue $RegPath -Property $Property -GetType
            throw "Value `"$Value`" cannot be converted into target property's current type `"$currentType`" (use -ValueType parameter to force change type)."
        }

        if ($_.Exception -like "*Requested registry access is not allowed*") {
            throw "Access denied. Are you running as administrator?"
        }

        throw $_
    }
}

#--------------------------------------------------
function Remove-RegKey {
    param(
        [Parameter(Position = 0)]
        [string]$RegPath = $(throw "Required argument not provided: <RegPath>."),

        [Parameter(Position = 1)]
        [switch]$Force
    )

    if (!$Force) { throw "Parameter -Force is required to confirm this operation." }

    $RegPath = Convert-RegPath $RegPath

    try {
        Remove-Item $RegPath -Force:$Force -Recurse
    }
    catch {
        if ($_.Exception -like "*Requested registry access is not allowed*") {
            throw "Access denied. Are you running as administrator?"
        }

        throw $_
    }
}

#--------------------------------------------------
function Remove-RegKeyProperty {
    param(
        [Parameter(Position = 0)]
        [string]$RegPath = $(throw "Required argument not provided: <RegPath>."),

        [parameter(Position = 1)]
        [string]$Property = $(throw "Required argument not provided: -Property."),

        [Parameter(Position = 2)]
        [switch]$Force
    )

    if (!$Force) { throw "Parameter -Force is required to confirm this operation." }

    $RegPath = Convert-RegPath $RegPath

    try {
        Remove-ItemProperty $RegPath -Name $Property -Force:$Force
    }
    catch {
        if ($_.Exception -like "*Requested registry access is not allowed*") {
            throw "Access denied. Are you running as administrator?"
        }

        throw $_
    }
}


Export-ModuleMember -Function New-RegKey,
                              Show-RegKey,
                              Get-RegKeyProperties,
                              Get-RegKeyPropertyValue,
                              Set-RegKeyPropertyValue,
                              Remove-RegKey,
                              Remove-RegKeyProperty
