function Remove-CCMComputer {
    <#
        .Synopsis
            Removes a computer from Chocolatey Central Management

        .Example
            Remove-CCMComputer -Id 2 -Confirm:$false

        .Example
            Get-CCMStaleComputer -Age 30 | Remove-CCMComputer -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        # The computer to remove.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Int64]$Id
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, "Removing")) {
            $null = Invoke-CCMApi Computers/Delete -Method Delete -Query @{id = $Id}
        }
    }
}