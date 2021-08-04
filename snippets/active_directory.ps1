# Get AD Computers
$DirSearcher = New-Object System.DirectoryServices.DirectorySearcher([adsi]'')
$DirSearcher.Filter = '(objectClass=Computer)'
$computers = $DirSearcher.FindAll().GetEnumerator() | ForEach-Object { $_.Properties.name } | sort



# Get AD Users
$DirSearcher = New-Object System.DirectoryServices.DirectorySearcher([adsi]'')
$DirSearcher.Filter = '(objectClass=User)'
$users = $DirSearcher.FindAll().GetEnumerator() | sort -Property name



# Search users in LDAP
$users = @()
$strFilter = "objectCategory=User"
# $strFilter = "(&(objectCategory=User)(Department=Finance))"

$objRoot = New-Object System.DirectoryServices.DirectoryEntry
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher

$objSearcher.SearchRoot = $objRoot
$objSearcher.PageSize = 1000
$objSearcher.Filter = $strFilter
$objSearcher.SearchScope = "Subtree"
$colProplist = "name"

foreach ($i in $colPropList) { $objSearcher.PropertiesToLoad.Add($i) }

$colResults = $objSearcher.FindAll()

foreach ($objResult in $colResults) {
    $objItem = $objResult.Properties;
    $users += $objItem.name
}

$users
