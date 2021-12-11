$Host.PrivateData.ProgressBackgroundColor='DarkGray'
$Host.PrivateData.ProgressForegroundColor='White'

for ($a = 1; $a -lt 100; $a += 10) {
    Write-Progress -id 1 -Activity "Long Loop Count" -PercentComplete $a -CurrentOperation "$a% complete" -Status "Counting..."
			for ($b = 1; $b -lt 100; $b += 10) {
				Write-Progress -id 2 -parentId 1 -Activity "Short Loop Count" -PercentComplete $b -CurrentOperation "$b% complete" -Status "Counting..."
			}
}

Write-Progress -Activity "Done" -Completed

sleep -s 2
exit
