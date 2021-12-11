param (
    [string]$nodePropertiesFilePath,
    [switch]$forceNodeRecreate,
		[switch]$forceSlaveReinstall,
    [switch]$forceJavaCertsReplace,
    [switch]$UninstallOracleJava,
	[switch]$auto
)

function Read-NodeProperties ([string]$nodePropertiesFilePath) {
    $erPr = "!!MANDATORY PROPERTY MISSING: "
    (cat "$nodePropertiesFilePath" -Encoding UTF8) -replace ('(?<!\\)\\(?!\\)','\\') | Set-Content "$nodePropertiesFilePath" -Force -Encoding UTF8
    try {
        $nodeProperties = ConvertFrom-StringData (cat $nodePropertiesFilePath -Raw) -ErrorAction stop
    } catch {
        Write-Host $_
        throw ($errorPref + "Can not read node properties file: '$nodePropertiesFilePath'")
    }

    if (!$nodeProperties.ContainsKey('jenkinsUrl')) {throw ($erPr + "<jenkinsUrl>")}
    if (!$nodeProperties.ContainsKey('user')) {throw ($erPr + "<user>")}
    if (!$nodeProperties.ContainsKey('apiToken')) {throw ($erPr + "<apiToken>")}
    if (!$nodeProperties.ContainsKey('numberOfExecutors')) {throw ($erPr + "<numberOfExecutors>")}
    if (!$nodeProperties.ContainsKey('usageMode')) {throw ($erPr + "<usageMode>")}
    if (!$nodeProperties.ContainsKey('jenkinsFolder')) {throw ($erPr + "<jenkinsFolder>")}
    if (!$nodeProperties.ContainsKey('winswVersion')) {throw ($erPr + "<winswVersion>")}
    if (!$nodeProperties.nodeName) {
        $nodeProperties.nodeName = ($env:COMPUTERNAME).ToLower()
    } else {
        $nodeProperties.nodeName = $nodeProperties.nodeName.ToLower()
    }
    if (!$nodeProperties.labels) {$nodeProperties.labels = "auto-generated"}
    if (!$nodeProperties.downloadFolder) {$nodeProperties.downloadFolder = $PSScriptRoot}
		if (!$nodeProperties.serviceDomain) {$nodeProperties.serviceDomain = $env:COMPUTERNAME}
		if (!$nodeProperties.serviceUser) {$nodeProperties.serviceUser = "default"}
		if (!$nodeProperties.servicePassw) {$nodeProperties.servicePassw = "default"}
		
    return $nodeProperties
}

function Install-ZuluJre($nodeProperties)
{
    try
    {
        $DataStamp = get-date -Format yyyyMMddTHHmmss
        $javaInstaller = (ls $($nodeProperties.downloadFolder) -Filter 'zulu*.msi')[0].FullName        
        $logFile = '{0}-{1}.log' -f $javaInstaller,$DataStamp
        $installLocation = $nodeProperties.javaInstallLocation
        $javaHomeDir = $nodeProperties.javaHomeDir
        $MSIArguments = @(
            "/i"
            ('"{0}"' -f $javaInstaller)    
            ('APPLICATIONROOTDIRECTORY="{0}"' -f $installLocation)    
            "/qn"
            "/norestart"    
        )
#        Write-Output "MSI Arguments are: $MSIArguments"
        $exitCode = (Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow -PassThru -ErrorAction stop).ExitCode
        if($exitCode -eq 0)
        {
            [System.Environment]::SetEnvironmentVariable('JAVA_HOME', $javaHomeDir,[System.EnvironmentVariableTarget]::Machine)
            return $true            
        }
        return $false
    }
    catch {
            Write-Host $_
            throw ($errorPref + "Could not able to install Zulu Jre '$nodePropertiesFilePath'")
        }
}

function Write-NodeProperties ($nodeProperties,[string]$nodePropertiesFilePath) {
    $NodePropertiesFilenameBkp = "bkp-" + ($nodePropertiesFilePath | Split-Path -Leaf)
    $nodePropertiesFilePathBkp = ($nodePropertiesFilePath | Split-Path) + "\$NodePropertiesFilenameBkp"
    if (!(Test-Path $nodePropertiesFilePathBkp)) {cp $nodePropertiesFilePath -Destination $nodePropertiesFilePathBkp -Force -ErrorAction Stop}
    rm $nodePropertiesFilePath -Force -ErrorAction Stop

    ($nodeProperties.GetEnumerator()).name | %{$nodeProperties.$_ = $nodeProperties.$_ -replace ('(?<!\\)\\(?!\\)','\\')}

    Try {
        "jenkinsUrl=$($nodeProperties.jenkinsUrl)" | Out-File $nodePropertiesFilePath -Append -Encoding utf8 -Force
        "user=$($nodeProperties.user)" | Out-File $nodePropertiesFilePath -Append -Encoding utf8 -Force
        "apiToken=$($nodeProperties.apiToken)" | Out-File $nodePropertiesFilePath -Append -Encoding utf8 -Force
        "nodeName=$($nodeProperties.nodeName)" | Out-File $nodePropertiesFilePath -Append -Encoding utf8 -Force
        "labels=$($nodeProperties.labels)" | Out-File $nodePropertiesFilePath -Append -Encoding utf8 -Force
        "numberOfExecutors=$($nodeProperties.numberOfExecutors)" | Out-File $nodePropertiesFilePath -Append -Encoding utf8 -Force
        "usageMode=$($nodeProperties.usageMode)" | Out-File $nodePropertiesFilePath -Append -Encoding utf8 -Force
        "jenkinsFolder=$($nodeProperties.jenkinsFolder)" | Out-File $nodePropertiesFilePath -Append -Encoding utf8 -Force
        "javaInstallLocation=$($nodeProperties.javaInstallLocation)" | Out-File $nodePropertiesFilePath -Append -Encoding utf8 -Force
        "javaHome=$($nodeProperties.javaHome)" | Out-File $nodePropertiesFilePath -Append -Encoding utf8 -Force
        "javaHomeDir=$($nodeProperties.javaHomeDir)" | Out-File $nodePropertiesFilePath -Append -Encoding utf8 -Force
        "winswVersion=$($nodeProperties.winswVersion)" | Out-File $nodePropertiesFilePath -Append -Encoding utf8 -Force
				"serviceDomain=$($nodeProperties.serviceDomain)" | Out-File $nodePropertiesFilePath -Append -Encoding utf8 -Force
				"serviceUser=$($nodeProperties.serviceUser)" | Out-File $nodePropertiesFilePath -Append -Encoding utf8 -Force
				"servicePassw=$($nodeProperties.servicePassw)" | Out-File $nodePropertiesFilePath -Append -Encoding utf8 -Force
        "downloadFolder=$($nodeProperties.downloadFolder)" | Out-File $nodePropertiesFilePath -Append -Encoding utf8 -Force
    } catch {
        Write-Error $_
        return $false
    }    
    return $true
}

function Get-ZuluJREInstallLocation($nodeProperties)
{
    try
    {
        $ZuluKey = 'HKLM:\SOFTWARE\Azul Systems\Zulu\zulu-8'        
        $javaInstallations = Get-ItemProperty -Path $ZuluKey -ErrorAction SilentlyContinue       
        if ($javaInstallations.InstallationPath) {
            $latestJavaRE = $javaInstallations.InstallationPath
            return $latestJavaRE
        } else {
            return $null
        }
    }
    catch {
            Write-Host $_
            throw ($errorPref + "Failed to get Zulu jre install location '$nodePropertiesFilePath'")
        }
}

function Get-JreInstallation {
    $uninstallKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    $installedSoftware = gp (ls $uninstallKey).name.Replace('HKEY_LOCAL_MACHINE','HKLM:')
    $javaInstallations = $installedSoftware | ?{($_.displayname -like 'Java *') -and ($_ -notlike '*SE Dev*')} | sort version -Descending
    if ($javaInstallations) {
        $latestJavaRE = $javaInstallations[0]
        return $latestJavaRE
    } else {
        return $null
    }
}


#=== Begin ===

$Global:errorPref = "!!ERROR: "
$scriptDir = $PSScriptRoot
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (!$IsAdmin) {throw ($errorPref + "This script must run as Administrator")}

#- read node properties file
if (!$nodePropertiesFilePath) {$nodePropertiesFilePath = "$scriptDir\node.properties"}
if (!(Test-Path $nodePropertiesFilePath)) {throw ($errorPref + "Node properties file does not exist: $nodePropertiesFilePath")}
$nodeProperties = Read-NodeProperties $nodePropertiesFilePath

Write-Host ("`n(script) " + $MyInvocation.MyCommand.Name + "`n(args)")
Write-Host ("  nodePropertiesFilePath:`t$nodePropertiesFilePath")
Write-Host ("  forceNodeRecreate:`t`t$forceNodeRecreate")
Write-Host ("  forceSlaveReinstall:`t`t$forceSlaveReinstall")
Write-Host ("  forceJavaCertsReplace:`t$forceJavaCertsReplace")
Write-Host (" UninstallOracleJava:`t$UninstallOracleJava")
Write-Host ("  auto:`t`t`t`t$auto")
Write-Host "(props)"
Write-Host ("  jenkinsUrl:`t`t`t$($nodeProperties.jenkinsUrl)")
Write-Host ("  user:`t`t`t`t$($nodeProperties.user)")
Write-Host ("  apiToken:`t`t`t*****")
Write-Host ("  nodeName:`t`t`t$($nodeProperties.nodeName)")
Write-Host ("  labels:`t`t`t$($nodeProperties.labels)")
Write-Host ("  numberOfExecutors:`t`t$($nodeProperties.numberOfExecutors)")
Write-Host ("  usageMode:`t`t`t$($nodeProperties.usageMode)")
Write-Host ("  jenkinsFolder:`t`t$($nodeProperties.jenkinsFolder)")
Write-Host ("  javaHome:`t`t`t$($nodeProperties.javaHome)")
Write-Host ("  javaHomeDir:`t`t`t$($nodeProperties.javaHomeDir)")
Write-Host ("  winswVersion:`t`t`t$($nodeProperties.winswVersion)")
Write-Host ("  serviceDomain:`t`t$($nodeProperties.serviceDomain)")
Write-Host ("  serviceUser:`t`t`t$($nodeProperties.serviceUser)")
Write-Host ("  servicePassw:`t`t`t*****")
Write-Host ("  downloadFolder:`t`t$($nodeProperties.downloadFolder)")

#- ensure that Java RE installed
Write-Output $nodeProperties.javaHome
$latestJavaRe = Get-ZuluJREInstallLocation
if (!$latestJavaRe) {
    if ($auto) {throw ($errorPref + "Java Runtime Environment not found")}

    if (!(Test-Path "$($nodeProperties.downloadFolder)\zulu*")) {
        . $scriptDir\Get.Binaries.ps1 -java -downloadFolder "$($nodeProperties.downloadFolder)"
    }    
    Write-Host 'Installing Zulu Java RE ...'   
    $InstallJreResult = Install-ZuluJre($nodeProperties)
    Write-Host $InstallJreResult
    if ($InstallJreResult -ne $true) {
        throw ($errorPref + "Failed to install Java RE")
    }
    $latestJavaRe = Get-ZuluJREInstallLocation
    #$latestJavaRE.InstallLocation = $latestJavaRe + "jre"
    if (!$latestJavaRe) {
        throw ($errorPref + "Java RE not found or unable to install")
    }
}

$latestJavaRe = $latestJavaRe + "jre"
Write-Output "Java JRE Installation is: $latestJavaRe"
$nodeProperties.javaHome = $latestJavaRe
#- install Java Certificates
if (!$auto) {
Write-Output $nodeProperties.downloadFolder $forceJavaCertsReplace
    . $scriptDir\Install.Java.Certificates.ps1 -javaHome "$($nodeProperties.javaHome)" -certificatesDir "$($nodeProperties.downloadFolder)\Certificates" -certExtensions cer -forceJavaCertsReplace:$forceJavaCertsReplace
}

#- ensure that winsw.exe present
if (!(Test-Path "$($nodeProperties.downloadFolder)\winsw-$($nodeProperties.winswVersion)-bin.exe")) {
    if ($auto) {throw ($errorPref + "File not found: '$($nodeProperties.downloadFolder)\winsw-$($nodeProperties.winswVersion)-bin.exe'")}

    . $scriptDir\Get.Binaries.ps1 -winsw -downloadFolder "$($nodeProperties.downloadFolder)"
} 

#- update properties file
    if (!(Write-NodeProperties $nodeProperties $nodePropertiesFilePath)) {
        throw ($errorPref + "Failed to update node properties file: $nodePropertiesFilePath")
    }

#- create node on Jenkins server
. $scriptDir\Create.Node.On.Jenkins.ps1 -nodePropertiesFilePath $nodePropertiesFilePath -forceNodeRecreate:$forceNodeRecreate

#- install Jenkins slave as service
if (Get-Service jenkinsslave -ErrorAction SilentlyContinue) {
	if ($forceSlaveReinstall) {
		. $scriptDir\Install.Jenkins.Slave.As.Service.ps1 -nodePropertiesFilePath $nodePropertiesFilePath
	} else {
		write-host "Restarting service: 'jenkinsslave'"
		Get-Service jenkinsslave | Restart-Service
	}
} else {
	. $scriptDir\Install.Jenkins.Slave.As.Service.ps1 -nodePropertiesFilePath $nodePropertiesFilePath
}
if($UninstallOracleJava)
{
	Write-Host "Uninstalling Oracle Java"
	. $scriptDir\Uninstall.Oracle.Java.ps1
}