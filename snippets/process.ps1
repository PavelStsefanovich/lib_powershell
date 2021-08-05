function Run-Process {
    param (
        [string]$processName,
        [string]$processArguments,
        [string]$processWorkingDirectory = $PWD.path,
        [PSCredential]$Credential
    )

    [hashtable]$output = @{}

    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = "$processName"
    $ProcessInfo.WorkingDirectory = $processWorkingDirectory
    $ProcessInfo.CreateNoWindow = $true
    $ProcessInfo.RedirectStandardError = $true
    $ProcessInfo.RedirectStandardOutput = $true
    $ProcessInfo.UseShellExecute = $false
    $ProcessInfo.Arguments = $processArguments

    if ($Credential) {
        $ProcessInfo.Username = $Credential.GetNetworkCredential().username
        $ProcessInfo.Domain = $Credential.GetNetworkCredential().Domain
        $ProcessInfo.Password = $Credential.Password
        wtite-host "running as user '$($ProcessInfo.Username)'"
    }

    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $ProcessInfo
    $Process.Start() | Out-Null
    #$Process.WaitForExit() # use if no need to emit output during execution
    while (!$Process.StandardOutput.EndOfStream) {
        write-host $Process.StandardOutput.ReadLine()
    }
    $output.stdout = $Process.StandardOutput.ReadToEnd()
    $output.stderr = $Process.StandardError.ReadToEnd()
    $output.errcode = $Process.ExitCode

    return $output
}