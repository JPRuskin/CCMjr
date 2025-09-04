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