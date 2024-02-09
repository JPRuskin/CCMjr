function Get-CCMServerConfiguration {
    <#
        .Synopsis
            Gets the configuration for the CCM Server and attempts to connect.

        .Example
            Get-CCMServerConfiguration | Connect-CCMServer
    #>
    Import-Configuration -CompanyName CCMjr -Name Ccm
}