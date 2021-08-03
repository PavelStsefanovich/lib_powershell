[CmdletBinding()]

param(

    [Parameter(
        Mandatory = $true,
        Position = 0,
        ParameterSetName = "set1",
        ValueFromPipeline = $false,
        ValueFromPipelineByPropertyName = $true,
        ValueFromRemainingArguments = $false,
        HelpMessage = "some help this is")]

    [alias("CN")]

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



# Dynamic Parameters (conditionally created based on value of another parameter)
# Example: <product> is parameter at position 1; <age> will be only required if <product>='beer'
# https://powershellmagazine.com/2014/05/29/dynamic-parameters-in-powershell/

DynamicParam {
    if ($product -eq "Beer") {
        #create a new ParameterAttribute Object
        $ageAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ageAttribute.Position = 2
        $ageAttribute.Mandatory = $true
        $ageAttribute.HelpMessage = "This product is only available for customers 21 years of age and older. Please enter your age:"

        #create an attributecollection object for the attribute we just created.
        $attributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]

        #add our custom attribute
        $attributeCollection.Add($ageAttribute)

        #add our paramater specifying the attribute collection
        $ageParam = New-Object System.Management.Automation.RuntimeDefinedParameter('age', [Int16], $attributeCollection)

        #expose the name of our parameter
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $paramDictionary.Add('age', $ageParam)
        return $paramDictionary
    }
}



# List Common Parameters
begin {
    [System.Management.Automation.PSCmdlet]::CommonParameters
    [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
}

process {

}

end {

}