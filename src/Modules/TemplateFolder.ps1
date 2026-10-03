function Open-CurrentTemplateFolder {
    if (-not $CurrentTraveler) {
        return
    }

    $registry = Get-Registry -Id $CurrentTraveler.RegistryId
    if (-not $registry -or [string]::IsNullOrWhiteSpace($registry.Folder)) {
        [System.Windows.MessageBox]::Show(
            'Template Folder is not defined.',
            'E-Traveler'
        ) | Out-Null
        return
    }

    if (-not (Test-Path -LiteralPath $registry.Folder -PathType Container)) {
        [System.Windows.MessageBox]::Show(
            "Template Folder does not exist:`n`n$($registry.Folder)",
            'E-Traveler'
        ) | Out-Null
        return
    }

    Start-Process explorer.exe -ArgumentList @(('"' + $registry.Folder + '"'))
}
