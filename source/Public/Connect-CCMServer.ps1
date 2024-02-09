function Connect-CCMServer {
    <#
        .Synopsis
            Creates a session to a central management instance.

        .Description
            Authenticates to a Chocolatey Central Management instance, and saves the session details in this session.

        .Example
            Connect-CCMServer -HostName http://ccm.ch0.co

        .Example
            $Credential = Get-Credential; Connect-CCMServer -Hostname https://localhost:7443 -Credential $Credential
    #>
    [CmdletBinding(HelpUri = "https://docs.chocolatey.org/en-us/central-management/chococcm/functions/connectccmserver")]
    param(
        # The hostname and port number of your Central Management installation.
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [String]$HostName,

        # The credentials for your Chocolatey Central Management installation.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.Management.Automation.PSCredential]$Credential
    )
    end {
        if (-not $HostName.StartsWith('http')) {
            Write-Verbose "No Protocol Provided - Assuming HTTPS"
            $HostName = 'https://' + $HostName
        }
        $LoginArguments = @{
            Uri             = "$HostName/Account/Login"
            Method          = "POST"
            ContentType     = 'application/x-www-form-urlencoded'
            SessionVariable = "Session"
            Body            = @{
                usernameOrEmailAddress = "$($Credential.UserName)"
                password               = "$($Credential.GetNetworkCredential().Password)"
            }
        }

        $null = Invoke-WebRequest @LoginArguments -ErrorAction Stop
 
        $script:HostName = $HostName
        $script:Session = $Session
    }
}