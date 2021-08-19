[CmdletBinding()]

param(

    [Parameter(
        Mandatory = $true,
        Position = 0,
        ParameterSetName = "set1",
        ValueFromPipeline = $false,
        ValueFromPipelineByPropertyName = $true,
        ValueFromRemainingArguments = $false,
        HelpMessage = "Hint for this argument")]

    [Alias("CN")]
    [AllowNull()]			    # Attributes that control how null or empty parameters are handled
    [AllowEmptyString()]
    [AllowEmptyCollection()]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [ValidateCount(min, max)]	# Attributes that validate string lengths or array element counts
    [ValidateLength(min, max)]
    [ValidatePattern(pattern)]	# Attributes that validate argument values against numeric ranges, regular expression patterns, or explicit sets of values
    [ValidateRange(min, max)]
    [ValidateSet('val1', 'val2', 'val3')]
    [ValidateScript( { ls })]	# Performs custom validationactions by specifying a scriptblock
    [int]                       # Restricts Parameter's Type
    $p1 = 0                     # Parameter Name and default Value
)

exit
