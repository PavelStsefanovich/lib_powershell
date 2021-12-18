# Dynamic Parameters (conditionally created based on value of another parameter)
# Example: <product> is parameter at position 1; <age> will be only required if <product>='beer'
# https://powershellmagazine.com/2014/05/29/dynamic-parameters-in-powershell/

Function Get-Order {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true,
            Position=1,
            HelpMessage="How many cups would you like to purchase?"
        )]
        [int]$cups,
        [Parameter(
            Mandatory=$false,
            Position=2,
            HelpMessage="What would you like to purchase?"
        )]
        [ValidateSet("Lemonade","Water","Tea","Coffee","Hard Lemonade")]
        [string]$product="Lemonade"
    )

    DynamicParam {
        if ($product -eq "Hard Lemonade") {
            #create a new ParameterAttribute Object
            $ageAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ageAttribute.Position = 3
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

    Begin {
        if ($PSBoundParameters.age -and $PSBoundParameters.age -lt 21) {
            Write-Error "You are not old enough for Hard Lemonade. How about a nice glass of regular Lemonade instead?" -ErrorAction Stop
        }
    }

    Process {
        $order = @()
        for ($cup = 1; $cup -le $cups; $cup++) {
            $order += "$($cup): A cup of $($product)"
        }
        $order
    }
}
