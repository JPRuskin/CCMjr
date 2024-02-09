function Import-CCMDeploymentPlan {
    <#
        .Synopsis
            Imports a deployment plan from a file or URL.

        .Example
            Import-CCMDeploymentPlan -Path .\DeploymentPlan.json

        .Example
            Import-CCMDeploymentPlan -Path https://raw.githubusercontent.com/chocolatey-community/chocolatey-central-management/master/DeploymentPlan.json
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Path
    )
    process {
        $Content = if (Test-Path $Path) {
            Get-Content $Path
        } else {
            (Invoke-WebRequest $Path -UseBasicParsing).Content
        }
        Invoke-CCMApi DeploymentPlans/Import -Method POST -Body ($Content | ConvertFrom-Json)
    }
}