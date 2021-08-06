# Init compressioin assembly
Add-Type -AssemblyName "system.io.compression.filesystem"

# Create zip from directory (simple)
[io.compression.zipfile]::CreateFromDirectory($source.fullname, $destination.zip)

# Create zip from directory (full)
$compression = "Optimal"    # 'Optimal', 'Fastest', 'NoCompression'
$include_base_dir = $true   # True, False
[io.compression.zipfile]::CreateFromDirectory($source_dir_path, $destination_zip_path, $compression, $include_base_dir)

# Unzip
[io.compression.zipfile]::ExtractToDirectory($source_zip_path, $destination_dir_path)



# Extract single file from arvhive
function abspath ($parent = $pwd.Path) {
    process {
        if ([System.IO.Path]::IsPathRooted($_)) { (Resolve-Path $_).Path }
        else { (Resolve-Path (Join-Path $parent $_)).Path }
    }
}
function extract_file ($source_zipfile_path, $file_to_extract, $destination_dir_path) {
    $source_zipfile_path = $source_zipfile_path | abspath
    $destination_dir_path = $destination_dir_path | abspath
    $destination_file_path = Join-Path $destination_dir_path $file_to_extract
    [Reflection.Assembly]::LoadWithPartialName( "System.IO.Compression.FileSystem" ) | Out-Null
    $zipstream = [System.IO.Compression.ZipFile]::OpenRead($source_zipfile_path)
    $filestream = New-Object IO.FileStream ($destination_file_path) , 'Append', 'Write', 'Read'

    foreach ($zipfile in $zipstream.Entries) {
        if ($zipfile.Name -eq $file_to_extract) {
            $file = $zipfile.Open()
            $file.CopyTo($filestream)
            $file.Close()
            break
        }
    }

    $filestream.Close()
}
