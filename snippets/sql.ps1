$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server=172.16.10.38;Initial Catalog=ngdeliveryaccount;User Id=usr;Password=P@33w0rd;"
$SqlConnection.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "select AppObjectId from dbo.Access where AccessId = 6"
$SqlCmd.Connection = $SqlConnection
$result = $SqlCmd.ExecuteScalar()
$SqlConnection.Close()
Write-output "result: " $result



# Example:
function Invoke-SqlCommand() {
    [cmdletbinding(DefaultParameterSetName = "integrated")]Param (
        [Parameter(Mandatory = $true)][Alias("Serverinstance")][string]$Server,
        [Parameter(Mandatory = $true)][string]$Database,
        [Parameter(Mandatory = $true, ParameterSetName = "not_integrated")][string]$Username,
        [Parameter(Mandatory = $true, ParameterSetName = "not_integrated")][string]$Password,
        [Parameter(Mandatory = $false, ParameterSetName = "integrated")][switch]$UseWindowsAuthentication = $true,
        [Parameter(Mandatory = $true)][string]$Query,
        [Parameter(Mandatory = $false)][int]$CommandTimeout = 0
    )

    #build connection string
    $connstring = "Server=$Server; Database=$Database; "
    If ($PSCmdlet.ParameterSetName -eq "not_integrated") { $connstring += "User ID=$username; Password=$password;" }
    ElseIf ($PSCmdlet.ParameterSetName -eq "integrated") { $connstring += "Trusted_Connection=Yes; Integrated Security=SSPI;" }

    #connect to database
    $connection = New-Object System.Data.SqlClient.SqlConnection($connstring)
    $connection.Open()

    #build query object
    $command = $connection.CreateCommand()
    $command.CommandText = $Query
    $command.CommandTimeout = $CommandTimeout

    #run query
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataset) | out-null

    #return the first collection of results or an empty array
    If ($dataset.Tables[0] -ne $null) { $table = $dataset.Tables[0] }
    ElseIf ($table.Rows.Count -eq 0) { $table = New-Object System.Collections.ArrayList }

    $connection.Close()
    return $table
}

$server = "<server>.database.windows.net"
$db = "<database>"
$sql = "SELECT TOP 5 * FROM [Index]"
Invoke-SqlCommand -Server $server -Database $db -Username $user -Password $pass -Query $sql | Format-Table
