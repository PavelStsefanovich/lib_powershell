[CmdletBinding()]
Param (
    [string]$RootDirectory = $PWD.path,
    [string[]]$Patterns,
    [switch]$Recurse,
    [string[]]$FilesList,
    [switch]$help
)

function Sign-File ($filePath) {
    if ($filepath.length -gt 0) {
        Write-Host "`n`nSigning: $filePath"

        if (gcm signtool -ErrorAction SilentlyContinue) {
            
            $signProcess = Start-Process signtool -ArgumentList "sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 /a `"$filePath`"" -NoNewWindow -Wait -PassThru
            return $signProcess.ExitCode
        }
        else {
            try {
                write-host $cert
                Set-AuthenticodeSignature "$filePath" $cert -HashAlgorithm sha256 -TimestampServer "http://timestamp.digicert.com" -Force -ErrorAction Stop | Out-Null
                return 0
            }
            catch {
                Write-Error $_
                return 1
            }
        }
    }
}

function Resolve-Filepath ($filepath, $RootDirectory) {
    if ($filepath -match '^([c-zC-Z]\:(\\|\/))|(\~(\\|\/))') {
        return (Resolve-Path $filepath -ErrorAction SilentlyContinue).Path
    } else {
        return (Resolve-Path (Join-Path $RootDirectory $filepath) -ErrorAction SilentlyContinue).Path
    }
}

### Execution ###

$ErrorActionPreference = 'Stop'

$files_to_sign = @()
$failed_files = @()

if ($help) {
    Write-Host ("_"*60)
    Write-Host "CodeSign.ps1 usage:`n"
    Write-Host "<RootDirectory>`t: root folder to look for files to sign; defaults to current directory"
    Write-Host "<Patterns>`t: file masks including asterics (wildcards)"
    Write-Host "<Recurse>`t: search in RootDirectory recursively"
    Write-Host "<FilesList>`t: comma-separated list of files to sign (fullpaths or paths relative to RootDirectory)"
    Write-Host ("_" * 60)
    exit
}

Write-Verbose "RootDirectory:`t$RootDirectory"
Write-Verbose "Patterns:"
$Patterns | % { Write-Verbose "  '$_'" }
Write-Verbose "Recurse:`t$Recurse"
Write-Verbose "FilesList:"
$FilesList | % { Write-Verbose "  '$_'" }

foreach ($pattern in $Patterns) {
    (ls $RootDirectory -Recurse:$Recurse -File -Filter $pattern).FullName | %{$files_to_sign += $_ }
}

foreach ($file in $FilesList) {
    $files_to_sign += Resolve-Filepath $file $RootDirectory
}

if (!$files_to_sign -or $files_to_sign.count -eq 0) {
    write-host ''
    Write-Warning "No files found matching provided criteria; nothing to sign."
}

$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert
if (!$cert) {
    throw "!!ERROR: No signing certificate found in store: 'CurrentUser\My'"
}

foreach ($filepath in $files_to_sign) {
    if ((Sign-File $filepath) -gt 0) {
        $failed_files += $filepath
    }
}

if ($failed_files.count -gt 0) {
    Write-Host "Signing failed for the following filepaths:"
    $failed_files | %{Write-Host "  $_"}
    exit 1
}