get-service *sqlwrite* | select @{name = 'ProcessName'; e = { $_.name } } | Get-Process
