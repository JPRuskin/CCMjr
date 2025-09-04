function Connect-CCMServer {
    <#
        .Synopsis
            Creates a session to a central management instance.

        .Description
            Authenticates to a Chocolatey Central Management instance, and saves the session details in this session.

        .Example
            Connect-CCMServer -CentralManagementUri http://localhost

            # Connects to the server with an interactive prompt for credential.

        .Example
            $Credential = Get-Credential; Connect-CCMServer -CentralManagementUri https://example.com:7443 -Credential $Credential

            # Connects to the server using the provided credential.
    #>
    [CmdletBinding(HelpUri = "https://docs.chocolatey.org/en-us/central-management/chococcm/functions/connectccmserver")]
    param(
        # The uri used to access your Central Management installation.
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [uri]$CentralManagementUri,

        # The credentials for your Chocolatey Central Management installation.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.Management.Automation.PSCredential]$Credential
    )
    end {
        if (-not $CentralManagementUri.Scheme) {
            Write-Verbose "No Protocol Provided - Assuming HTTPS"
            $CentralManagementUri = 'https://' + $CentralManagementUri.OriginalString
        }

        $LoginArguments = @{
            Uri             = "$($CentralManagementUri.OriginalString.TrimEnd('/'))/Account/Login"
            Method          = "POST"
            ContentType     = 'application/x-www-form-urlencoded'
            SessionVariable = "Session"
            Body            = @{
                usernameOrEmailAddress = "$($Credential.UserName)"
                password               = "$($Credential.GetNetworkCredential().Password)"
            }
        }

        $null = Invoke-WebRequest @LoginArguments -ErrorAction Stop

        $script:CentralManagementUri = $CentralManagementUri
        $script:Session = $Session
    }
}