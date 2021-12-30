[CmdletBinding()]
param (
    [string]$outfile,
    [switch]$no_microsoft_apps
)


if ($no_microsoft_apps) {
    $apps = (Get-AppxPackage).name | ? { $_ -notlike '*microsoft*' } | sort
}
else {
    $apps = (Get-AppxPackage).name | sort
}

if ($outfile) {
    $apps | out-file $outfile -force -encoding ascii
}
else {
    $apps
}
