$hives = @{
    'HKCR' = 'HKEY_CLASSES_ROOT';
    'HKCU' = 'HKEY_CURRENT_USER';
    'HKLM' = 'HKEY_LOCAL_MACHINE';
    'HKU'  = 'HKEY_USERS';
    'HKCC' = 'HKEY_CURRENT_CONFIG'
}

$registryDrives = (Get-PSDrive | ? { $_.Provider.name -eq 'Registry' }).Name

foreach ($hive in $hives.Keys) {
    if ($hive -notin $registryDrives) {
        New-PSDrive -Name $hive -PSProvider Registry -Root $hives.$hive -ErrorAction stop | Out-Null
    }
}



#--------------------------------------------------
function Convert-RegistryPath {
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
function Show-RegKey {
    param(
        [string]$RegPath = $(throw "Required argument not provided: <RegPath>."),
        [switch]$SubKeys
    )

    $RegPath = Convert-RegistryPath $RegPath

    if ($SubKeys) {
        $keys = (ls $RegPath).name | sort | Split-Path -Leaf
        $keys
    }
    else {
        $keys = (ls $RegPath).name | sort
        $properties = (gi $RegPath).property | sort
        $keys
        $properties
    }
}


function Get-RegKeyProperties {
    [CmdletBinding()]
    param (
        [parameter()]
        [string]$key = $(throw "Mandatory argument not provided: <key>."),

        [parameter()]
        [string]$item = '*'
    )

    $ErrorActionPreference = 'Stop'
    $regValues = (gi $key).property | ? { $_ -like $item }
    return $regValues
}

#--------------------------------------------------
function Get-RegistryValueData {
    [CmdletBinding()]
    param (
        [parameter()]
        [string]$key = $(throw "Mandatory argument not provided: <key>."),

        [parameter()]
        [string]$item = $(throw "Mandatory argument not provided: <item>.")
    )

    $ErrorActionPreference = 'Stop'
    $keyValue = Get-ItemProperty $key | Select-Object -ExpandProperty $item
    return $keyValue
}

#--------------------------------------------------
function Get-RegistryValueDataType ([string]$key, [string]$item) {
    $ErrorActionPreference = 'Stop'

    $itemType = ([string](gi $key -ErrorAction Stop).getvaluekind($item)).toUpper()
    if ($itemType -notin 'STRING', 'EXPANDSTRING', 'BINARY', 'DWORD', 'MULTISTRING', 'QWORD') {
        return $null
    }
    return $itemType
}

#--------------------------------------------------
function Set-RegistryValueData {
    [CmdletBinding()]
    param (
        [parameter()]
        [string]$key = $(throw "Mandatory argument not provided: <key>."),

        [parameter()]
        [string]$item = $(throw "Mandatory argument not provided: <item>."),

        [parameter()]
        [ValidateSet('STRING', 'EXPANDSTRING', 'BINARY', 'DWORD', 'MULTISTRING', 'QWORD', $null)]
        [string]$itemType = $null,

        [parameter()]
        $value = $null
    )

    $ErrorActionPreference = 'Stop'

    if ($key.StartsWith('Computer\')) {
        $key = $key.Substring(9)
    }

    if ($key.StartsWith('HKEY_CURRENT_USER\')) {
        $key = "HKCU:" + $key.Substring(17)
    }

    if ($key.StartsWith('HKEY_LOCAL_MACHINE\')) {
        $key = "HKLM:" + $key.Substring(18)
    }

    if (!$itemType) {
        $itemType = Get-RegistryValueDataType $key -item $item
    }

    if (!$itemType) {
        $itemType = 'STRING'
    }

    #- create missing directories in $key
    $path = $key
    $paths = @()
    while (!(Test-Path $path)) {
        $paths += $path
        $path = $path | Split-Path
    }
    $paths[($paths.Length - 1)..0] | % { New-Item $_ | Out-Null }

    #- create registry value with data
    New-ItemProperty $key -Name $item -PropertyType $itemType -Value $value -Force | Out-Null
}

Export-ModuleMember -Function *



# TODO WinRegistry

# public:
# Get-RegKey : list subkeys and values
# Get-RegKeyValues : filtered list of the key values
# Get-RegValueData : return value of specific key attribute
# Get-RegValueDataType : return type of specific key attribute value
# Set-RegValueData : set value of specific key attribute

# private:
# convert registry path to PS format: HKLM:\
# convert registry path to REGEDIT format: HKEY_LOCAL_MACHINE
