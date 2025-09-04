#Region '.\Classes\CCMComputer.ps1' 0
class CCMComputer {
    [int64]$Id
    [guid]$ComputerGUID
    [string]$Name
    [string]$FriendlyName
    [string]$DisplayName
    [ipaddress]$IpAddress
}
#EndRegion '.\Classes\CCMComputer.ps1' 9
#Region '.\Classes\CCMDeploymentPlan.ps1' 0
class CCMDeploymentPlan {
    
}
#EndRegion '.\Classes\CCMDeploymentPlan.ps1' 4
#Region '.\Classes\CCMDeploymentStep.ps1' 0
class CCMDeploymentStep {
    
}
#EndRegion '.\Classes\CCMDeploymentStep.ps1' 4
#Region '.\Classes\CCMGroup.ps1' 0
class CCMGroup {
    
}
#EndRegion '.\Classes\CCMGroup.ps1' 4
#Region '.\Private\Get-CCMComputer.ps1' 0
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
#EndRegion '.\Private\Get-CCMComputer.ps1' 21
#Region '.\Public\Connect-CCMServer.ps1' 0
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
#EndRegion '.\Public\Connect-CCMServer.ps1' 52
#Region '.\Public\Get-CCMServerConfiguration.ps1' 0
function Get-CCMServerConfiguration {
    <#
        .Synopsis
            Gets the configuration for the CCM Server and attempts to connect.

        .Example
            Get-CCMServerConfiguration | Connect-CCMServer
    #>
    Import-Configuration -CompanyName jpruskin -Name CCMjr
}
#EndRegion '.\Public\Get-CCMServerConfiguration.ps1' 11
#Region '.\Public\Import-CCMDeploymentPlan.ps1' 0
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
#EndRegion '.\Public\Import-CCMDeploymentPlan.ps1' 26
#Region '.\Public\Import-CCMExampleFunctions.ps1' 0
function Import-CCMExampleFunctions {
    [CmdletBinding()]
    param(
        # If provided, removes the "unsupported" warning for undocumented endpoints.
        [switch]$RemoveUndocumentedWarning
    )

    if ($RemoveUndocumentedWarning) {
        $env:CCMMayBeUnsupported = $true
    }

    Export-ModuleMember -Function @(
        "Get-CCMComputer"
    )
}
#EndRegion '.\Public\Import-CCMExampleFunctions.ps1' 16
#Region '.\Public\Invoke-CCMApi.ps1' 0
function Invoke-CCMApi {
    <#
        .SYNOPSIS
            Calls the CCM API

        .EXAMPLE
            Invoke-CCMApi -Uri "https://ccm.example.com/api/services/app/Groups/GetAll"

        .EXAMPLE
            Invoke-CCMApi -Slug "Groups/GetAll"

        .EXAMPLE
            Invoke-CCMApi -Slug "Groups/CreateOrEdit" -Method POST -Body @{ name = "Test" }

        .EXAMPLE
            Invoke-CCMApi -Slug "ComputerSoftware/GetAllPagedBySoftwareId" -Query @{ filter=""; softwareId=$Result.Id; skipCount=30; maxResultCount=10 }
    #>
    [Alias('ccm')]
    [CmdletBinding(DefaultParameterSetName = "Combine", HelpUri = "https://docs.chocolatey.org/en-us/central-management/chococcm/functions/")]
    param(
        # The portion of the API call after /api/
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "Combine")]
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "BodyCombine")]
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "QueryCombine")]
        [Alias('Path')]
        [ArgumentCompleter({
            param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
            if (-not $_ccmSwagger -and $script:Session) {
                $global:_ccmSwagger = Invoke-RestMethod -Uri "$($script:CentralManagementUri.OriginalString.TrimEnd('/'))/swagger/v1/swagger.json" -WebSession $script:Session
            }

            $_ccmSwagger.paths.PSObject.Properties.Name | Where-Object {
                $_ -like "*$WordToComplete*"
            } | ForEach-Object {
                $Path = $_ccmSwagger.paths.$_
                $ShortPath = $_ -replace "^/api/services/app/"

                [System.Management.Automation.CompletionResult]::new(
                    $ShortPath,
                    $ShortPath,
                    "ParameterValue",
                    $(if ($Path.$($Path.PSObject.Properties.Name).Summary) {
                        $Path.$($Path.PSObject.Properties.Name).Summary
                    } else {
                        $_
                    })
                )
            }
        })]
        [string]$Slug,

        # The full URL of the API call
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "URI")]
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "BodyUri")]
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "QueryUri")]
        [string]$Uri = "$($script:CentralManagementUri.OriginalString.TrimEnd('/'))/api/services/app/$($Slug.TrimStart('/api/services/app/'))",

        # The Web Request method to use
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = "GET",

        # The content type, if submitting body
        [Parameter(ParameterSetName = "BodyCombine")]
        [Parameter(ParameterSetName = "BodyUri")]
        [string]$ContentType = "application/json",

        # The body to submit with the request
        [Parameter(Mandatory, ParameterSetName = "BodyCombine")]
        [Parameter(Mandatory, ParameterSetName = "BodyUri")]
        $Body,

        # The query string to submit with the requested URI
        [Parameter(Mandatory, ParameterSetName = "QueryCombine")]
        [Parameter(Mandatory, ParameterSetName = "QueryUri")]
        [hashtable]$Query,

        # Set to return the raw output of the Invoke-RestMethod
        [switch]$Raw
    )
    begin {
        if (-not $script:Session) {
            try {
                Connect-CCMServer @ConnectionParameters -ErrorAction Stop
            } catch {
                throw "Unauthenticated! Please run Connect-CCMServer first!"
            }
        }
    }
    process {
        $RestArguments = @{
            Uri         = $Uri
            Method      = $Method
            ContentType = $ContentType
            WebSession  = $Session
        }

        if ((Get-Command Invoke-RestMethod).Parameters.ContainsKey("UseBasicParsing")) {
            $RestArguments.UseBasicParsing = $true
        }

        if ($Body) {
            $RestArguments.Body = switch ($ContentType) {
                "application/json" {
                    $Body | ConvertTo-Json -Depth 5  # ? Consider handling the difference between PS 5 and 7 with single item arrays
                }
                "application/json&skipconvert" {
                    # This is an absolute magic value, for those times you need to process the JSON yourself.
                    $RestArguments.ContentType = "application/json"
                    $Body
                }
                default {
                    $Body
                }
            }
        }

        if ($Query) {
            $RestArguments.ContentType = $null
            $RestArguments.Body = $Query
        }

        if ($_ccmSwagger.paths.PSObject.Properties.Name -notcontains ($RestArguments.Uri -replace $script:CentralManagementUri.OriginalString.TrimEnd('/')) -and -not $env:CCMMayBeUnsupported) {
            Write-Warning "$($RestArguments.Uri) is not a documented API call for this server. It may not work! Set `$env:CCMMayBeUnsupported to skip this warning."
        }

        $Result = Invoke-RestMethod @RestArguments
        if ($Raw) {
            $Result
        } else {
            $Result.result
        }
    }
}
#EndRegion '.\Public\Invoke-CCMApi.ps1' 133
#Region '.\Public\New-CCMOutdatedDeploymentPlan.ps1' 0
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
#EndRegion '.\Public\New-CCMOutdatedDeploymentPlan.ps1' 44
#Region '.\Public\Remove-CCMComputer.ps1' 0
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
#EndRegion '.\Public\Remove-CCMComputer.ps1' 24
#Region '.\Public\Set-CCMServerConfiguration.ps1' 0
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
#EndRegion '.\Public\Set-CCMServerConfiguration.ps1' 33
#Region '.\Public\Wait-CCMDeployment.ps1' 0
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
#EndRegion '.\Public\Wait-CCMDeployment.ps1' 31
#Region '.\Suffix.ps1' 0
if ($StoredConfiguration = Get-CCMServerConfiguration) {
    Connect-CCMServer @StoredConfiguration -ErrorAction SilentlyContinue
}

if (-not $_ccmSwagger -and $script:Session) {
    $global:_ccmSwagger = Invoke-RestMethod -Uri "$($script:CentralManagementUri.OriginalString.TrimEnd('/'))/swagger/v1/swagger.json" -WebSession $script:Session
}
#EndRegion '.\Suffix.ps1' 8
