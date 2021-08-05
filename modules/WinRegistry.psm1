function Get-RegistryValue {
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

function Get-RegistryValueDataType ([string]$key, [string]$item) {
    $ErrorActionPreference = 'Stop'

    $itemType = ([string](gi $key -ErrorAction Stop).getvaluekind($item)).toUpper()
    if ($itemType -notin 'STRING', 'EXPANDSTRING', 'BINARY', 'DWORD', 'MULTISTRING', 'QWORD') {
        return $null
    }
    return $itemType
}

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
