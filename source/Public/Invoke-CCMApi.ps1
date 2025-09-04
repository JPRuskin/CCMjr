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