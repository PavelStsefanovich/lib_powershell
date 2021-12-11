function Draw-Progressbar {
    if ($script:progressBar -lt 0) {
        Write-Host "[.................................................]`r[" -NoNewline
        $script:progressBar = 0
    }

    if ($script:progressPercent -gt $script:progressBar) {

        $dots = [int][math]::Truncate(($script:progressPercent - $script:progressBar) / 2)
        if ($dots -gt 0) {
            $script:progressBar = $script:progressPercent
            if ($script:progressBar -lt 100) {Write-Host "o" -NoNewline}
            else {Write-Host "]`r                                                   `r" -NoNewline}
        }
    }
}

write-host "Running progress bar..."

$total = 100;
$script:progressBar = -1;

for ($i = 0; $i -le $total; $i++) {
    $progress = $i
    [int]$progressPercent = [int][math]::Truncate($progress / ($total /100))
    
    Draw-Progressbar
    sleep -Milliseconds 15
}
write-host "done!"
exit