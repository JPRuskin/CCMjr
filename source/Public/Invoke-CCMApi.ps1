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
        # The hostname (and port) of the machine in question.
        [Parameter(ParameterSetName = "Combine")]
        [Parameter(ParameterSetName = "BodyCombine")]
        [Parameter(ParameterSetName = "QueryCombine")]
        [ValidateNotNullOrEmpty()]
        [string]$HostName = $script:HostName,

        # The portion of the API call after /api/
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "Combine")]
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "BodyCombine")]
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "QueryCombine")]
        [Alias('Path')]
        [string]$Slug,

        # The full URL of the API call
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "URL")]
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "BodyUri")]
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "QueryUri")]
        [string]$Uri = "$($script:Protocol)://$($HostName.TrimEnd('/'))/api/services/app/$($Slug.TrimStart('/api/services/app/'))",

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
        [hashtable]$Query
    )
    begin {
        if (-not $script:Session) {
            try {
                Connect-CCMServer @ConnectionParameters
            }
            catch {
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
                default {
                    $Body
                }
            }
        }

        if ($Query) {
            $RestArguments.ContentType = $null
            $RestArguments.Body = $Query
        }

        Invoke-RestMethod @RestArguments
    }
}