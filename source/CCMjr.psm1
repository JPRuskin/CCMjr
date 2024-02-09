Get-ChildItem -Filter *.ps1 -Recurse | ForEach-Object {
    . $_.FullName
}
