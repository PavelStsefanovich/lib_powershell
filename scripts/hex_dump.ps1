[CmdletBinding()]
param(
    [string]$path_to_file,
    [int]$table_width = 20,
    [int]$number_of_bytes = -1  # defaults to all
)

$ErrorActionPreference = 'Stop'
$OFS=""

Get-Content -Encoding byte $path_to_file -ReadCount $table_width -TotalCount $number_of_bytes | % {
    $record = $_
    if (($record -eq 0).count -ne $table_width)
    {
        $hex = $record | %{
        " " + ("{0:x}" -f $_).PadLeft(2,"0")}
        $char = $record | %{
        if ([char]::IsLetterOrDigit($_))
        { [char] $_ } else { "." }}
        "$hex $char"
    }
}
