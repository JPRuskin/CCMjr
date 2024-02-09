Import-Module $PSScriptRoot\..\..\ChocoCCM.psd1

Describe "Remove-CCMDeployment" {
    BeforeAll {
        InModuleScope -ModuleName ChocoCCM {
            $script:Session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
            $script:HostName = "localhost"
            $script:Protocol = "http"
        }
        Mock Invoke-RestMethod -ModuleName ChocoCCM
        Mock Get-CCMDeployment -ModuleName ChocoCCM {
            @{
                Id   = 0
                Name = "Super Complex Deployment"
            }
            @{
                Id   = 1
                Name = "Deployment Alpha"
            }
        }
    }

    Context "Removing a deployment" {
        BeforeAll {
            $TestParams = @{
                Deployment = "Super Complex Deployment"
            }

            $Result = Remove-CCMDeployment @TestParams -Confirm:$false
        }

        It "Gets the ID for the deployment to delete" {
            Should -Invoke Get-CCMDeployment -ModuleName ChocoCCM -Scope Context -Times 1 -Exactly
        }

        It "Calls the API to delete the deployment" {
            Should -Invoke Invoke-RestMethod -ModuleName ChocoCCM -Scope Context -Times 1 -Exactly -ParameterFilter {
                $Method -eq "DELETE" -and
                $Uri.AbsolutePath -eq "/api/services/app/DeploymentPlans/Delete" -and
                $Uri.Query -eq "?Id=0" -and
                $ContentType -eq "application/json"
            }
        }

        It "Returns Nothing" {
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Removing multiple deployments" {
        BeforeAll {
            $TestParams = @{
                Deployment = @(
                    "Super Complex Deployment"
                    "Deployment Alpha"
                )
            }

            $Result = Remove-CCMDeployment @TestParams -Confirm:$false
        }

        It "Gets the ID for the deployment to delete" {
            Should -Invoke Get-CCMDeployment -ModuleName ChocoCCM -Scope Context -Times 1 -Exactly
        }

        It "Calls the API to delete each deployment" {
            Should -Invoke Invoke-RestMethod -ModuleName ChocoCCM -Scope Context -Times 1 -Exactly -ParameterFilter {
                $Method -eq "DELETE" -and
                $Uri.AbsolutePath -eq "/api/services/app/DeploymentPlans/Delete" -and
                $Uri.Query -eq "?Id=0" -and
                $ContentType -eq "application/json"
            }

            Should -Invoke Invoke-RestMethod -ModuleName ChocoCCM -Scope Context -Times 1 -Exactly -ParameterFilter {
                $Method -eq "DELETE" -and
                $Uri.AbsolutePath -eq "/api/services/app/DeploymentPlans/Delete" -and
                $Uri.Query -eq "?Id=1" -and
                $ContentType -eq "application/json"
            }
        }

        It "Returns Nothing" {
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Backwards Compatibility" {
        It "Has aliased 'Deployment' to 'Name" {
            (Get-Command -Name Remove-CCMDeployment).Parameters.Name.Aliases | Should -Contain "Deployment"
        }
    }
}