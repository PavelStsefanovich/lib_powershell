param (
    [string]$javaHome = $(throw "!!ARGUMENT MISSING <javaHome>: path to Java home directory is required"),
    [string]$certificatesDir = $(throw "!!ARGUMENT MISSING <certificatesDir>: path to certificates directory is required"),
    [hashtable]$certificates,
    [string[]]$certExtensions = @('cer','der'),
    [string]$castorePassw = "changeit",
    [switch]$forceJavaCertsReplace
)


function Check-IfCertificateExists ($javaHome,$certAlias,$castorePassw) {
    $exitCode = (start "$javaHome\bin\keytool.exe" -ArgumentList "-list -v -keystore `"$javaHome\lib\security\cacerts`" -storepass $castorePassw -alias $certAlias -noprompt" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$scriptDir\null").ExitCode
    rm "$scriptDir\null" -Force -ErrorAction SilentlyContinue
    if ($exitCode -eq 0) {
        Write-Host " <$certAlias> already in keystore"
        return $true
    } else {
        return $false
    }
}

function Remove-ExistingCertificate ($javaHome,$certAlias,$castorePassw) {
    Write-Host " Removing certificate: <$certAlias> ..."
    $exitCode1 = (start "$javaHome\bin\keytool.exe" -ArgumentList "-delete -alias $certAlias -storepass $castorePassw -keystore `"$javaHome\lib\security\cacerts`"" -NoNewWindow -Wait -PassThru).ExitCode
    if ($exitCode1 -ne 0) {
        throw ($errorPref + "Failed to remove existing certificate with alias: <$certAlias>")
    }
}

function Install-Certificate ($javaHome,$certificatePath,$certAlias,$castorePassw) {
    Write-Host " Installing certificate: <$certAlias> ..."
    $exitCode = (start "$javaHome\bin\keytool.exe" -ArgumentList "-importcert -file `"$certificatePath`" -alias $certAlias -storepass $castorePassw -keystore `"$javaHome\lib\security\cacerts`" -noprompt" -NoNewWindow -Wait -PassThru).ExitCode
    if ($exitCode -ne 0) {
        throw ($errorPref + "Failed to install certificate <$certAlias>: '$certificatePath'")
    }
    Write-Host " <$certAlias> installed succsessfully"
}

#- initialization
$Global:errorPref = "!!ERROR: "
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (!$IsAdmin) {throw ($errorPref + "This script must run as Administrator")}

$Global:scriptDir = $PSScriptRoot
$javaHome = $javaHome.TrimEnd('\/')
$certificatesDir = $certificatesDir.TrimEnd('\/')


#- print parameters
Write-Host ("`n(script) " + $MyInvocation.MyCommand.Name + "`n(args)")
Write-Host ("  javaHome:`t`t`t$javaHome")
Write-Host ("  certificatesDir:`t`t$certificatesDir")
if ($certificates) {
    $certificates.GetEnumerator().name | %{Write-Host "`t`t`t`t - $_"}
} elseif ($certExtensions) {
    $certExtensions | %{Write-Host "`t`t`t`t - *$_"}
} else {
    throw ($errorPref + "One of the following is required: [hash]<certificates> or [string]<certExtensions>")
}
Write-Host ("  forceJavaCertsReplace:`t$forceJavaCertsReplace")
if ($castorePassw -eq 'changeit') {
    Write-Host "  castorePassw:`t`tdefault"
} else {
    Write-Host "  castorePassw:`t`t*****"
}
Write-Host "`n"


#- search for matching certificates in certificates directory
if ($certExtensions -and !$certificates) {
    for ($i = 0; $i -lt $certExtensions.Count; $i++) {
        $certExtensions[$i] = "*" + $certExtensions[$i]
    }
    $foundCerts = ls "$certificatesDir\*" -Include $certExtensions
    if ($foundCerts) {
        $certificates = @{}
        $foundCerts | %{
            $certificates.Add($_.Name,$_.Name.Replace('.','_'))
        }
    } else {
        throw ($errorPref + "No matching certificates found in ")
    }
}


#- install wildcard certs to Java CA store
Write-Host "Installing certificates to Java CA store at: '$javaHome\lib\security\cacert'"

foreach ($cert in $certificates.GetEnumerator().name) {
    Write-Host " - $cert ..."
    $certAlias = $certificates.$cert
    if (Check-IfCertificateExists -javaHome "$javaHome" -certAlias $certAlias -castorePassw $castorePassw) {
        if ($forceJavaCertsReplace) {
            Remove-ExistingCertificate -javaHome "$javaHome" -certAlias $certAlias -castorePassw $castorePassw
            Install-Certificate -javaHome "$javaHome" -certificatePath "$certificatesDir\$cert" -certAlias $certAlias -castorePassw $castorePassw
        }
    } else {
        Install-Certificate -javaHome "$javaHome" -certificatePath "$certificatesDir\$cert" -certAlias $certAlias -castorePassw $castorePassw
    }
}