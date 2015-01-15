function Get-StackDependencies {
	param(
		[parameter(Mandatory=$true)]
		[System.Collections.Hashtable]
		$Stack,

		[parameter(Mandatory=$true)]
		[System.Collections.Hashtable]
		$Config,

		[parameter(Mandatory=$true)]
		[string]
		$Path,

		[parameter(Mandatory=$true)]
		[System.Collections.Hashtable]
		$Parameters,

		[parameter()]
		[string]
		$RootStackName
	)

	if ($RootStackName -eq $null -or $RootStackName -eq "") {
		$RootStackName = $Stack.Name
	}

	if ($RootStackName -eq $null -or $RootStackName -eq "") {
		throw "RootStackName is null or empty string"
	}

	Write-Verbose "Getting dependencies for $($Stack.Name)"
	$Dependencies = @()
	$TemplateFilename = Get-TemplateFilename -Stack $Stack -Path $Path
	if (Test-Path $TemplateFilename) {
		Write-Verbose "Getting list of parameters for stack [$($Stack.Name)] to work out dependencies"
		$TemplateBody = Read-TextFile $TemplateFilename
		$TestResponse = Test-CFNTemplate -TemplateBody $TemplateBody
		Write-Verbose "Retrieved list of $($TestResponse.Parameters.Count) parameters for stack [$($Stack.Name)] to work out dependencies"
		foreach ($Parameter in $TestResponse.Parameters) {
			Write-Verbose "Processing parameter [$($Parameter.ParameterKey)] for stack [$($Stack.Name)] to work out dependency"
			$NewDependency = Get-StackParameter -Parameter $Parameter -Stack $Stack -Config $Config -Path $Path -Parameters $Parameters -ValidateOnly | Where-Object { $_ -ne $null -and $_ -ne $true}
			if ($NewDependency -ne $null) {
				if ($NewDependency -NotIn $Dependencies) {
					Write-Verbose "Adding [$($NewDependency)] to dependency list for [$($RootStackName)]"
					$Dependencies = $Dependencies + $NewDependency
					$Dependency = $Config.Stacks | Where-Object { $_.Name -eq $NewDependency }
					if ($Dependency -ne $null) {
						$SubDependencies = Get-StackDependencies -Stack $Dependency -Config $Config -RootStackName $RootStackName -Path $Path -Parameters $Parameters
						$Dependencies = $Dependencies + $($SubDependencies | Where-Object { $_ -NotIn $Dependencies })
					}
					else {
						throw "Unable to get all dependencies for [$($Stack.Name)] because it is dependent upon [$($NewDependencies)] but cannot find it"
					}
				}
				else {
					Write-Verbose "Skipping [$($NewDependency)] because it is already in dependency list"
				}
			}
		}
	}
	else {
		throw "Get-StackDependencies: Unable to find template file $($TemplateFilename)"
	}

	$Dependencies
}