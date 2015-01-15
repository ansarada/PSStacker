$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

Describe "Add-StackNamePrefix" {
    Context "when there are two stacks, parameters & defaults - Prefix not supplied" {
        $Config = @{
            defaults = @{
                parameters = @{
                    parameter1 = 'String2';
                    parameter2 = @{stack = 'Stack1'; output = 'Output1-1'}
                }
            };
            stacks = @(
                @{name = 'Stack1'; template_name = 'template1'},
                @{
                    name = 'Stack2';
                    template_name = 'template2';
                    parameters = @{
                        parameter1 = "String2";
                        parameter2 = @{stack = 'Stack1'; output = 'Output1-1'}
                    }
                }
            )
        }
        $StackNamePrefix = ''

        $ActualResult = Add-StackNamePrefix -Config $Config -StackNamePrefix $StackNamePrefix
        $ExpectedResult = $Config

            It "Returns exactly matching hashtable/array added" {
                $($ActualResult | ConvertTo-Json -Compress) | Should Be $($ExpectedResult | ConvertTo-Json -Compress)
            }
    }

    Context "when there are two stacks, parameters & defaults - Prefix supplied" {
        $Config = @{
            defaults = @{
                parameters = @{
                    parameter1 = 'String2';
                    parameter2 = @{stack = 'Stack1'; output = 'Output1-1'}
                }
            };
            stacks = @(
                @{name = 'Stack1'; template_name = 'template1'},
                @{
                    name = 'Stack2';
                    template_name = 'template2';
                    parameters = @{
                        parameter1 = "String2";
                        parameter2 = @{stack = 'Stack1'; output = 'Output1-1'}
                    }
                }
            )
        }
        $StackNamePrefix = 'Prefix-'

        $ActualResult = Add-StackNamePrefix -Config $Config -StackNamePrefix $StackNamePrefix
        $ExpectedResult = @{
            defaults = @{
                parameters = @{
                    parameter1 = 'String2';
                    parameter2 = @{stack = 'Prefix-Stack1'; output = 'Output1-1'}
                }
            };
            stacks = @(
                @{name = 'Prefix-Stack1'; template_name = 'template1'},
                @{
                    name = 'Prefix-Stack2';
                    template_name = 'template2';
                    parameters = @{
                        parameter1 = "String2";
                        parameter2 = @{stack = 'Prefix-Stack1'; output = 'Output1-1'}
                    }
                }
            )
        }

            It "Returns exactly matching hashtable/array added" {
                $($ActualResult | ConvertTo-Json -Compress) | Should Be $($ExpectedResult | ConvertTo-Json -Compress)
            }
    }
}
