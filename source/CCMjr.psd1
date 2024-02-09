@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'CCMjr.psm1'

    # Version number of this module.
    ModuleVersion     = '0.12.0'

    # ID used to uniquely identify this module
    GUID              = '8ce70731-7be2-47b1-b6f7-932ed4b67e1b'

    # Author of this module
    Author            = 'James Ruskin'

    # Description of the functionality provided by this module
    Description       = 'This module provides a PowerShell wrapper to Chocolatey Central Management. See https://docs.chocolatey.org/en-us/central-management/ for more information.'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        "Configuration"
    )

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @(
        #"CCM.Formats.ps1xml"
    )

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = '*'

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = '*'

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{
            PreRelease = '-test'

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('chocolatey', 'central-management', 'automation')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/jpruskin/CCMjr/blob/main/LICENSE.md'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/jpruskin/CCMjr'

            # A URL to an icon representing this module.
            IconUri      = 'https://img.chocolatey.org/nupkg/chocolateyicon.png'

            # ReleaseNotes of this module
            ReleaseNotes = ''
        } # End of PSData hashtable
    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI       = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}
