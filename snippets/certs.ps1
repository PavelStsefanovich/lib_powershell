# Install .pfx Certificate

$pfx_file_name = ""
$pfx_passw = ""
$pfx_secure_passw = ConvertTo-SecureString $pfx_passw -AsPlainText -Force

# (fix) (win update 3000850 issu: https://support.microsoft.com/en-ca/help/3000850/november-2014-update-rollup-for-windows-rt-8-1-windows-8-1-and-windows)
New-ItemProperty HKLM:/SOFTWARE/Microsoft/Cryptography/Protect/Providers/df9d8cd0-1501-11d1-8c7a-00c04fc297eb/ `
    -Name ProtectionPolicy `
    -Value 1 `
    -PropertyType 'DWord' `
    -ErrorAction SilentlyContinue | `
    Out-Null

Import-PfxCertificate -FilePath "$CertFilepath" `
    -CertStoreLocation Cert:/CurrentUser/My/ `
    -Password $pfx_secure_passw `
    -ErrorAction Stop | `
    Out-Null
