function Set-CCMServerConfiguration {
    <#
        .Synopsis
            Sets the configuration for the CCM Server for use in other sessions.

        .Description
            Stores configuration for the Chocolatey Central Management server specified for use in future sessions.

        .Example
            Set-CCMServerConfiguration -CentralManagementUri https://ccm.ch0.co:244 -Credential ccmadmin

            # Prompts the user for a password and sets the configuration based on the passed values.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$CentralManagementUri,

        [Parameter(Mandatory, Position = 1)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(DontShow)]
        [ValidateSet("User", "Machine")]
        [string]$Scope = "User"
    )
    end {
        @{
            CentralManagementUri = $CentralManagementUri
            Credential = $Credential
        } | Export-Configuration -CompanyName jpruskin -Name CCMjr -Scope $Scope
    }
}