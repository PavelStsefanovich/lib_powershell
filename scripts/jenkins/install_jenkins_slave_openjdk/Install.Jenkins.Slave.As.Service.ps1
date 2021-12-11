param (
    [string]$nodePropertiesFilePath
)


function Read-NodeProperties ([string]$nodePropertiesFilePath) {
    $erPr = "!!MANDATORY PROPERTY MISSING: "
    try {
        $nodeProperties = ConvertFrom-StringData (cat $nodePropertiesFilePath -Raw) -ErrorAction stop
    } catch {
        Write-Host $_
        throw ($errorPref + "Can not read node properties file: '$nodePropertiesFilePath'")
    }

    if (!$nodeProperties.ContainsKey('jenkinsUrl')) {throw ($erPr + "<jenkinsUrl>")}
    if (!$nodeProperties.ContainsKey('user')) {throw ($erPr + "<user>")}
    if (!$nodeProperties.ContainsKey('apiToken')) {throw ($erPr + "<apiToken>")}
    if (!$nodeProperties.ContainsKey('jenkinsFolder')) {throw ($erPr + "<jenkinsFolder>")}
    if (!$nodeProperties.ContainsKey('javaHome')) {throw ($erPr + "<javaHome>")}
    if (!$nodeProperties.nodeName) {
        $nodeProperties.nodeName = ($env:COMPUTERNAME).ToLower()
    } else {
        $nodeProperties.nodeName = $nodeProperties.nodeName.ToLower()
    }
    if (!$nodeProperties.winswVersion) {$nodeProperties.winswVersion = "1"}
		if (!$nodeProperties.serviceDomain -or ($nodeProperties.serviceDomain -eq 'local')) {$nodeProperties.serviceDomain = $env:COMPUTERNAME}
		if (!$nodeProperties.serviceUser) {$nodeProperties.serviceUser = 'default'}
		if (!$nodeProperties.servicePassw) {$nodeProperties.servicePassw = 'default'}
		if (($nodeProperties.servicePassw -eq 'default') -and ($nodeProperties.serviceUser -ne 'default')) {throw ("!!ERROR: <servicePassw> not provided, though <serviceUser> is specified")}
    if (!$nodeProperties.downloadFolder) {$nodeProperties.downloadFolder = $PSScriptRoot}

    return $nodeProperties
}

function CreateGetNodeSecretGroovyScript($nodeName) {
	$groovyScript = @"
import hudson.model.Node.Mode
import hudson.slaves.*
import jenkins.model.Jenkins
for (aSlave in hudson.model.Hudson.instance.slaves) {
  if (aSlave.name == "$nodeName") {
    secret = aSlave.getComputer().getJnlpMac()
  }
}
return secret
"@
    return $groovyScript
}

function RunGroovyScriptOnJenkinsServer ($jenkinsUrl, $groovyScript, $wc) {
    $url = $jenkinsUrl + "/scriptText"
    $nvc = New-Object System.Collections.Specialized.NameValueCollection
	$nvc.Add("script", $groovyScript);
    try {
	    $byteRes = $wc.UploadValues($url,"POST", $nvc);
    } catch {
        throw $_
    }
	$res = [System.Text.Encoding]::UTF8.GetString($byteRes)
    return $res
}


#=== Begin ===

$Global:errorPref = "!!ERROR: "
$scriptDir = $PSScriptRoot
$templateMainXmlConfigFilename = "tmpl_jenkins-slave.xml"
$templateExeConfigFilename = "tmpl_jenkins-slave.exe.config"
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (!$IsAdmin) {throw ($errorPref + "This script must run as Administrator")}

#- read node properties file
if (!$nodePropertiesFilePath) {$nodePropertiesFilePath = "$scriptDir\node.properties"}
if (!(Test-Path $nodePropertiesFilePath)) {throw ($errorPref + "Node properties file does not exist: $nodePropertiesFilePath")}
$nodeProperties = Read-NodeProperties $nodePropertiesFilePath

#- print input parameters
Write-Host ("`n(script) " + $MyInvocation.MyCommand.Name + "`n(args)")
Write-Host ("  nodePropertiesFilePath:`t$nodePropertiesFilePath")
Write-Host "(props)"
Write-Host ("  jenkinsUrl:`t`t`t$($nodeProperties.jenkinsUrl)")
Write-Host ("  user:`t`t`t`t$($nodeProperties.user)")
Write-Host ("  apiToken:`t`t`t*****")
Write-Host ("  nodeName:`t`t`t$($nodeProperties.nodeName)")
Write-Host ("  jenkinsFolder:`t`t$($nodeProperties.jenkinsFolder)")
Write-Host ("  javaHome:`t`t`t$($nodeProperties.javaHome)")
Write-Host ("  winswVersion:`t`t`t$($nodeProperties.winswVersion)")
Write-Host ("  serviceDomain:`t`t$($nodeProperties.serviceDomain)")
Write-Host ("  serviceUser:`t`t`t$($nodeProperties.serviceUser)")
Write-Host ("  servicePassw:`t`t`t*****")
Write-Host ("  downloadFolder:`t`t$($nodeProperties.downloadFolder)")

#- construct WebClient object and set vars
$jenkinsUrl = $nodeProperties.jenkinsUrl.TrimEnd('/\')
$jenkinsFolder = $nodeProperties.jenkinsFolder.TrimEnd('/\')
$javaHome = $nodeProperties.javaHome.TrimEnd('/\')
$nodeName = $nodeProperties.nodeName
$downloadFolder = $nodeProperties.downloadFolder.TrimEnd('/\')
$winswVersion = $nodeProperties.winswVersion
$token = $nodeProperties.user + ":" + $nodeProperties.apiToken
$tokenBytes=[System.Text.Encoding]::UTF8.GetBytes($token)
$base64 = [System.Convert]::ToBase64String($tokenBytes)
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("Authorization", "Basic $base64")

#- check if configuration templates present
if (! (Test-Path "$scriptDir\Templates\$templateMainXmlConfigFilename")) {
    throw ($errorPref + "File not found: '$scriptDir\Templates\$templateMainXmlConfigFilename'")
}
if (! (Test-Path "$scriptDir\Templates\$templateExeConfigFilename")) {
    throw ($errorPref + "File not found: '$scriptDir\Templates\$templateExeConfigFilename'")
}

#- check if winsw.exe present
if (!(Test-Path "$downloadFolder\winsw-$winswVersion-bin.exe")) {
    throw ($errorPref + "File not found: '$downloadFolder\winsw-$winswVersion-bin.exe'")
} 

#- check if jenkins accessible
try {
    $ifJenkins = $wc.DownloadString($jenkinsUrl)
} catch {
    write ($errorPref + "Unable to access URL: $jenkinsUrl")
    throw $_
}

#- check if node exists on jenkins server
$url = $jenkinsUrl + "/computer/$nodeName/api/xml"
try {
    $node = $wc.DownloadString($url)
} catch {
    throw ($errorPref + "Specified node does not exists on Jenkins server: '$nodeName'")
}

#- get node's secret key
$groovyScript = CreateGetNodeSecretGroovyScript $nodeName
$runScriptResult = RunGroovyScriptOnJenkinsServer -jenkinsUrl "$jenkinsUrl" -groovyScript $groovyScript -wc $wc
if ($runScriptResult -notlike '*Exception*') {
    $nodeSecret = $runScriptResult.TrimEnd("`n`r").replace('Result: ','')
} else {
    write $runScriptResult
    throw ($errorPref + "Failed to obtain secret key for: '$nodeName'")
}

#- download 'slave.jar' from jenkins server if not present
if (!(Test-Path "$downloadFolder\slave.jar")) {
    Write-Host "File not found: 'slave.jar'. Attempting to download from Jenkins server ..."
    $url = $jenkinsUrl + "/jnlpJars/slave.jar"
    try {
        $wc.DownloadFile($url,"$downloadFolder\slave.jar")
        Write-Host "Successfully downloaded"
    } catch {
        throw ($errorPref + "Download FAILED: $url")
    }
}

#- remove Jenkins slave if exists
$jenkinsServiceName = (gsv *jenkinsslave* -ErrorAction SilentlyContinue).Name
if ($jenkinsServiceName) {
    Write-Host "Removing existing jenkins slave service ..."
    Stop-Service $jenkinsServiceName
    $exitCode = (Start-Process cmd -ArgumentList "/c sc delete $jenkinsServiceName" -NoNewWindow -PassThru -Wait).ExitCode
    if ($exitCode -ne 0) {
        throw ($errorPref + "Failed to delete existing Jenkins slave")
    }
}

#- clean Jenkins directory if exists
if (Test-Path $jenkinsFolder) {
    Write-Host "Jenkins directory already exists. Cleaning ..."
    ls $jenkinsFolder -File -ErrorAction SilentlyContinue | %{rm $_.FullName -ErrorAction Stop}
} else {
    mkdir $jenkinsFolder -Force -ErrorAction Stop | Out-Null
}

#- update configuration
Write-Host "Updating slave configuration files ..."
$mainConfig = cat "$scriptDir\Templates\$templateMainXmlConfigFilename" -Encoding UTF8
$mainConfig = $mainConfig.Replace('@@JAVA_HOME@@',$javaHome)
$mainConfig = $mainConfig.Replace('@@JENKINS_URL@@',$jenkinsUrl)
$mainConfig = $mainConfig.Replace('@@NODE_NAME@@',$nodeName)
$mainConfig = $mainConfig.Replace('@@NODE_SECRET@@',$nodeSecret)

if ($nodeProperties.serviceUser -eq 'default') {
	$serviceAccountConfig = ''
} else {
	$serviceConfigDomain = $nodeProperties.serviceDomain
	$serviceConfigUser = $nodeProperties.serviceUser
	$serviceConfigPassw = $nodeProperties.servicePassw
	$serviceAccountConfig = @"
<serviceaccount>
	<domain>$serviceConfigDomain</domain>
	<user>$serviceConfigUser</user>
	<password>$serviceConfigPassw</password>
	<allowservicelogon>true</allowservicelogon>
</serviceaccount>	
"@
}
$mainConfig = $mainConfig.Replace('@@SERVICE_ACCOUNT@@',$serviceAccountConfig)

$mainConfig | Out-File ("$jenkinsFolder\" + $templateMainXmlConfigFilename.Remove(0,5)) -Encoding utf8 -Force
cp "$scriptDir\Templates\$templateExeConfigFilename" -Destination ("$jenkinsFolder\" + $templateExeConfigFilename.Remove(0,5)) -Force
cp "$downloadFolder\winsw-$winswVersion-bin.exe" -Destination "$jenkinsFolder\jenkins-slave.exe" -Force
cp "$downloadFolder\slave.jar" -Destination $jenkinsFolder -Force

#- install jenkins slave as service
Write-Host "Installing Jenkins slave as sercvice ..."
$exitCode = (start "$jenkinsFolder\jenkins-slave.exe" -ArgumentList "install" -NoNewWindow -PassThru -Wait).ExitCode
if ($exitCode -ne 0) {
    throw ($errorPref + "Failed to install Jenkins slave as service")
}

gsv jenkinsslave -ErrorAction stop | Start-Service -ErrorAction Stop

Write-Host "Jenkins slave is installed successfully: '$nodeName'"
