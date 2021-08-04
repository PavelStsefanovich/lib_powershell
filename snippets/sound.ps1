$sound = New-Object System.Media.SoundPlayer
$sound.SoundLocation = 'C:\Windows\Media\notify.wav'
$sound.Play()



# Example:
function play_sound ([string]$type) {
    $sound = New-Object System.Media.SoundPlayer
    if ($type -eq 'error') { $soundname = "Windows Critical Stop.wav"}
    elseif ($type -eq 'warning') { $soundname = "Windows Notify.wav"}
    else { $soundname = "notify.wav"}
    $sound.SoundLocation = "C:\Windows\Media\$soundname"
    $sound.Play()
}
