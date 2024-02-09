#requires -Modules ModuleBuilder
[CmdletBinding()]
param(
    # The version to build the module with. Defaults to the output of gitversion.
    [Parameter()]
    [string]$Version = $(
        if (Get-Command gitversion -ErrorAction SilentlyContinue) {
            gitversion /showvariable SemVer
        } else {
            '0.1.0'
        }
    )
)

Build-Module -SemVer $Version