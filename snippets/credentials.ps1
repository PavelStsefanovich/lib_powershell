# Plain Text to SecureString
$s_string = convertto-securestring $plain_text_passw -asplaintext -force


# SecureString to Plain Text
# Module: UtilityFunctions
# Function: ss_to_plain()


# Console input to SecureString
$s_string = Read-Host -AsSecureString # -Prompt 'Enter password'


# Encrypt SecureString
$encrypted_s_string = ConvertFrom-SecureString $s_string # -Key $encryption_key


# Decrypt encrypted SecureString
$s_sting = ConvertTo-SecureString $encrypted_s_string # -Key $encryption_key


# PS Credential
$credential = New-Object System.Management.Automation.PSCredential ($username, $s_string)


# PS Credential (GUI)
$credential = Get-Credential # -UserName "$env:USERDOMAIN\$env:USERNAME" -Message ' '
$s_string = $credential.password
