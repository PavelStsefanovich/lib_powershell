function enlist ([switch]$r, [string]$a, [string]$d, [string]$s){
    $of = 'C:\some\path\file.txt'
    if ($r) {   # get random line
        $content = cat $of
        $line = ""
        while ($line.Length -lt 1) {
            $ln_num = Get-Random $content.Length
            $line = $content[$ln_num] | ConvertTo-SecureString | ss-to-plain
        }
        $line
    }
    if ($a) {   # add line
        $a | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | out-file $of -Encoding ascii -Append
    }
    if ($d) {   # delete line
        $content = cat $of
        $content | % {
            if (($_ | ConvertTo-SecureString | ss-to-plain)  -ne $d.trim()) { $new_content += "$_`n" }
        }
        $new_content.trimend() | Set-Content $of -Encoding ascii -force
    }
    if ($s) {   # search lines containing $s
        $content = cat $of
        $content | % {
            $u = $_ | ConvertTo-SecureString | ss-to-plain
            if ($u -like "*$s*") { $u }
        }   
    }
}