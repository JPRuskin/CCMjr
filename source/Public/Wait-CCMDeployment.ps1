function Wait-CCMDeployment {
    <#
        .Synopsis
            Waits for a deployment plan to complete

        .Example
            Wait-CCMDeployment -Id 2 -Timeout 600
    #>
    [CmdletBinding()]
    param(
        # The ID of the deployment plan to wait for.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64]$Id,

        # Timeout in seconds. If not provided, waits for a good while.
        [uint16]$Timeout = [uint16]::MaxValue
    )
    process {
        $Timer = [Diagnostics.Stopwatch]::StartNew()
        do {
            $Result = Invoke-CCMApi "DeploymentPlans/GetDeploymentPlanForView" -Query @{ id = $Id }

            if ($null -ne $Result.deploymentPlan.finishDateTimeUtc) {
                Write-Verbose "Deployment $Id finished at $($Result.deploymentPlan.finishDateTimeUtc)Z"
                break
            }
            Start-Sleep -Seconds 10
        } while ($Timer.Elapsed.TotalSeconds -lt $Timeout)
    }
}