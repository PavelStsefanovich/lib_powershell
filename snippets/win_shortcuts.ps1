function Get-Shortcut {
    param(
        $path = $null
    )

    $obj = New-Object -ComObject WScript.Shell

    if ($path -eq $null) {
        $pathUser = [System.Environment]::GetFolderPath('StartMenu')
        $pathCommon = $obj.SpecialFolders.Item('AllUsersStartMenu')
        $path = dir $pathUser, $pathCommon -Filter *.lnk -Recurse 
    }
    if ($path -is [string]) {
        $path = dir $path -Filter *.lnk
    }
    $path | ForEach-Object { 
        if ($_ -is [string]) {
            $_ = dir $_ -Filter *.lnk
        }
        if ($_) {
            $link = $obj.CreateShortcut($_.FullName)

            $info = @{}
            $info.Hotkey = $link.Hotkey
            $info.TargetPath = $link.TargetPath
            $info.LinkPath = $link.FullName
            $info.Arguments = $link.Arguments
            $info.Target = try { Split-Path $info.TargetPath -Leaf } catch { 'n/a' }
            $info.Link = try { Split-Path $info.LinkPath -Leaf } catch { 'n/a' }
            $info.WindowStyle = $link.WindowStyle
            $info.IconLocation = $link.IconLocation

            New-Object PSObject -Property $info
        }
    }
}

function Set-Shortcut {
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        $LinkPath,
        $Hotkey,
        $IconLocation,
        $Arguments,
        $TargetPath
    )
    begin {
        $shell = New-Object -ComObject WScript.Shell
    }

    process {
        $link = $shell.CreateShortcut($LinkPath)

        $PSCmdlet.MyInvocation.BoundParameters.GetEnumerator() |
        Where-Object { $_.key -ne 'LinkPath' } |
        ForEach-Object { $link.$($_.key) = $_.value }
        $link.Save()
    }
}


# Simple snippet:
$ps_link_path = 'C:\Users\Pavel\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk'
$link = $obj.CreateShortcut($ps_link_path)
$link.Arguments = "-nologo"
$link.Save()
