# Get the ACL for an existing folder
$existingAcl = Get-Acl -Path 'C:\DemoFolder'

# Set the permissions that you want to apply to the folder
$permissions = $env:username, 'Read,Modify', 'ContainerInherit,ObjectInherit', 'None', 'Allow'

# Create a new FileSystemAccessRule object
$rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permissions

# Modify the existing ACL to include the new rule
$existingAcl.SetAccessRule($rule)

# Apply the modified access rule to the folder
$existingAcl | Set-Acl -Path 'C:\DemoFolder'



# Example1:
$existingAcl = Get-Acl -Path $target_dir
$permissions = $env:username, 'Read,Modify', 'ContainerInherit,ObjectInherit', 'None', 'Allow'
$rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permissions
$existingAcl.SetAccessRule($rule)
$existingAcl | Set-Acl -Path $target_dir


# Example2:
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl = Get-ACL "C:\Program Files (x86)\AtHocENS\CommonSiteData"
$acl.AddAccessRule($accessRule)
Set-ACL -Path "C:\Program Files (x86)\AtHocENS\CommonSiteData" -ACLObject $acl



<# Filesystem Rights

AppendData                      append data to the end of a file.

ChangePermissions               change the security and audit rules associated with a file or folder.

CreateDirectories               create a folder This right requires the Synchronize value.

CreateFiles                     create a file. This right requires the Synchronize value.

Delete                          delete a folder or file.

DeleteSubdirectoriesAndFiles    delete a folder and any files contained within that folder.

ExecuteFile                     run an application file.

FullControl                     exert full control over a folder or file, and to modify access control and audit rules. This value represents the right to do anything with a file and is the combination of all rights in this enumeration.

ListDirectory                   read the contents of a directory.

Modify                          read, write, list folder contents, delete folders and files, and run application files. This right includes the ReadAndExecute right, the Write right, and the Delete right.

Read                            open and copy folders or files as read-only. This right includes the ReadData right, ReadExtendedAttributes right, ReadAttributes right, and ReadPermissions right.

ReadAndExecute                  open and copy folders or files as read-only, and to run application files. This right includes the Read right and the ExecuteFile right.

ReadAttributes                  open and copy file system attributes from a folder or file. For example, this value view the file creation or modified date. This does not include the right to read data, extended file system attributes, or access and audit rules.

ReadData                        open and copy a file or folder. This does not include the right to read file system attributes, extended file system attributes, or access and audit rules.

ReadExtendedAttributes          open and copy extended file system attributes from a folder or file. For example, this value view author and content information. This does not include the right to read data, file system attributes, or access and audit rules.

ReadPermissions                 open and copy access and audit rules from a folder or file. This does not include the right to read data, file system attributes, and extended file system attributes.

Synchronize                     Specifies whether the application can wait for a file handle to synchronize with the completion of an I/O operation. This value is automatically set when allowing access and automatically excluded when denying access.

TakeOwnership                   change the owner of a folder or file. Note that owners of a resource have full access to that resource.

Traverse                        list the contents of a folder and to run applications contained within that folder.

Write                           create folders and files, and to add or remove data from files. This right includes the WriteData right, AppendData right, WriteExtendedAttributes right, and WriteAttributes right.

WriteAttributes                 open and write file system attributes to a folder or file. This does not include the ability to write data, extended attributes, or access and audit rules.

WriteData                       open and write to a file or folder. This does not include the right to open and write file system attributes, extended file system attributes, or access and audit rules.

WriteExtendedAttributes         open and write extended file system attributes to a folder or file. This does not include the ability to write data, attributes, or access and audit rules.
#>