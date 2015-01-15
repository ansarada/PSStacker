function Add-StackNamePrefix {
	[CmdletBinding()]

	param (
		[parameter(Mandatory=$true)]
		[System.Collections.Hashtable]
		$Config,

		[parameter()]
		[string]
		$StackNamePrefix
	)

	Write-Verbose "Adding stack prefix name to stack names & parameters"
	foreach ($Stack in $Config.Stacks) {
		Write-Verbose "Changing stack [$($Stack.Name)] to [$($StackNamePrefix + $Stack.Name)]"
		$Stack.Name = $StackNamePrefix + $Stack.Name
		if ($Stack.Parameters) {
			foreach ($Parameter in $Stack.Parameters.Keys) {
				if ($Stack.Parameters.$($Parameter).GetType().Name -eq "Hashtable") {
					Write-Verbose "Parameter [$($Stack.Name)].[$($Parameter)] changing stack [$($Stack.Parameters.$($Parameter).Stack)] to [$($StackNamePrefix + $Stack.Parameters.$($Parameter).Stack)]"
					$Stack.Parameters.$($Parameter).Stack = $StackNamePrefix + $Stack.Parameters.$($Parameter).Stack
				}
			}
		}
	}

	if ($Config.Defaults.Parameters) {
		Write-Verbose "Adding stack prefix name default parameters"
		foreach ($Parameter in $Config.Defaults.Parameters.Keys) {
			if ($Config.Defaults.Parameters.$($Parameter).GetType().Name -eq "Hashtable") {
				Write-Verbose "Default parameter [$($Parameter)], changing stack [$($Config.Defaults.Parameters.$($Parameter).Stack)] to [$StackNamePrefix + $Config.Defaults.Parameters.$($Parameter).Stack]"
				$Config.Defaults.Parameters.$($Parameter).Stack = $StackNamePrefix + $Config.Defaults.Parameters.$($Parameter).Stack
			}
		}
	}

	return $Config
}