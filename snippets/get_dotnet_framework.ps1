[CmdletBinding(HelpUri = "https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed#ps_a")]
Param(
    [string]$targetVersion
)


$ErrorActionPreference = 'Stop'
$errPref = "!!ERROR:"
$warnPref = "(!)"

$dotNetRegistryKey = "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\"

$dotNetReleases = @{
    "4.5"   = 378389;
    "4.5.1"	= 378675;
    "4.5.2"	= 379893;
    "4.6"   = 393295;
    "4.6.1"	= 394254;
    "4.6.2"	= 394802;
    "4.7"   = 460798;
    "4.7.1"	= 461308;
    "4.7.2"	= 461808
}
$dotNetVersions = ($dotNetReleases.GetEnumerator() | sort -Property value).name

#=== Begin

$release = (Get-ItemProperty $dotNetRegistryKey -Name Release).Release
if (!$release) { throw "$errPref Unable to read registry at $dotNetRegistryKey\Release." }
if ($release -lt $dotNetReleases.($dotNetVersions[0])) { throw "errPref .Net 4.5 or later is not detected." }

if ($targetVersion) {
    if ($targetVersion -notin $dotNetVersions) {
        Write-Warning "$warnPref <targetVersion> '$targetVersion' is not in the list of supported versions:"
        $dotNetVersions | % { Write-Warning $_ }
        exit
    }

    if ($dotNetReleases."$targetVersion" -le $release) {
        return $true
    }
    else {
        return $false
    }

}
else {
    Write-Host "`nInstalled .Net Framework versions:"
    $dotNetVersions | % {
        if ($dotNetReleases."$_" -le $release) {
            Write-Host " - $_"
        }
    }

}
