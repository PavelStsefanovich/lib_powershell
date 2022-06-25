$token = $user + ":" + $apiToken
$tokenBytes = [System.Text.Encoding]::UTF8.GetBytes($token)
$base64 = [System.Convert]::ToBase64String($tokenBytes)
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
# [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

# New Webclient
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("Authorization", "Basic $base64")


# -------------------------------------------------

# Regular http GET
$wc.DownloadString($url)
$wc.DownloadStringAsync($url)

# Download to file on disk
$wc.DownloadFile($url, $destination_file_path)
$wc.DownloadFileAsync($url, $destination_file_path)

# Download to byte array in memory
$wc.DownloadData($url)
$wc.DownloadDataAsync($url)

# -------------------------------------------------

# Regular http POST
$wc.UploadString($url, $string)
$wc.UploadString($url, $method, $string)                # if uploading with method other than POST
$wc.UploadStringAsync($url, $string)
$wc.UploadStringAsync($url, $method, $string)           # if uploading with method other than POST

# Upload file from disk
$wc.UploadFile($url, $source_file_path)
$wc.UploadFile($url, $method, $source_file_path)        # if uploading with method other than POST
$wc.UploadFileAsync($url, $source_file_path)
$wc.UploadFileAsync($url, $method, $source_file_path)   # if uploading with method other than POST

# Upload data from byte array
$wc.UploadData($url, $byte_array)
$wc.UploadData($url, $method, $byte_array)              # if uploading with method other than POST
$wc.UploadDataAsync($url, $byte_array)
$wc.UploadDataAsync($url, $method, $byte_array)         # if uploading with method other than POST

# Upload key-value collection (hashtable)
$wc.UploadValues($url, @{})
$wc.UploadValues($url, $method, @{})                    # if uploading with method other than POST
$wc.UploadValuesAsync($url, @{})
$wc.UploadValuesAsync($url, $method, @{})               # if uploading with method other than POST
