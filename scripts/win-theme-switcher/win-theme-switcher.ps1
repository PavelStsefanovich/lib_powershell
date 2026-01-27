
<#
.SYNOPSIS
Switches the Windows theme between light and dark based on local sunrise and sunset times.

.DESCRIPTION
This script automatically adjusts the system and application theme (light/dark) by fetching daily sunrise and sunset times for the user's current location. 
It can also install itself as a scheduled task to run automatically at user logon and every hour thereafter.

.PARAMETER install
A switch parameter that, when present, creates a scheduled task for the current user to run this script at logon and hourly. The task does not require elevated privileges.

.EXAMPLE
PS > .\win-theme-switcher.ps1
Executes the theme switch logic immediately based on the current time and sun phases.

.EXAMPLE
PS > .\win-theme-switcher.ps1 -install
Installs or updates the 'Win Theme Switcher' scheduled task to run for the current user.
#>
param (
    [Switch]$install
)


$ErrorActionPreference = 'Stop'


function Install-ScheduledTask {
    $taskName = "Win Theme Switcher"
    $scriptDir = $PSScriptRoot
    $scriptName = Split-Path $PSCommandPath -Leaf
    $xmlTemplatePath = Join-Path -Path $scriptDir -ChildPath ($scriptName.Replace('.ps1', '.xml'))
    $xmlPath = Join-Path -Path $scriptDir -ChildPath 'task-config.xml'
    $vbsPath = Join-Path -Path $scriptDir -ChildPath ($scriptName.Replace('.ps1', '.vbs'))

    (Get-Content $xmlTemplatePath -Raw).Replace('@@vbs-wrapper@@', $vbsPath) | Set-Content $xmlPath -Force -Encoding 'utf8'

    try {
        # If a task with the same name exists, remove it first so the imported XML replaces it cleanly
        if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
            Write-Host "Updating existing scheduled task: '$taskName'."
            try {
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
            }
            catch {
                Write-Warning "Failed to unregister existing scheduled task: $_"
            }
        }
        else {
            Write-Host "Creating new scheduled task: '$taskName'."
        }

        # Try using Register-ScheduledTask with the XML content
        $xml = Get-Content -Path $xmlPath -Raw -ErrorAction Stop
        Register-ScheduledTask -TaskName $taskName -Xml $xml -ErrorAction Stop
        Write-Host "Scheduled task '$taskName' installed successfully from XML."
        return
    }
    catch {
        Write-Error "Register-ScheduledTask with XML failed: $_"
        exit 1
    }
    finally {
        Remove-Item $xmlPath -Force
    }
}

function Invoke-ThemeRefresh {
    <#
        Broadcasts a theme change to all windows and refreshes taskbars on all monitors.
        The WM_SETTINGCHANGE + "ImmersiveColorSet" broadcast is based on settings-change-broadcaster.ps1.
        Restarting explorer.exe is a practical workaround to ensure secondary monitor taskbars update.
    #>
    try {
        if (-not ([System.Management.Automation.PSTypeName] 'ThemeRefresher').Type) {
            $code = @"
using System;
using System.Runtime.InteropServices;

public class ThemeRefresher {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd, uint Msg, IntPtr wParam, string lParam,
        uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
}
"@
            Add-Type -TypeDefinition $code -ErrorAction Stop
        }

        # 0xFFFF is HWND_BROADCAST, 0x001A is WM_SETTINGCHANGE
        $result = [IntPtr]::Zero
        [ThemeRefresher]::SendMessageTimeout([IntPtr]0xffff, 0x001a, [IntPtr]0, "ImmersiveColorSet", 0x0002, 1000, [ref]$result) | Out-Null
    }
    catch {
        Write-Warning "Failed to broadcast theme change: $_"
    }

    # Also send additional notifications that Explorer listens for and call SHChangeNotify.
    try {
        $code2 = @"
using System;
using System.Runtime.InteropServices;

public class ThemeRefresher2 {
    public const int HWND_BROADCAST = 0xffff;
    public const uint WM_SETTINGCHANGE = 0x001A;
    public const uint WM_THEMECHANGED = 0x031A;
    public const uint SMTO_ABORTIFHUNG = 0x0002;

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd, uint Msg, IntPtr wParam, string lParam,
        uint fuFlags, uint uTimeout, out IntPtr lpdwResult);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam,
        uint fuFlags, uint uTimeout, out IntPtr lpdwResult);

    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(long wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
}
"@

        Add-Type -TypeDefinition $code2 -ErrorAction SilentlyContinue

        $r = [IntPtr]::Zero
        [ThemeRefresher2]::SendMessageTimeout([IntPtr]0xffff, [ThemeRefresher2]::WM_SETTINGCHANGE, [IntPtr]0, "ImmersiveColorSet", [ThemeRefresher2]::SMTO_ABORTIFHUNG, 1000, [ref]$r) | Out-Null
        [ThemeRefresher2]::SendMessageTimeout([IntPtr]0xffff, [ThemeRefresher2]::WM_SETTINGCHANGE, [IntPtr]0, [IntPtr]::Zero, [ThemeRefresher2]::SMTO_ABORTIFHUNG, 1000, [ref]$r) | Out-Null
        [ThemeRefresher2]::SendMessageTimeout([IntPtr]0xffff, [ThemeRefresher2]::WM_THEMECHANGED, [IntPtr]0, [IntPtr]::Zero, [ThemeRefresher2]::SMTO_ABORTIFHUNG, 1000, [ref]$r) | Out-Null
        [ThemeRefresher2]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
    }
    catch {
        Write-Warning "Failed to send extended shell notifications: $_"
    }
}

function Set-Theme($theme) {
    $themeValue = if ($theme -eq 'Light') { 1 } else { 0 }
    $themePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    
    try {
        # Check current theme values and only update if they differ
        $current = @{}
        try {
            $props = Get-ItemProperty -Path $themePath -Name 'AppsUseLightTheme','SystemUsesLightTheme' -ErrorAction Stop
            $current.AppsUseLightTheme = [int]$props.AppsUseLightTheme
            $current.SystemUsesLightTheme = [int]$props.SystemUsesLightTheme
        }
        catch {
            # If values don't exist or cannot be read, treat as different to force an update
            $current.AppsUseLightTheme = $null
            $current.SystemUsesLightTheme = $null
        }

        $needUpdate = $false
        if ($current.AppsUseLightTheme -ne $themeValue) { $needUpdate = $true }
        if ($current.SystemUsesLightTheme -ne $themeValue) { $needUpdate = $true }

        if (-not $needUpdate) {
            Write-Verbose "Theme already set to $theme. No changes required."
            return
        }

        Write-Verbose "Setting theme to $theme."
        Set-ItemProperty -Path $themePath -Name "AppsUseLightTheme" -Value $themeValue -ErrorAction Stop
        Set-ItemProperty -Path $themePath -Name "SystemUsesLightTheme" -Value $themeValue -ErrorAction Stop
        Invoke-ThemeRefresh
        Write-Host "Theme successfully set to $theme."
    }
    catch {
        Write-Error "Failed to set theme. Error: $_"
    }
}

function Get-SunPhase {
    try {
        # Get location from IP
        $locationData = Invoke-RestMethod -Uri "https://ipinfo.io/json"
        $lat, $lng = $locationData.loc.Split(',')
        
        $url = "https://api.sunrisesunset.io/json?lat=$lat&lng=$lng"
        $response = Invoke-RestMethod -Uri $url -Method Get

        if ($response.status -eq "OK") {
            $sunrise = [datetime]$response.results.sunrise
            $sunset = [datetime]$response.results.sunset
            return [pscustomobject]@{
                Sunrise = $sunrise
                Sunset  = $sunset
            }
        } else {
            Write-Error "Sun phase API returned an error: $($response.status)"
            return $null
        }
    } catch {
        Write-Error "Failed to get sun phase data. Check your internet connection. Error: $_"
        return $null
    }
}


# --- Main Script Logic ---

if ($install) {
    Install-ScheduledTask
} else {
    $sunPhase = Get-SunPhase
    if ($sunPhase) {
        $now = Get-Date
        Write-Host "Current Time: $($now.ToString('T'))"
        Write-Host "Sunrise:      $($sunPhase.Sunrise.ToString('T'))"
        Write-Host "Sunset:       $($sunPhase.Sunset.ToString('T'))"

        if ($now -ge $sunPhase.Sunrise -and $now -lt $sunPhase.Sunset) {
            Set-Theme -Theme "Light"
        } else {
            Set-Theme -Theme "Dark"
        }
    }
}
