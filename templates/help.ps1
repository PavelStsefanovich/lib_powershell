<#
.SYNOPSIS
    Installs IWS hotfix from supplied .zip file.
.DESCRIPTION
    This script is intended to be used with the hotfix package that it is shipped with.

    This script uses Registry to determine IWS installation location and database connection string, when running on Application server (or App + DB combo box). If it runs on machine where only database is installed, DB user, password (and instance, if not default: ".") must be supplied as input parameters.

    The script uses SQLCMD command line utility to execute SQL queries. This utility comes by default with MSSQL server, but might not be installed on Application-only server. In this case user must install SQLCMD manually before running the script, or run script twice: first on Application server (with -Server Application parameter), then on Database server (with -Server Database -DbUser <user> -DbPassword <"password"> parameters).
.PARAMETER    Server
    Alias: 'Target'
 Specifies target server (Application, Database) to apply patch to.
 Accepted values: 'Application','Database','All'
.PARAMETER    StopAppForDatabaseUpgrade
    Alias: 'StopApp'
 Indicates that Application server should be stopped for for duration of both Application and Database upgrade. By default, Application server will only stop for it's own upgrade and then start again before Database upgrade.
 This will only work if running on Application Server. If you upgrade Database server individually, please stop Application server manually.
.PARAMETER    DbUser
    Specifies Database connection user. If not specified, attempts to read username from IWS OleDbConnectionString in Registry (this only works if running from Application server, because registry entriy on Database server lacks OleDbConnectionString. This parameter is mandatory, if running locally from Database server).
.PARAMETER    DbPassword
    Specifies Database connection password (in quotes). If not specified, attempts to read username from IWS OleDbConnectionString in Registry (this only works if running from Application server, because registry entriy on Database server lacks OleDbConnectionString. This parameter is mandatory, if running locally from Database server).
.PARAMETER    DbInstance
    Specifies Database server(\instance). If not specified, attempts to read username from IWS OleDbConnectionString in Registry (this only works if running from Application server). If not found, tries to use <localhost\defaultInstance> (".")
.PARAMETER    Silent
    Indicates that all the prompts should be supressed, allowing script to run without user interaction.
.PARAMETER    Rollback
    Switches script execution to rollback mode.
.EXAMPLE
    .\Install.ps1

    Applies patch to both Application server and Database server with default parameters. (Runs on Application Server machine or combo-box (App + DB on single machine)).
 SQL command line utility (SQLCMD) and it's prerequisite (MSODBCSQL) must be installed on Application server. Database instance, user and password will be read from IWS installation entry in Registry.
.EXAMPLE
    .\Install.ps1 -Server Application

    Applies patch to Application server with default parameters. (Runs on Application Server machine or combo-box (App + DB on single machine)).
.EXAMPLE
    .\Install.ps1 -Server Database -DbUser "athoc\user" -DbPassword "pass123" -DbInstance "."

    Advanced. Refer to eWiki page for more info.
    Applies patch to local Database server to default instance. (Runs on Database Server machine). Append "." with instance name if not default like this: -DbInstance ".\YorInstance"
.EXAMPLE
    .\Install.ps1 -Rollback

    Executes Rollback for both Application server and Database server with default parameters. (Runs on Application Server machine or combo-box (App + DB on single machine)).
 SQL command line utility (SQLCMD) and it's prerequisite (MSODBCSQL) must be installed on Application server. Database instance, user and password will be read from IWS installation entry in Registry.
.EXAMPLE
    .\Install.ps1 -Server Application -Rollback

    Executes Rollback for Application server with default parameters. (Runs on Application Server machine or combo-box (App + DB on single machine)).
.EXAMPLE
    .\Install.ps1 -Server Database -DbUser "athoc\user" -DbPassword "pass123" -DbInstance "." -Rollback

    Advanced. Refer to eWiki page for more info.
    Executes Rollback for local Database server for default instance. (Runs on Database Server machine). Append "." with instance name if not default, like this: -DbInstance ".\YorInstance"
.LINK
    For more information, please follow the link:
 https://ewiki.athoc.com/display/ES/Install.ps1
#>


[cmdletbinding(HelpUri = "https://localhost")]
Param (
    [parameter()]
    [ValidateSet("Application", "Database", "All")]
    [Alias('Target')]
    [string]$Server,

    [parameter()]
    [Alias('StopApp')]
    [switch]$StopAppForDatabaseUpgrade,

    [parameter()]
    [string]$DbUser,

    [parameter()]
    [string]$DbPassword,

    [parameter()]
    [Alias('DbServer')]
    [string]$DbInstance,

    [parameter()]
    [switch]$Rollback,

    [parameter()]
    [switch]$Silent
)

<# (notes)

LOCATION IN SCRIPT OR FUNCTION:

For scripts:    in the verty beginning, followed by 2 blank lines

For functions:
• At the beginning of the function body, after the open brace.
• At the end of the function body.
• Before the function keyword. In this case, if the comment is to be processed as a
doc comment, there can’t be more than one blank line between the last line of
the comment and the function keyword.



AVAILABLE TAGS:

SYNOPSIS                A brief description of the function or script. This tag can be used only once in each help topic.
DESCRIPTION             A detailed description of the function or script.
PARAMETER               The description of a parameter.
EXAMPLE                 An example showing how to use a command.
INPUTS                  The type of object that can be piped into a command.
OUTPUTS                 The types of objects that the command returns.
NOTES                   Additional information about the function or script.
LINK                    The name of a related topic.
COMPONENT               The technology or feature that the command is associated with.
ROLE                    The user role for this command.
FUNCTIONALITY           The intended use of the function.
FORWARDHELPTARGETNAME   Redirects to the help topic for the specified command.
FORWARDHELPCATEGORY     Specifies the help category of the item in the .FORWARDHELPTARGETNAME tag.
REMOTEHELPRUNSPACE      Specifies the name of a variable containing the PSSession to use when looking up help for this function. This keyword is used by the Export-PSSession cmdlet to find the Help topics for the exported commands. (See section 12.4.2.)
EXTERNALHELP            Specifies the path to an external help file for the command.

#>
