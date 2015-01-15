function Sync-CFNStack {
	param (
		[parameter(Mandatory=$true)]
		[string]
		$StackName,

		[parameter(Mandatory=$true)]
		[string]
		$TemplateFilename,

		[parameter()]
		[Amazon.CloudFormation.Model.Parameter[]]
		$Parameters,

		[parameter()]
		[string[]]
		$Capabilities,

		[parameter()]
		[Amazon.CloudFormation.OnFailure]
		$OnFailure = [Amazon.CloudFormation.OnFailure]::ROLLBACK,

		[parameter()]
		[string]
		$StackPolicyFilename,

		[parameter()]
		[Amazon.CloudFormation.Model.Tag[]]
		$Tags
	)

	Write-Verbose "Checking to see if template file $($TemplateFilename) for stack $($StackName) exists"
	if (-not (Test-Path $TemplateFilename)) {
		throw "Unable to find template file $($TemplateFilename) for stack $($StackName)"
	}

	Write-Verbose "Loading template file $($TemplateFilename)"
	$TemplateBody = Read-TextFile $TemplateFilename

	Write-Verbose "Setting common stack parameters for $($StackName)"
	$CFNStackParameters = @{
		StackName = $StackName;
		Capabilities = $Capabilities;
		Parameters = $Parameters;
		TemplateBody = $TemplateBody
	}


	Write-Verbose "Checking to see if we need a policy file"
	if ($StackPolicyFilename) {
		Write-Verbose "Yep, we need a policy"
		if (Test-Path $StackPolicyFilename) {
			Write-Verbose "Reading policy file $($StackPolicyFilename)"
			$StackPolicyBody = Read-TextFile $StackPolicyFilename
			$CFNStackParameters["StackPolicyBody"] = $StackPolicyBody
		}
		else {
			throw "Unable to find policy file $($StackPolicyFilename) for $($StackName)"
		}
	}

	if (Test-CFNStack -StackName $StackName) {
		Write-Verbose "Stack $($StackName) already exists so checking to see what we need to do"
		try {
			Update-CFNStack @CFNStackParameters
		}
		catch {
			if ($_.Exception.Message -eq "No updates are to be performed.") {
				Write-Verbose "No updates to be made"
			}
			else {
			    throw $_
			}
		}
	}
	else {
		Write-Verbose "Stack $($StackName) does not already exists so setting some more parameters"
		# $CFNStackParameters["DisableRollback"] = $DisableRollback
		$CFNStackParameters["Tags"] = $Tags
		$CFNStackParameters["OnFailure"] = $OnFailure

		Write-Verbose "Creating stack $($StackName)"
		$Response = New-CFNStack @CFNStackParameters
	}

	Write-Verbose "Exiting Sync-DRCFNStack for $($StackName)"
}