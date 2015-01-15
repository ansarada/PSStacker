function Get-PolicyFilename {
	param (
		[parameter(Mandatory=$true)]
		[System.Collections.Hashtable]
		$Stack,

		[parameter(Mandatory=$true)]
		[string]
		$Path
	)

	if ($Stack.policy_name -eq $null ) {
		$Filename = Join-Path $Path $(Join-Path "policies" "$($Stack.name).json")
		if (Test-Path $Filename) {
			return $Filename
		}
	}
	else {
		$Filename = Join-Path $Path $(Join-Path "policies" "$($Stack.policy_name).json")
		if (Test-Path $Filename) {
			return $Filename
		}
		else {
			throw "Unable to find policy for [$($Stack.Name)]: $($Filename)"
		}
	}
}