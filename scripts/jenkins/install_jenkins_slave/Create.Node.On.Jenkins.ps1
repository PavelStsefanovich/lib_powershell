param (
    [string]$nodePropertiesFilePath,
    [switch]$forceNodeRecreate,
    [switch]$returnNodeSecret
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
    if (!$nodeProperties.nodeName) {
        $nodeProperties.nodeName = ($env:COMPUTERNAME).ToLower()
    } else {
        $nodeProperties.nodeName = $nodeProperties.nodeName.ToLower()
    }
    if (!$nodeProperties.labels) {$nodeProperties.labels = "auto-generated"}
    if (!$nodeProperties.numberOfExecutors) {$nodeProperties.numberOfExecutors = "1"}
    if (!$nodeProperties.usageMode) {$nodeProperties.usageMode = "EXCLUSIVE"}

    return $nodeProperties
}

function CreateAddNodeGroovySrcipt($nodeName, $labels, $jenkinsFolder, $numberOfExecutors, $usageMode){
    $remoteFolder = $jenkinsFolder.Replace("\", "\\")
	$groovyScript = @"
import hudson.model.Node.Mode
import hudson.slaves.*
import jenkins.model.Jenkins
DumbSlave dumb = new DumbSlave("$nodeName",
"",
"$remoteFolder",
"$numberOfExecutors",
Mode.EXCLUSIVE,
"$labels", // Labels
new JNLPLauncher(),
RetentionStrategy.INSTANCE)
Jenkins.instance.addNode(dumb)
"@
	return $groovyScript
}

function CreateRemoveNodeGroovyScript($nodeName) {
	$groovyScript = @"
import hudson.model.Node.Mode
import hudson.slaves.*
import jenkins.model.Jenkins
for (aSlave in hudson.model.Hudson.instance.slaves) {
  if (aSlave.name == "$nodeName") {
    hudson.model.Hudson.instance.removeNode(aSlave) 
  }
}
"@
    return $groovyScript    
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
	    $byteRes = $wc.UploadValues($url,"POST", $nvc)
    } catch {
        throw $_
    }
	$res = [System.Text.Encoding]::UTF8.GetString($byteRes)
    return $res
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

#- print input parameters
Write-Host ("`n(script) " + $MyInvocation.MyCommand.Name + "`n(args)")
Write-Host ("  nodePropertiesFilePath:`t$nodePropertiesFilePath")
Write-Host ("  forceNodeRecreate:`t`t$forceNodeRecreate")
Write-Host ("  returnNodeSecret:`t`t$returnNodeSecret")
Write-Host "(props)"
Write-Host ("  jenkinsUrl:`t`t`t$($nodeProperties.jenkinsUrl)")
Write-Host ("  user:`t`t`t`t$($nodeProperties.user)")
Write-Host ("  apiToken:`t`t`t*****")
Write-Host ("  nodeName:`t`t`t$($nodeProperties.nodeName)")
Write-Host ("  labels:`t`t`t$($nodeProperties.labels)")
Write-Host ("  numberOfExecutors:`t`t$($nodeProperties.numberOfExecutors)")
Write-Host ("  usageMode:`t`t`t$($nodeProperties.usageMode)")
Write-Host ("  jenkinsFolder:`t`t$($nodeProperties.jenkinsFolder)")

#- construct WebClient object
$jenkinsUrl = $nodeProperties.jenkinsUrl.TrimEnd('/\')
$nodeName = $nodeProperties.nodeName
$token = $nodeProperties.user + ":" + $nodeProperties.apiToken
$tokenBytes=[System.Text.Encoding]::UTF8.GetBytes($token)
$base64 = [System.Convert]::ToBase64String($tokenBytes)
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("Authorization", "Basic $base64")
$nodeExists = $true

#- check if jenkins accessible
try {
    $ifJenkins = $wc.DownloadString($jenkinsUrl)
} catch {
    write ($errorPref + "Unable to access URL: $jenkinsUrl")
    throw $_
}

#- check if node exists on jenkins server
try {
    $url = $jenkinsUrl + "/computer/$nodeName/api/xml"
    $node = $wc.DownloadString($url)
} catch {
    $nodeExists = $false
}

#- remove node from jenkins if exists if forced recreation
if ($forceNodeRecreate -and $nodeExists) {
    Write-Host "Removing existing node from Jenkins server: '$nodeName'"
    $groovyScript = CreateRemoveNodeGroovyScript $nodeName
    $runScriptResult = RunGroovyScriptOnJenkinsServer -jenkinsUrl $jenkinsUrl -groovyScript $groovyScript -wc $wc
	if ($runScriptResult -notlike '*Exception*') {
        Write-Host "Node removed successfully: '$nodeName'"
        $nodeExists = $false
    } else {
        write $runScriptResult
        throw ($errorPref + "Removing of node FAILED: '$nodeName'")
    }
}

#- create node on jenkins
if ($nodeExists) {
    Write-Host "Node already exists on Jenkins server: '$nodeName'"
} else {
    Write-Host "Creating node on Jenkins server: '$nodeName'"
    $groovyScript = CreateAddNodeGroovySrcipt "$nodeName" "$($nodeProperties.labels)" "$($nodeProperties.jenkinsFolder)" "$($nodeProperties.numberOfExecutors)" "$($nodeProperties.usageMode)"
    $runScriptResult = RunGroovyScriptOnJenkinsServer -jenkinsUrl $jenkinsUrl -groovyScript $groovyScript -wc $wc
	if ($runScriptResult -notlike '*Exception*') {
        Write-Host "Node created successfully: '$nodeName'"
    } else {
        write $runScriptResult
        throw ($errorPref + "Creating of node FAILED: '$nodeName'")
    }
}

#- get node's secret key
if ($returnNodeSecret) {
    $groovyScript = CreateGetNodeSecretGroovyScript $nodeName
    $runScriptResult = RunGroovyScriptOnJenkinsServer -jenkinsUrl "$jenkinsUrl" -groovyScript $groovyScript -wc $wc
    if ($runScriptResult -notlike '*Exception*') {
        $nodeSecret = $runScriptResult.TrimEnd("`n`r").replace('Result: ','')
    } else {
        write $runScriptResult
        throw ($errorPref + "Failed to obtain secret key for: '$nodeName'")
    }

    return "$nodeSecret"
}
