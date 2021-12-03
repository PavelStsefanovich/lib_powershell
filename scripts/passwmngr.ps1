[cmdletbinding(HelpUri = "")]
param (
    [switch]$child_window
)


$VAULT_FILE_PATH = "$HOME\.psvlt"   # Change to backed up location




##########  FUNCTIONS  ##########################################

#--------------------------------------------------
function passw-to-key {
    param([string] $passphrase)
    return [Byte[]]($passphrase.PadRight(24).Substring(0, 24).ToCharArray())
}

#--------------------------------------------------
function  encrypt {
    param (
        $decrytped_text,
        $passphrase
    )

    $key = passw-to-key $passphrase

    $encrypted_text = $decrytped_text |
    ConvertTo-SecureString -AsPlainText -Force |
    ConvertFrom-SecureString -Key $key

    return $encrypted_text
}

#--------------------------------------------------
function encrypt-vault {
    param(
        $decrypted_vault,
        $passphrase
    )

    $encrypted_vault = @()

    $config_json = @{'config' = $decrypted_vault.config} | ConvertTo-Json -Compress
    $encrypted_config = encrypt $config_json $passphrase
    $encrypted_vault += ,$encrypted_config

    foreach ($secret in $decrypted_vault.secrets.keys) {
        $secret_json = @{$secret = $decrypted_vault.secrets.$secret} | ConvertTo-Json -Compress
        $encrypted_secret = encrypt $secret_json $passphrase
        $encrypted_vault += ,$encrypted_secret
    }

    return $encrypted_vault
}

#--------------------------------------------------
function  decrypt {
    param (
        $encrypted_text,
        $passphrase
    )

    $key = passw-to-key $passphrase

    try {
        $decrytped_text = $encrypted_text |
        ConvertTo-SecureString -Key $key |
        ss-to-plain
    }
    catch {
        return $null
    }

    return $decrytped_text
}

#--------------------------------------------------
function decrypt-vault {
    param(
        $encrypted_vault,
        $passphrase
    )

    $decrypted_vault = @{'secrets' = @{}}

    for ($i = 0; $i -lt $encrypted_vault.Count; $i++) {
        $decrypted_entry = decrypt $encrypted_vault[$i] $passphrase
        if (!$decrypted_entry) { return $null }

        try {
            $decrypted_hashtable = $decrypted_entry | json-to-hashtable

            if ($i -eq 0) {
                if (!$decrypted_hashtable.config.columns) { throw "Corrupted vault" }
                $decrypted_vault += $decrypted_hashtable
            }
            else { $decrypted_vault.secrets += $decrypted_hashtable }
        }
        catch {
            if ($i -eq 0) {
                error "Vault file appears to be corrupted"
                newline
                info "Press any key to exit"
                wait-any-key
                exit 1
            }

            warning "failed to decrypt a secret"
        }
    }

    return $decrypted_vault
}

#--------------------------------------------------
function save-vault {
    param(
        $vault,
        $master_password,
        $vault_file_path
    )

    encrypt-vault $vault $master_password | Set-Content $vault_file_path -Force
}

#--------------------------------------------------
function separator {
    param(
        [int]$width,
        [switch]$bold,
        [switch]$no_borders
    )

    $sep_char = "_"
    if ($bold) { $sep_char = "=" }

    if ($no_borders) { $separator = "  " + $sep_char * ($width - 4) }
    else { $separator = " |" + ($sep_char * ($width - 4)) + "|" }

    return $separator
}

#--------------------------------------------------
function trim-col-value {
    param(
        $col_value,
        $max_length
    )

    if ($col_value.length -ge $max_length) {
        if ($col_value.trim().length -ge $max_length) {
            $col_value = $col_value.Substring(0, $max_length - 4) + '... '
        }
    }

    return $col_value
}

#--------------------------------------------------
function display-vault {
    param(
        $vault,
        $vault_display_width
    )

    # header
    cls; newline
    Write-Host (separator $vault_display_width -no_borders)

    $header = " |"
    for ($i = 0; $i -lt $vault.config.columns.Count; $i++) {
        $header += " $($vault.config.columns[$i])".PadRight($vault.config.columnSizes[$i]) + "|"
    }

    Write-Host $header
    Write-Host (separator $vault_display_width -bold)

    # secrets list
    if ($vault.secrets.Count -gt 0) {
        foreach ($secret_name in ($vault.secrets.Keys | sort)) {
            $line = " |"
            $col_value = trim-col-value " $secret_name".PadRight($vault.config.columnSizes[0]) $vault.config.columnSizes[0]
            $line += "$col_value|"

            for ($i = 1; $i -lt $vault.config.columns.Count; $i++) {
                if ($vault.config.columns[$i] -eq 'SECRET') { $col_value = "********" }
                else { $col_value = $vault.secrets.$secret_name[$vault.config.columns[$i].ToLower()] }
                $col_value = trim-col-value " $col_value".PadRight($vault.config.columnSizes[$i]) $vault.config.columnSizes[$i]
                $line += "$col_value|"
            }

            Write-Host $line
            Write-Host (separator $vault_display_width)
        }
    }
    else {
        $line = " | <empty>".PadRight(148) + "|"
        Write-Host $line
        Write-Host (separator $vault_display_width)
    }
}

#--------------------------------------------------
function select-operation {
    $menu_color = 'DarkCyan'
    $width = 30
    newline
    Write-Host "  ( A )" -ForegroundColor $menu_color -NoNewline
    info "Add secret"
    Write-Host "  ( D )" -ForegroundColor $menu_color -NoNewline
    info "Delete secret"
    Write-Host "  ( S )" -ForegroundColor $menu_color -NoNewline
    info "Show secrets"
    Write-Host "  ( E )" -ForegroundColor $menu_color -NoNewline
    info "Exit (Ctrl+C)"
    Write-Host ("  " + ("." * $width)) -ForegroundColor DarkGray
    Write-Host "  ( C )" -ForegroundColor $menu_color -NoNewline
    info "Change master password"
    Write-Host "  ( P )" -ForegroundColor $menu_color -NoNewline
    info "Purge vault"


    wait-any-key
    $userin = $Host.UI.RawUI.ReadKey("AllowCtrlC,IncludeKeyUp,NoEcho").Character
    if ([int]$userin -in 3,69,101 ) { $userin = 'exit' }

    return ([string]$userin).tolower()
}

#--------------------------------------------------
function add-secret {
    param(
        $vault,
        $master_password,
        $vault_file_path
    )

    $secret = @{}
    $secret_name = ''
    $padding = ($vault.config.columns | % { $_.length } | measure -Maximum).Maximum + 2

    cls; newline
    info "NEW SECRET" -success; newline

    for ($i = 0; $i -lt $vault.config.columns.Count; $i++) {
        $col_name = $vault.config.columns[$i]

        $line = " $col_name".PadRight($padding) + ": "
        info $line -no_newline
        $col_value = $null
        $col_value = Read-Host

        if ($col_name -eq 'NAME') {
            if (!$col_value -or ($col_value.trim().Length -eq 0)) {
                error "Secret name cannot be empty"
                $colValNotGood = $true
            }

            if ($col_value.trim() -in $vault.secrets.Keys) {
                error "Secret with name `"$col_name`" already exists"
                $colValNotGood = $true
            }

            if ($colValNotGood) {
                info "press any key to return to main menu"
                wait-any-key
                return $vault
            }

            $secret_name = $col_value
        }
        else {
            $secret.Add($col_name.ToLower(), $col_value)
        }
    }

    $vault.secrets.Add($secret_name, $secret)
    save-vault $vault $master_password $vault_file_path
    return $vault
}

#--------------------------------------------------
function delete-secret {
    param(
        $vault,
        $master_password,
        $vault_file_path
    )

    newline
    warning "DELETE SECRET: Type full secret name (must match exactly)" -no_prefix
    newline
    info "  > " -no_newline
    $userin = Read-Host
    newline

    if ($userin.Trim() -in $vault.secrets.keys) {
        if (confirm "Delete secret `"$userin`"?") {
            $vault.secrets.Remove($userin.Trim())
        }
    }
    else {
        error "Cannot find secret with name `"$userin`""
        info "press any key to return to main menu"
        wait-any-key
    }

    save-vault $vault $master_password $vault_file_path
    return $vault
}

#--------------------------------------------------
function show-secrets {
    param($vault)

    $border_width = 100
    $padding = ($vault.config.columns | % { $_.length } | measure -Maximum).Maximum + 2
    $secret = ""

    newline
    info "SHOW SECRET: Type secret name (wildcard '*' supported)"
    newline
    info "  > " -no_newline
    $userin = Read-Host
    newline

    $filtered_secret_names = $vault.secrets.Keys | ? { $_ -like $userin.Trim() }

    if ($filtered_secret_names.Count -gt 0) {
        Write-Host (separator $border_width -bold -no_borders)

        foreach ($secret_name in $filtered_secret_names) {
            info ($vault.config.columns[0].PadRight($padding) + ": ") -no_newline
            info $secret_name

            for ($i = 1; $i -lt $vault.config.columns.Count; $i++) {
                $row_title = $vault.config.columns[$i]
                $row_value = $vault.secrets.$secret_name[$row_title.ToLower()]
                info ($row_title.PadRight($padding) + ": ") -no_newline
                info $row_value
                if ($row_title -eq 'SECRET') { $secret = $row_value }
            }

            Write-Host (separator $border_width -no_borders)
        }

        if ($filtered_secret_names.Count -eq 1) {
            newline
            info "Hit 'C' to copy secret to the clipboard"
            info "Press any other key to return to main menu"

            $userin = $Host.UI.RawUI.ReadKey("AllowCtrlC,IncludeKeyUp,NoEcho").Character
            if ([int]$userin -in 67, 99 ) {
                Set-Clipboard $secret
                newline
                info "secret copied to clipboard" -success
                sleep 2
            }
        }
        else {
            newline
            info "press any key to return to main menu"
            wait-any-key
        }
    }
    else {
        warning "Nothing found matching filter `"$userin`"" -no_prefix
        newline
        info "press any key to return to main menu"
        wait-any-key
    }
}

#--------------------------------------------------
function purge-vault {
    param(
        $vault_file_path,
        $script_name
    )

    cls; newline
    warning "PURGE VAULT"; newline
    info "To confirm purging of current vault, type `"DELETE`" (upper case) and hit Enter"
    info "Any other input will cancel this operation"; newline
    info "  > " -no_newline
    $userin = Read-Host
    newline

    if ($userin -ceq 'DELETE') {
        rm $vault_file_path -Force
        info "Vault has been deleted" -success
        info "To create new vault, run $script_name again"; newline
        info "press any key to exit"
        wait-any-key
        exit 0
    }

    warning "Confirmation failed. Vault has NOT been deleted"; newline
    info "press any key to return to main menu"
    wait-any-key
}

#--------------------------------------------------
function try-again {
    newline
    info "To try again, press any key"
    info "To exit, press Ctrl+C"
    wait-any-key
    $userin = $Host.UI.RawUI.ReadKey("AllowCtrlC,IncludeKeyUp,NoEcho").Character
    if ([int]$userin -eq 3) { return $false}
    return $true
}

#--------------------------------------------------
function create-master-password {
    param($title)

    while (!$passIsGood) {
        
        $passIsGood = $true
        cls; newline
        info $title -success; newline
        info ("Enter new master password".PadRight(32) + ": ") -no_newline
        $master_password = Read-Host -AsSecureString | ss-to-plain

        if ($master_password.Length -lt 8) {
            $passIsGood = $false
            newline
            warning "Master password must be at least 8 characters long" -no_prefix
            warning "It's complexity is on you" -no_prefix
            if (!(try-again)) { return $null }
            cls
            continue
        }

        info "Enter password again to confirm : " -no_newline
        $verification_password = Read-Host -AsSecureString | ss-to-plain

        if ($verification_password -ne $master_password) {
            $passIsGood = $false
            newline
            warning "Passwords do not match" -no_prefix
            if (!(try-again)) { return $null }
            cls
            continue
        }
    }

    return $master_password
}

#--------------------------------------------------
function change-master-password {
    param(
        $vault,
        $master_password,
        $vault_file_path
    )

    $new_master_password = create-master-password "CHANGE MASTER PASSWORD"
    if ($new_master_password) {
        save-vault $vault $new_master_password $vault_file_path
        newline
        info "master password changed successfully" -success
        sleep 2
        $master_password = $new_master_password
    }
    else {
        newline
        warning "Master password has not been changed"; newline
        info "press any key to return to main menu"
        wait-any-key
    }
    
    return $master_password
}



##########  MAIN  ###############################################

#--------------------------------------------------
# INIT
$ErrorActionPreference = 'Stop'
[console]::TreatControlCAsInput = $true
$host.PrivateData.ErrorBackgroundColor = $host.UI.RawUI.BackgroundColor
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$SCRIPT_NAME = $MyInvocation.MyCommand.Name
$SCRIPT_FULLPATH = $PSCommandPath


#--------------------------------------------------
# DEPENDENCIES
if (!$child_window) {
    try { Import-Module UtilityFunctions -MinimumVersion '0.3.0' -DisableNameChecking -Force -ErrorAction Stop }
    catch {
        write-host " "
        $warning  = "Dependency module not found: UtilityFunctions v.0.3.0`n"
        $warning += "You can install it with the following command (must run as admin):`n"
        $warning += " > Install-Module UtilityFunctions -RequiredVersion 0.3.0 -SkipPublisherCheck -Force"
        write-warning $warning
        Write-Host  "More info about the module can be found here:"
        Write-Host  " https://github.com/PavelStsefanovich/lib_powershell/tree/main/modules/UtilityFunctions`n"
        exit
    }
}


#--------------------------------------------------
# LAUNCH IN A NEW WINDOW
if (!$child_window) {
    $argline = "-noprofile -nologo"
    $argline += " -File `"$SCRIPT_FULLPATH`" -child_window"
    Start-Process "$PSHOME\powershell.exe" -ArgumentList $argline
    exit
}


#--------------------------------------------------
# SET CONSOLE WINDOW SIZE AND TITLE
$vault_display_width = 150
$pshost = get-host
$pswindow = $pshost.ui.rawui
$newsize = $pswindow.buffersize
$newsize.height = 3000
$newsize.width = $vault_display_width
$pswindow.buffersize = $newsize
$newsize = $pswindow.windowsize
$newsize.height = 50
$newsize.width = $vault_display_width
$pswindow.windowsize = $newsize
$pswindow.WindowTitle = " PASSWORD MANAGER    v1.0.0    https://github.com/PavelStsefanovich/lib_powershell" 


#--------------------------------------------------
# GET VAULT OBJECT
$auth_successful = $false
if ((gi $VAULT_FILE_PATH -ErrorAction SilentlyContinue).Length -gt 0) { $vault_exists = $true }

while ($vault_exists -and !$auth_successful) {
    cls; newline
    info "Enter master password to enter vault: " -no_newline
    $MASTER_PASSWORD = Read-Host  -AsSecureString | ss-to-plain
    $encrypted_vault = cat $VAULT_FILE_PATH
    if ($encrypted_vault -is [string]) { $encrypted_vault = ,@($encrypted_vault) }
    $VAULT = decrypt-vault $encrypted_vault $MASTER_PASSWORD

    if ($VAULT) { $auth_successful = $true }
    else {
        error "Wrong master password"
        info "To try again, press any key"
        info "To exit, press Ctrl+C"
        wait-any-key
        $userin = $Host.UI.RawUI.ReadKey("AllowCtrlC,IncludeKeyUp,NoEcho").Character
        if ([int]$userin -eq 3) { exit 0 }
    }
}

if (!$vault_exists) {
    # create vault path and file if not exists
    $vault_file_dir = Split-Path $VAULT_FILE_PATH
    if ($vault_file_dir) { mkdir $vault_file_dir -Force | Out-Null }
    ni $VAULT_FILE_PATH -ItemType File -Force | Out-Null

    # create master password
    $MASTER_PASSWORD = create-master-password 'NEW VAULT'
    if (!$MASTER_PASSWORD) { exit 0 }

    # create vault base layout
    $vault_config = @{
        "columns"     = @("NAME", "LOGIN", "SECRET", "COMMENT")
        "columnSizes" = @("37", "35", "17", "54")
    }

    $VAULT = @{
        'config'  = $vault_config
        'secrets' = @{}
    }
}


#--------------------------------------------------
# VAULT OPERATIONS
while (!$done) {
    display-vault $VAULT $vault_display_width
    $userin = select-operation

    switch ($userin) {
        "exit" { $done = $true; continue }
        "a" { $VAULT = add-secret $VAULT $MASTER_PASSWORD $VAULT_FILE_PATH; break }
        "d" { $VAULT = delete-secret $VAULT $MASTER_PASSWORD $VAULT_FILE_PATH; break }
        "s" { show-secrets $VAULT; break }
        "c" { $MASTER_PASSWORD = change-master-password $VAULT $MASTER_PASSWORD $VAULT_FILE_PATH; break }
        "p" { purge-vault $VAULT_FILE_PATH $SCRIPT_NAME; break }
        Default {}
    }
}


#--------------------------------------------------
# SAVE VAULT AND CLOSE WINDOW
save-vault $VAULT $MASTER_PASSWORD $VAULT_FILE_PATH
exit 0
