[CmdletBinding()]
param(
    [string]$path_to_file,
    [int]$tab_size = 4
)

$ErrorActionPreference = 'Stop'
$converted_content = @()

Get-Content $path_to_file | % {
    $line = $_
    while ( $true ) {
        $i = $line.IndexOf([char] 9)
        if ( $i -eq -1 ) { break }
        if ( $tab_size -gt 0 ) {
            $pad = " " * ($tab_size - ($i % $tab_size))
        }
        else {
            $pad = ""
        }
        $line = $line -replace "^([^\t]{$i})\t(.*)$",
        "`$1$pad`$2"
    }
    $converted_content += $line
}

Set-Content $path_to_file -Value $converted_content -Force
