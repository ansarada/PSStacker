$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

Describe "Get-PolicyFilename" {
    Context "when there is no policy" {
        $Stack = @{
            name = 'stack_name_value'
        }
        $Path = 'TestDrive:\'

        $result = Get-PolicyFilename -Stack $Stack -Path $Path

            It "returns null" {
                $result | Should Be $null
            }
    }

    Context "when there is a policy and path has no trailing slash and the policy file exists" {
        New-Item 'TestDrive:\policies' -Type directory
        Set-Content 'TestDrive:\policies\policy_name_value.json' -value ''

        $Stack = @{
            name = 'stack_name_value';
            policy_name = 'policy_name_value';
        }
        $Path = 'TestDrive:\'

        $result = Get-PolicyFilename -Stack $Stack -Path $Path

            It "returns null" {
                $result | Should Be 'TestDrive:\policies\policy_name_value.json'
            }
    }

    Context "when there is a stack name and path has no trailing slash and the policy file exists" {
        New-Item 'TestDrive:\policies' -Type directory
        Set-Content 'TestDrive:\policies\stack_name_value.json' -value ''

        $Stack = @{
            name = 'stack_name_value';
        }
        $Path = 'TestDrive:\'

        $result = Get-PolicyFilename -Stack $Stack -Path $Path

            It "returns null" {
                $result | Should Be 'TestDrive:\policies\stack_name_value.json'
            }
    }
}
