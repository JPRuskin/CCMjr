function Set-CCMServerConfiguration {
    <#
        .Synopsis
            Sets the configuration for the CCM Server for use in other sessions.

        .Example
            Set-CCMServerConfiguration -HostName ccm.ch0.co -Credential ccmadmin
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$HostName,

        [Parameter(Mandatory, Position = 1)]
        [System.Management.Automation.PSCredential]$Credential
    )
    end {
        @{
            HostName   = $HostName
            Credential = $Credential
        } | Export-Configuration -Scope User -CompanyName CCMJr -Name CCM
        # This uses DPAPI for the credential, so there's little point going further than User scope
    }
}