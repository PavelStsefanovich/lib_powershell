$ErrorActionPreference = 'Stop'
"`n(Jenkins): Getting list of users who committed for this build ..."

$token = 'bbot' + ":" + $env:bbotPassword
$tokenBytes = [System.Text.Encoding]::UTF8.GetBytes($token)
$base64 = [System.Convert]::ToBase64String($tokenBytes)
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$headers = @{'Authorization' = "Basic $base64" }
$crumb = Invoke-RestMethod -Method Get -Uri ($env:JENKINS_URL + 'crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)') -Headers $headers
$headers.Add($crumb.split(':')[0], $crumb.split(':')[1])

$buildinfo = irm -Uri "$env:BUILD_URL/api/json" -Method Get -Headers $headers
$users = ($buildinfo.culprits.fullname | % { $_ -match ".*\((?<username>.*)\)" | out-null; $matches.username }) | sort | Get-Unique
$users
