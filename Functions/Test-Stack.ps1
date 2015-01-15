function Test-Stack {
	param(
		[parameter(Mandatory=$true)]
		[System.Collections.Hashtable]
		$Stack,

		[parameter(Mandatory=$true)]
		[string]
		$Path,

		[parameter(Mandatory=$true)]
		[System.Collections.Hashtable]
		$Config,

		[parameter(Mandatory=$true)]
		[System.Collections.Hashtable]
		$Parameters
	)

	Write-Verbose "Verifying stack $($Stack.name)"

	try {
		$StackTemplateFilename = Get-TemplateFilename $Stack $Path

		Write-Verbose "Checking that template file ($($StackTemplateFilename)) for stack $($Stack.name) exists"
		if (-not $(Test-Path $StackTemplateFilename)) {
			throw "Could not find stack $($Stack.name) ($($StackTemplateFilename))"
		}

		Write-Verbose "Checking that template file ($($StackTemplateFilename)) for stack $($Stack.name) is properly formatted"
		$TemplateBody = Read-TextFile $StackTemplateFilename
		Write-Verbose "Loaded file $($StackTemplateFilename), total of $($TemplateBody.Length) characters"

		Write-Verbose "Validating stack $($Stack.name) template file $($StackTemplateFilename)"
		$ValidationResponse = Test-CFNTemplate -TemplateBody $TemplateBody
		if (-not $ValidationResponse) {
			throw "Stack $($Stack.name) template file $($StackTemplateFilename) failed validation"
		}
		Write-Verbose "Stack $($Stack.name) template file $($StackTemplateFilename) passed validation"

		foreach ($Parameter in $ValidationResponse.Parameters) {
			if (-not $(Get-StackParameter -Parameter $Parameter -Stack $Stack -Config $Config -Path $Path -Parameters $Parameters -ValidateOnly)) {
				throw "Failed to find value for $($Parameter.ParameterKey)"
			}
		}

		Write-Host "Stack $($Stack.name) is valid"
	}
	catch {
		Write-Host "Stack $($Stack.name) failed validation"
		throw $_
	}
}