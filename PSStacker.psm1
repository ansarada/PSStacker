Write-Verbose "Importing AWSPowerShell"
Import-Module AWSPowerShell

foreach ($Assembly in $(Get-ChildItem -Recurse $(Join-Path $PSScriptRoot "Libs") -Filter '*.dll')) {
	Write-Host "Loading assembly $($Assembly.Name)"
	Import-Module $Assembly.FullName
}

foreach ($Script in $(Get-ChildItem $(Join-Path $PSScriptRoot "Functions"))) {
	if ($Script.Name -NotLike '*.Tests.ps1') {
		Write-Host "Dot sourcing $($Script.Name)"
		. $Script.FullName
	}
}

<#

######################################################################################
######################################################################################
######################################################################################

# Note: Need to change this to process streams

function ConvertFrom-PSCustomObject {
	param (
		[parameter(Mandatory=$true)]
		[PSCustomObject]
		$Src
	)

	if ($Src -and $Src.PSObject -and $Src.PSObject.Properties) {
		$Dst = @{}
		foreach ($Item in $($Src.PSObject.Properties | Where-Object { $_ -ne $null })) {
			if ($Item.Value.GetType().Name -eq "PSCustomObject") {
				$Value = ConvertFrom-PSCustomObject $Item.Value
			}
			elseif ($Item.Value.GetType().Name -eq "Object[]") {
				[Object[]]$Value = $Item.Value | Foreach-Object { ConvertFrom-PSCustomObject $_ }
				[Object[]]$Value = $Value | Where-Object { $_ -ne $null }
				if ($Value.Length -eq 0) {
					return
				}
			}
			else {
				$Value = $Item.Value
			}
			$Dst[$Item.Name] = $Value
		}
		$Dst
	}
}

######################################################################################
######################################################################################
######################################################################################

function Read-JsonFile {
	param (
		[parameter(Mandatory=$true)]
		[string]
		$Filename
	)

	$PSCustomObject = Read-TextFile $Filename | ConvertFrom-Json
	ConvertFrom-PSCustomObject $PSCustomObject
}

######################################################################################
######################################################################################
######################################################################################

function Read-TextFile {
	param (
		[parameter(Mandatory=$true)]
		[string]
		$Filename
	)

	$(Get-Content $Filename) -join "`n"
}

#>

######################################################################################
######################################################################################
######################################################################################

function Update-Stacks {
	[CmdletBinding()]

	param (
		[parameter()]
		[string]
		$Path = ".\",

		[parameter()]
		[string]
		$Region = "us-east-1",

		[parameter()]
		[Amazon.CloudFormation.Model.Tag[]]
		$Tags,

		[parameter()]
		[string]
		$StackNamePrefix,

		[Parameter()]
		[System.Collections.Hashtable]
		$Parameters,

		[parameter()]
		[switch]
		$ValidateOnly
	)

	$RegionFilename = Join-Path $Path $(Join-Path "Regions" "$($Region).json")

	if (-not $(Test-Path $RegionFilename)) {
		throw "Region file $($RegionFilename) does not exist"
	}
	else {
		Write-Verbose "Region file $($RegionFilename) found"
	}

	if ($(Get-AWSRegion | Where-Object { $_.Region -eq $Region }) -eq $null) {
		throw "Region $($Region) does not exist"
	}
	else {
		Write-Verbose "Region $($Region) is valid"
	}

	$Config = Read-JsonFile $RegionFilename

	if ($StackNamePrefix) {
		$Config = Add-StackNamePrefix -Config $Config -StackNamePrefix $StackNamePrefix
	}

	foreach ($Stack in $Config.Stacks) {
		Test-Stack -Stack $Stack -Path $Path -Config $Config -Parameters $Parameters
	}

	Write-Host "Calculating dependencies"
	foreach ($Stack in $Config.Stacks) {
		Write-Host "Getting dependencies for [$($Stack.Name)]"
		$Stack["Dependencies"] = Get-StackDependencies -Stack $Stack -Config $Config -Path $Path -Parameters $Parameters
		Write-Host "Found $($Stack["Dependencies"].Count) for [$($Stack.Name)]"
	}
	Write-Host "Finished calculating dependencies"

	if (-not $ValidateOnly) {

		$Completed = @()
		$InProgress = @()
		$Uncompleted = $Config.Stacks | Foreach-Object { $_.Name }
		While ($Completed.Length -lt $Config.Stacks.Length) {
			Write-Host "Uncompleted: $($Uncompleted.Length), In progress: $($InProgress.Length), Completed: $($Completed.Length), Total: $($Config.Stacks.Length)"

			foreach ($Stack in $($Config.Stacks | Where-Object { $_.Name -in $Uncompleted })) {

				if ($($Stack.Dependencies | Where-Object { $_ -NotIn $Completed }) -eq $null) {

					Write-Host "Preparing for stack $($Stack.Name)"
					$StackTemplateFilename = Get-TemplateFilename $Stack $Path
					$TemplateBody = Read-TextFile $StackTemplateFilename
					$TestResponse = Test-CFNTemplate -TemplateBody $TemplateBody
					$TemplateParameters = @()

					foreach ($Parameter in $TestResponse.Parameters) {
						$Value = Get-StackParameter -Parameter $Parameter -Stack $Stack -Config $Config -Parameters $Parameters
						$TemplateParameters = $TemplateParameters + @( @{ParameterKey = $Parameter.ParameterKey; ParameterValue = $Value} )
					}

					$StackPolicyFilename = Get-PolicyFilename $Stack $Path

					$SyncParameters = @{
						"StackName" = $Stack.Name;
						"TemplateFilename" = $StackTemplateFilename;
						"Parameters" = $TemplateParameters;
						"Capabilities" = $Stack.Capabilities;
						"OnFailure" = $Stack.OnFailure;
						"StackPolicyFilename" = $StackPolicyFilename;
						"Tags" = $Tags
					}

					Write-Host "Syncing stack $($Stack.Name)"
					Sync-CFNStack @SyncParameters

					$InProgress = $InProgress + $Stack.Name
				}
			}

			Write-Verbose "Recalculating Completed queues"
			[string[]]$Completed = $Completed + $InProgress | Where-Object { $(Test-CFNStack $_) -eq $true } | Where-Object { $(Test-StackStatusCompleted $_) -eq $true }

			Write-Verbose "Recalculating InProgress queues"
			[string[]]$InProgress = $InProgress | Where-Object { $_ -NotIn $Completed }

			Write-Verbose "Recalculating Uncompleted queues"
			[string[]]$Uncompleted = $Config.Stacks | Where-Object { $_.Name -NotIn $Completed } | Where-Object { $_.Name -NotIn $InProgress } | Foreach-Object { $_.Name }

			if ($Uncompleted.Length + $InProgress.Length + $Completed.Length -ne $Config.Stacks.Length) {
				Write-Verbose "Uncompleted: $($Uncompleted.Length), In progress: $($InProgress.Length), Completed: $($Completed.Length), Total: $($Config.Stacks.Length)"
				throw "Total of queues does not equal number of stacks"
			}

			Start-Sleep -Seconds 5
		}
	}
}
