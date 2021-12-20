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

$registryDrives = (Get-PSDrive | Where-Object { $_.Provider.name -eq 'Registry' }).Name

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
                $hive = ($hives.GetEnumerator() | `
                    Where-Object { $_.value -eq $hiveLongName }).name
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

    <#
    .Description
    Converts Registry path into format supported by PowerShell provider.
    This is internal function and is not exported on module import.
    .PARAMETER RegPath
    Specifies full path to the target Registry key.
    Example: -RegPath Computer\HKEY_LOCAL_MACHINE\SOFTWARE\<some_key>
    Example: -RegPath HKLM/SOFTWARE/<some_key>
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/WinRegistry
    #>
}

#--------------------------------------------------
function New-RegKey {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$RegPath,

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
        $paths[($paths.Length - 1)..0] | `
            ForEach-Object { New-Item $_ | Out-Null }
    }
    catch {
        if ($_.Exception -like "*Requested registry access is not allowed*") {
            throw "Access denied. Are you running as administrator?"
        }

        throw $_
    }

    <#
    .Description
    Creates new Registry key, if it does not exist already.
    Automatically creates missing subkeys in the path.
    .PARAMETER RegPath
    Specifies full path to the target Registry key.
    Example: -RegPath Computer\HKEY_LOCAL_MACHINE\SOFTWARE\<some_key>
    Example: -RegPath HKLM/SOFTWARE/<some_key>
    .PARAMETER Force
    Required parameter. Use to confirm your intent to proceed.
    Example: -Force
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/WinRegistry
    #>
}

#--------------------------------------------------
function Show-RegKey {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$RegPath,

        [Parameter(Position = 1)]
        [switch]$SubKeys
    )

    $RegPath = Convert-RegPath $RegPath

    if ($SubKeys) {
        $keys = (Get-ChildItem $RegPath).name | `
            Sort-Object | Split-Path -Leaf
        $keys
    }
    else {
        $keys = (Get-ChildItem $RegPath).name | Sort-Object
        $properties = (Get-Item $RegPath).property | Sort-Object
        $keys
        $properties
    }

    <#
    .Description
    Lists subkeys (with full paths) and properties of the target Registry key.
    Optionally only lists subkeys names.
    .PARAMETER RegPath
    Specifies full path to the target Registry Key.
    Example: -RegPath Computer\HKEY_LOCAL_MACHINE\SOFTWARE\<some_key>
    Example: -RegPath HKLM/SOFTWARE/<some_key>
    .PARAMETER SubKeys
    Only lists subkeys names of the target Registry key.
    Example: -SubKeys
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/WinRegistry
    #>
}

#--------------------------------------------------
function Get-RegKeyProperties {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$RegPath,

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
    $propNames = (Get-Item $RegPath).property | `
        Where-Object { $_ -like $Filter } | Sort-Object
    $propNameMaxLength = ($propNames | `
        ForEach-Object { $_.length } | Measure-Object -Maximum).Maximum

    # return only properties names
    if (!$Detailed) { return $propNames }

    $properties = [ordered]@{}

    foreach ($prop in $propNames) {
        $propValue = Get-ItemProperty $RegPath | Select-Object -ExpandProperty $prop
        $propType = ([string](Get-Item $RegPath).getvaluekind($prop)).toUpper()
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

    <#
    .Description
    Lists properties of the target Registry key. Accepts filters.
    Optionally shows properties' values and types.
    Optionally returns result set as hashtable.
    .PARAMETER RegPath
    Specifies full path to the target Registry Key.
    Example: -RegPath Computer\HKEY_LOCAL_MACHINE\SOFTWARE\<some_key>
    Example: -RegPath HKLM/SOFTWARE/<some_key>
    .PARAMETER Filter
    Specifies filter for properties names to be included into result set.
    Example: -Filter propname*
    .PARAMETER Detailed
    Includes properties' values and types.
    Example: -Detailed
    .PARAMETER AsHashtable
    Returns result set as hashtable.
    Requires parameter -Detailed to be specified first (must appear before -AsHashtable).
    Example: -AsHashtable
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/WinRegistry
    #>
}

#--------------------------------------------------
function Get-RegKeyPropertyValue {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$RegPath,

        [parameter(Position = 1, Mandatory = $true)]
        [string]$Property,

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

    <#
    .Description
    Returns value of specific Registry key property.
    Optionally returns property type instead of value.
    .PARAMETER RegPath
    Specifies full path to the target Registry Key.
    Example: -RegPath Computer\HKEY_LOCAL_MACHINE\SOFTWARE\<some_key>
    Example: -RegPath HKLM/SOFTWARE/<some_key>
    .PARAMETER Property
    Specifies target Registry key property.
    Example: -Property <property_name>
    .PARAMETER GetType
    Returns property type instead of value.
    Example: -GetType
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/WinRegistry
    #>
}

#--------------------------------------------------
function Set-RegKeyPropertyValue {
    param (
        [parameter(Position = 0, Mandatory = $true)]
        [string]$RegPath,

        [parameter(Position = 1, Mandatory = $true)]
        [string]$Property,

        [parameter(Position = 2)]
        [string]$Value = $null,

        [parameter(Position = 3)]
        [ValidateSet('STRING', 'EXPANDSTRING', 'MULTISTRING', 'DWORD', 'QWORD', 'BINARY',
            'REG_SZ', 'REG_EXPAND_SZ', 'REG_MULTI_SZ', 'REG_DWORD', 'REG_QWORD', 'REG_BINARY',
            $null)]
        [string]$ValueType = $null,

        [parameter()]
        [switch]$Force
    )

    if (!$Force) { throw "Parameter -Force is required to confirm this operation." }

    $RegPath = Convert-RegPath $RegPath
    $UserInputValueType = $ValueType

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
            if ($UserInputValueType) {
                throw "Value `"$Value`" cannot be converted into type `"$ValueType`"."
            }
            else {
                $currentType = Get-RegKeyPropertyValue $RegPath -Property $Property -GetType
                throw "Value `"$Value`" cannot be converted into target property's current type `"$currentType`" (use -ValueType parameter to force change type)."
            }
        }

        if ($_.Exception -like "*Requested registry access is not allowed*") {
            throw "Access denied. Are you running as administrator?"
        }

        throw $_
    }

    <#
    .Description
    Sets value and type of specific Registry key property. Creates new property, if does not exist already.
    If type is not specified, uses current type of the target property (value must be of the same type).
    If type is not specified and property does not not exist, defaults to 'REG_SZ'.
    .PARAMETER RegPath
    Specifies full path to the target Registry Key.
    Example: -RegPath Computer\HKEY_LOCAL_MACHINE\SOFTWARE\<some_key>
    Example: -RegPath HKLM/SOFTWARE/<some_key>
    .PARAMETER Property
    Specifies target Registry key property.
    Example: -Property <property_name>
    .PARAMETER Value
    Specifies new value.
    Example: -Value <value>
    .PARAMETER ValueType
    Specifies new value type.
    CAUTION: if specified while target property exists, will force-udate of property type.
    If not specified while target property exists, will use current property type.
    Example: -ValueType DWORD
    .PARAMETER Force
    Required parameter. Use to confirm your intent to proceed.
    Example: -Force
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/WinRegistry
    #>
}

#--------------------------------------------------
function Remove-RegKey {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$RegPath,

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

    <#
    .Description
    Deletes target Registry key and all its children (subkeys and properties).
    .PARAMETER RegPath
    Specifies full path to the target Registry Key.
    Example: -RegPath Computer\HKEY_LOCAL_MACHINE\SOFTWARE\<some_key>
    Example: -RegPath HKLM/SOFTWARE/<some_key>
    .PARAMETER Force
    Required parameter. Use to confirm your intent to proceed.
    Example: -Force
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/WinRegistry
    #>
}

#--------------------------------------------------
function Remove-RegKeyProperty {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$RegPath,

        [parameter(Position = 1, Mandatory = $true)]
        [string]$Property,

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

    <#
    .Description
    Deletes specific Registry key property.
    .PARAMETER RegPath
    Specifies full path to the target Registry Key.
    Example: -RegPath Computer\HKEY_LOCAL_MACHINE\SOFTWARE\<some_key>
    Example: -RegPath HKLM/SOFTWARE/<some_key>
    .PARAMETER Property
    Specifies target Registry key property.
    Example: -Property <property_name>
    .PARAMETER Force
    Required parameter. Use to confirm your intent to proceed.
    Example: -Force
    .LINK
    https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/WinRegistry
    #>
}


Export-ModuleMember -Function New-RegKey,
                              Show-RegKey,
                              Get-RegKeyProperties,
                              Get-RegKeyPropertyValue,
                              Set-RegKeyPropertyValue,
                              Remove-RegKey,
                              Remove-RegKeyProperty
