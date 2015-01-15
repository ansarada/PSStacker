$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

Import-Module AWSPowerShell

Describe 'Test-CFNStack' {
    Context 'when there no stacks' {
        Mock Get-CFNStackSummary {
            return [Amazon.CloudFormation.Model.StackSummary[]] @()
        }

        $result = Test-CFNStack -StackName 'StackName'

            It "returns false" {
                $result | Should Be $false
            }
    }

    Context 'when there are stacks but not of the name under test' {
        Mock Get-CFNStackSummary {
            return [Amazon.CloudFormation.Model.StackSummary[]] @(@{
                CreationTime = New-Object DateTime(2014, 01, 01);
                DeletionTime = New-Object DateTime(2014, 01, 01);
                LastUpdatedTime = New-Object DateTime(2014, 01, 01);
                StackId = 'arn:aws:cloudformation:ap-southeast-2:292525414287:stack/dr-2441/c5a34b00-28f1-11e4-b548-506726f1';
                StackName = 'OtherStackName';
                StackStatus = New-Object Amazon.CloudFormation.StackStatus('CREATE_COMPLETE');
                StackStatusReason = 'StackStatusReason';
                TemplateDescription = 'TemplateDescription'

            })
        }

        $result = Test-CFNStack -StackName 'StackName'

            It "returns false" {
                $result | Should Be $false
            }
    }

    Context 'when there are stacks and one of the name under test but it is deleted' {
        Mock Get-CFNStackSummary {
            if ($StackStatusFilter -contains 'DELETE_COMPLETE') {
                return [Amazon.CloudFormation.Model.StackSummary[]] @(@{
                    CreationTime = New-Object DateTime(2014, 01, 01);
                    DeletionTime = New-Object DateTime(2014, 01, 01);
                    LastUpdatedTime = New-Object DateTime(2014, 01, 01);
                    StackId = 'arn:aws:cloudformation:ap-southeast-2:292525414287:stack/dr-2441/c5a34b00-28f1-11e4-b548-506726f1';
                    StackName = 'StackName';
                    StackStatus = New-Object Amazon.CloudFormation.StackStatus('DELETE_COMPLETE');
                    StackStatusReason = 'StackStatusReason';
                    TemplateDescription = 'TemplateDescription'
                })
            } else {
                return [Amazon.CloudFormation.Model.StackSummary[]] @()
            }
        }

        $result = Test-CFNStack -StackName 'StackName'

            It "returns false" {
                $result | Should Be $false
            }
    }

    Context 'when there are stacks and one of the name under test and it is not deleted' {
        Mock Get-CFNStackSummary {
            return [Amazon.CloudFormation.Model.StackSummary[]] @(@{
                CreationTime = New-Object DateTime(2014, 01, 01);
                DeletionTime = New-Object DateTime(2014, 01, 01);
                LastUpdatedTime = New-Object DateTime(2014, 01, 01);
                StackId = 'arn:aws:cloudformation:ap-southeast-2:292525414287:stack/dr-2441/c5a34b00-28f1-11e4-b548-506726f1';
                StackName = 'StackName';
                StackStatus = New-Object Amazon.CloudFormation.StackStatus('CREATE_COMPLETE');
                StackStatusReason = 'StackStatusReason';
                TemplateDescription = 'TemplateDescription'

            })
        }

        $result = Test-CFNStack -StackName 'StackName'

            It "returns false" {
                $result | Should Be $true
            }
    }
}
