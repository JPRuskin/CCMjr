if ($StoredConfiguration = Get-CCMServerConfiguration) {
    Connect-CCMServer @StoredConfiguration -ErrorAction SilentlyContinue
}

if (-not $_ccmSwagger -and $script:Session) {
    $global:_ccmSwagger = Invoke-RestMethod -Uri "$($script:CentralManagementUri.OriginalString.TrimEnd('/'))/swagger/v1/swagger.json" -WebSession $script:Session
}