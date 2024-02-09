function Get-CCMComputer {
    <#
        .Synopsis
            Returns computers from the CCM Server.

        .Example
            Get-CCMComputer
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param(
        [Parameter(ParameterSetName="Name", Mandatory)]
        [string]$Name,  # May result in more than one computer

        [Parameter(ParameterSetName="Id", Mandatory)]
        [int64]$Id
    )
    process {
        Invoke-CCMApi Computers/GetAll
    }
}