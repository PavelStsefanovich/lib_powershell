[CmdletBinding(HelpUri = "")]
Param(
    [string]$Certfile,
    [string]$CertPassw,
    [string]$CaCertFile,
    [string]$WORKSPACE = $PSScriptRoot,
    [string]$Website = 'Default Web Site',
    [string]$nodesToUpdateFile = "$WORKSPACE\nodesToUpdate.txt",
    [string]$DomainName = 'athocdevo.com',
    [string[]]$excludeNodes
)

$resultsFile = "$WORKSPACE\ssl.wildcard.update.$DomainName." + (Get-Date -Format MMddyyyy).ToString() + ".csv"
$certFilename = Split-Path $Certfile -Leaf
if ($CaCertFile) {$CaCertFilename = Split-Path $CaCertFile -Leaf}
try {
    $nodesToUpdate = ConvertFrom-StringData (cat $nodesToUpdateFile -Raw) -ErrorAction stop
} catch {
    Write-Host "`n<nodesToUpdateFile> is not in Jenkins build generated format. Attempting to parse as simple list of nodes"
    try {
        $nodesToUpdate = @{}
        cat $nodesToUpdateFile -ErrorAction Stop | %{$nodesToUpdate.Add($_,'offline')}
    } catch {
        throw ("Parsing failed for <$nodesToUpdateFile>`n" + $_)
    }
}

foreach ($nodename in $nodesToUpdate.GetEnumerator().name) {
    $computerName = $nodename.TrimEnd('.') + "." + $DomainName.TrimStart('.')
    $nodesToUpdate.$nodename = @{'status' = $nodesToUpdate.$nodename; 'isUpdated' = $false}
    $nodesToUpdate.$nodename.isReachable = Test-Connection ($computerName) -Count 1 -Quiet

		if ($excludeNodes) {
			if ($excludeNodes.Contains($nodename)) {
					write-host "`nNode excluded: $nodename"
					$nodesToUpdate.$nodename.updateError = "Node explicitely excluded"
					continue
			}
		}
    write-host "`nWorking on: '$nodename' ..."
    if ($nodesToUpdate.$nodename.isReachable) {
        try {
            mkdir "\\$computerName\C$\BR" -Force -ErrorAction Stop | out-null
            cp $Certfile -dest "\\$computerName\C$\BR" -Force -ErrorAction Stop
            if ($CaCertFile) {cp $CaCertFile -dest "\\$computerName\C$\BR" -Force -ErrorAction Stop}
            Invoke-Command -ComputerName $computerName -FilePath "$WORKSPACE\update_iis_ssl_binding.ps1" -ArgumentList $certFilename,$CertPassw,$CaCertFilename,$DomainName,"c:\BR",$Website -ErrorAction stop
            $nodesToUpdate.$nodename.isUpdated = $true
        } catch {
            write-host "Certificate installation failed for '$nodename' with error:"
            write-error $_
            $nodesToUpdate.$nodename.updateError = $_
        }
    } else {
	    $nodesToUpdate.$nodename.updateError = "Node cannot be connected"
	}
}

Try {
    $results = @()

    foreach ($nodename in $nodesToUpdate.GetEnumerator().name) {
        $status = $nodesToUpdate.$nodename.status
        $isReachable = $nodesToUpdate.$nodename.isReachable.toString()
        $isUpdated = $nodesToUpdate.$nodename.isUpdated.toString()
        if ($nodesToUpdate.$nodename.isReachable -and !$nodesToUpdate.$nodename.isUpdated) {
            $updateError = $nodesToUpdate.$nodename.updateError.toString()
        } else {
            $updateError = ""
        }

        $line = [pscustomobject]@{
            Computername = $nodename
            Status = $status
            isReachable = $isReachable
            isUpdated = $isUpdated
            updateError = $updateError
        }

        $results += $line
    }

    $results | Export-Csv $resultsFile -NoTypeInformation

} Catch {
    Write-Warning "SSL certificate update ran successfully, but generation of results file failed. Please refer to the console output for each node status"
}
