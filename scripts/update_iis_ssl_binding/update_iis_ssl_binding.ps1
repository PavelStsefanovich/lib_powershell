[CmdletBinding(HelpUri = "")]
Param (
    [Parameter(Mandatory=$true)]
    [string]$Certfile,

    [Parameter(Mandatory=$true)]
    [string]$CertPassw,

    [string]$CaCertFile,

    [string]$DomainName,

    [string]$WORKSPACE = $PSScriptRoot,

    [string]$Website = 'Default Web Site'
)


$ErrorActionPreference = 'Stop'
$errorPref = "!!ERROR: "
try {
    $certRootStore = "LocalMachine"
    $certStore = "WebHosting"
    if ($Certfile -notmatch '[a-zA-Z]\:(\\|\/)\w') {
        $Certfile = $WORKSPACE + "\" + $Certfile.TrimStart('.\/')
    }
    if (!(Test-Path $Certfile)) {throw ($errorPref + "Certificate file not found: '$Certfile'")}
    if ((gci $Certfile).Extension -ne '.pfx') {throw ($errorPref + "Only .pfx certificates files accepted for Binding")}
    if ($CaCertFile) {
        if ($CaCertFile -notmatch '[a-zA-Z]\:(\\|\/)\w') {
            $CaCertFile = $WORKSPACE + "\" + $CaCertFile.TrimStart('.\/')
        }
        if (!(Test-Path $CaCertFile)) {throw ($errorPref + "Certificate file not found: '$CaCertFile'")}
        if ((gci $CaCertFile).Extension -ne '.crt') {throw ($errorPref + "Only .crt certificates files accepted for CA Root")}
    }
    if (!(Test-Path 'C:\inetpub\wwwroot')) {
        throw ($errorPref + "Path not found: 'C:\inetpub\wwwroot'")
    }

    Write-Host "  - Importing certificate from file: '$Certfile'"
    foreach ($cert in (ls Cert:\LocalMachine -Recurse | ?{$_.Subject -like "*$DomainName*"})) {
        rm ("cert:\" + (convert-path $cert.PSPath -ErrorAction SilentlyContinue)) -Force -Recurse
    }
    $pfx = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $pfx.Import($Certfile,$CertPassw,"Exportable,PersistKeySet,MachineKeySet")
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore)
    $store.Open('ReadWrite')
    $store.Add($pfx)
    $store.Close()
    $certThumbprint = $pfx.Thumbprint

    Write-Host '  - Binding certificate with Thumbprint' $certThumbprint
    Get-WebBinding -Protocol 'https' | Remove-WebBinding
    New-WebBinding -Name $Website -IP "*" -Port 443 -Protocol https | Out-Null
    gci IIS:\SslBindings\*!443 | rm -Force
    gi "Cert:\$certRootStore\$certStore\$certThumbprint" | ni 'IIS:\SslBindings\0.0.0.0!443' -Force -ErrorAction stop | Out-Null

    Write-Host "  - Importing CA Root certificate from file: '$CaCertFile'"
    if ($CaCertFile) {
        Import-Certificate $CaCertFile -CertStoreLocation Cert:\LocalMachine\Root -ErrorAction Stop | Out-Null
    }

    Write-Host "`n SUCCESS"
} catch {
    Write-Host "`n FAILED"
    throw $_
}
