function Test-StackStatusCompleted {
	param(
		[parameter(Mandatory=$true)]
		[string]
		$StackName
	)

	$CFNStack = Get-CFNStack -StackName $StackName
	if ($CFNStack -eq $null) {
		throw "Could not retrieve details for stack $($Stack.Name)"
	}

	if ($CFNStack.StackStatus -eq [Amazon.CloudFormation.StackStatus]::CREATE_COMPLETE) { return $true }
	elseif ($CFNStack.StackStatus -eq [Amazon.CloudFormation.StackStatus]::UPDATE_COMPLETE) { return $true }
	elseif ($CFNStack.StackStatus -eq [Amazon.CloudFormation.StackStatus]::UPDATE_ROLLBACK_COMPLETE) {
		throw "Stack has rolled back"
	}
	elseif ($CFNStack.StackStatus -eq [Amazon.CloudFormation.StackStatus]::ROLLBACK_COMPLETE) {
		throw "Stack has rolled back"
	}
	else { return $false }
}
