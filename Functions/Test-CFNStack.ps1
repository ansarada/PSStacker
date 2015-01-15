function Test-CFNStack {
	param(
		[parameter(Mandatory=$true)]
		[string]
		$StackName
	)

	Write-Verbose "Checking to see if stack $($StackName) exists"
	try {
		$Stacks = Get-CFNStackSummary -StackStatusFilter @(
			'CREATE_COMPLETE',
			'CREATE_FAILED',
			'CREATE_IN_PROGRESS',
			'DELETE_FAILED',
			'DELETE_IN_PROGRESS',
			'ROLLBACK_COMPLETE',
			'ROLLBACK_FAILED',
			'ROLLBACK_IN_PROGRESS',
			'UPDATE_COMPLETE',
			'UPDATE_COMPLETE_CLEANUP_IN_PROGRESS',
			'UPDATE_IN_PROGRESS',
			'UPDATE_ROLLBACK_COMPLETE',
			'UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS',
			'UPDATE_ROLLBACK_FAILED',
			'UPDATE_ROLLBACK_IN_PROGRESS')

		$Stack = $Stacks | Where-Object { $_.StackName -eq $StackName }

		if ($Stack -eq $null) {
			Write-Verbose "Stack $($StackName) does not exist"
			return $false
		}
		else {
			Write-Verbose "Stack $($StackName) exists"
			return $true
		}
	}
	catch {
		if ($_.Exception.Message -eq "Stack:$($StackName) does not exist") {
			Write-Verbose "Stack $($StackName) does not exist"
			return $false
		}
		else {
			throw $_
		}
	}
}