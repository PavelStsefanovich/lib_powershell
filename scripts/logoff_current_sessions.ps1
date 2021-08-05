<#
DESCRIPTION
    Retrieves all user sessions from local or remote server/s and loggs off all active and disconnected sessions
PARAMETER computer
    Name of computer/s to run session query against.
.NOTES
    Name: Get-ComputerSessions
    Author: Dimitry Goldshteyn
    DateCreated: 6/3/15
#>

Function Get-ComputerSessions {

[cmdletbinding(
    DefaultParameterSetName = 'session',
    ConfirmImpact = 'low'
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ValueFromPipeline = $True)]
            [string[]]$computer
            )
Begin {
    $ListofSessions = @()
    }
Process {
    ForEach($c in $computer) {
        # Parse 'query session' and store in $sessions:
        $sessions = query session /server:$c
            1..($sessions.count -1) | % {
                $temp = "" | Select Computer,SessionName, Username, Id, State, Type, Device
                $temp.Computer = $c
                $temp.SessionName = $sessions[$_].Substring(1,18).Trim()
                $temp.Username = $sessions[$_].Substring(19,20).Trim()
                $temp.Id = $sessions[$_].Substring(39,9).Trim()
                $temp.State = $sessions[$_].Substring(48,8).Trim()
                $temp.Type = $sessions[$_].Substring(56,12).Trim()
                $temp.Device = $sessions[$_].Substring(68).Trim()
                $ListofSessions += $temp
            }
        }
    }
End {
   return $ListofSessions 
    }
}

$sessions = Get-ComputerSessions $env:computername

$sessions

foreach ($session in $sessions){
	if ($session.State -eq "Active" -or "Disc")
	{logoff $session.Id /server:$env:computername}
	"All Sessions are Logged Off!"

}
