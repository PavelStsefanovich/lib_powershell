function Get-AvailableDrive ([switch]$only_letter) {
    $alphabet = [string[]][char[]]([int][char]'D'..[int][char]'Z')  # no need to iterate A:, B:, C:
    for ($i = 0; $i -lt $alphabet.Length; $i++) {
        if ($alphabet[$i] -notin (Get-PSDrive -PSProvider FileSystem).Name) {
            $available_drive = $alphabet[$i]
            if (!$only_letter) {
                $available_drive += ":"
            }
            break
        }
    }

    if ([string]::IsNullOrEmpty($available_drive)) {
        throw "No drive letters available."
    }

    return $available_drive
}

Get-AvailableDrive -only_letter
