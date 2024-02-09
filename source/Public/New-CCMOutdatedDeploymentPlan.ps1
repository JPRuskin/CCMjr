function New-CCMOutdatedDeploymentPlan {
    <#
        .Synopsis
            Creates a new deployment plan for outdated software, for either a single computer or all computers.

        .Example
            New-CCMOutdatedDeploymentPlan -ComputerId 1234 -Deploy
    #>
    [CmdletBinding(DefaultParameterSetName = "All")]
    param(
        [Parameter(ParameterSetName = "Computer", ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$ComputerId,

        [switch]$Deploy
    )
    process {
        $RequestArgs = if ($PSCmdlet.ParameterSetName -eq "Computer") {
            @{
                Slug = "DeploymentPlans/CreateOrEditForComputer"
                Body = @{
                    computerId                  = $ComputerId
                    createOutdatedSoftwareSteps = $true
                }
            }
        } else {
            @{
                Slug = "DeploymentPlans/CreateOrEditForOutdated"
                Body = @{}
            }
        }

        $Result = Invoke-CCMApi -Method Post @RequestArgs

        if ($Result -and $Deploy) {
            # Trigger the deployment plan
            Invoke-CCMApi "DeploymentPlans/MoveToReady" -Method Post -Body @{ id = $Result.id }
            Invoke-CCMApi "DeploymentPlans/Start" -Method Post -Body @{ id = $Result.id }
        }

        return $Result
    }
}