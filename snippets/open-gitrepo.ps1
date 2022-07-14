function Open-GitRepo {

    param (
        [Parameter(Mandatory = $true)]
        [string]$url,


        [Parameter()]
        [string]$dir = $null
    )


    if ( !$dir ) { $dir = (Split-Path $url -Leaf).replace('.git', '') }
    $command = "git clone $url"
    if ( $dir ) { $command += " '$dir'" }
    iex $command
    & code "$dir"
}