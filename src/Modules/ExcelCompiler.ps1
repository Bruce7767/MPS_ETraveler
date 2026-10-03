function Open-XlsReadOnly {
    param([string]$Path)

    try {
        Start-Process `
            -FilePath 'excel.exe' `
            -ArgumentList @('/r', ('"' + $Path + '"')) `
            -ErrorAction Stop
    }
    catch {
        [System.Windows.MessageBox]::Show(
            "Traveler was compiled successfully, but Excel could not be started in Read-Only mode.`n`n$Path`n`n$($_.Exception.Message)",
            'E-Traveler'
        ) | Out-Null
    }
}

function Compile-Traveler {
    param(
        $Traveler,
        [bool]$OpenAfter = $false
    )

    if (-not $CurrentDevice -or -not $Traveler) {
        return
    }

    $registry = Get-Registry -Id $Traveler.RegistryId
    if (-not $registry) {
        [System.Windows.MessageBox]::Show(
            'Template setup is not defined. Use Edit Setup first.',
            'E-Traveler'
        ) | Out-Null
        return
    }

    $pages = @(Get-ActivePages -Traveler $Traveler -Registry $registry)
    if ($pages.Count -eq 0) {
        [System.Windows.MessageBox]::Show(
            'Compile blocked. No active traveler pages are configured.',
            'E-Traveler'
        ) | Out-Null
        return
    }

    $invalidPages = @(
        $pages | Where-Object {
            -not $_.Path -or
            [System.IO.Path]::GetExtension([string]$_.Path) -ine '.xls' -or
            -not (Test-Path -LiteralPath $_.Path -PathType Leaf)
        }
    )

    if ($invalidPages.Count -gt 0) {
        $details = $invalidPages | ForEach-Object {
            $pathText = if ($_.Path) { $_.Path } else { '<not assigned>' }
            "$($_.Label)`n$pathText"
        }

        $message = @(
            'Compile blocked. Every active page must point to an existing Excel 97-2003 .xls file.'
            ''
            ($details -join "`n`n")
        ) -join "`n"

        [System.Windows.MessageBox]::Show($message, 'E-Traveler') | Out-Null
        return
    }

    $deviceName = ConvertTo-SafeFileName $CurrentDevice.Device
    $dieName = ConvertTo-SafeFileName $CurrentDevice.Die
    $workflowName = ConvertTo-SafeFileName $Traveler.Workflow

    $outputDirectory = Join-Path (Join-Path $OutputDir $deviceName) $dieName
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

    $outputPath = Join-Path $outputDirectory ($workflowName + '.xls')
    $temporaryPath = Join-Path $outputDirectory (
        '.{0}.{1}.building.xls' -f $workflowName, [guid]::NewGuid().ToString('N')
    )

    $excel = $null
    $workbooks = $null
    $destinationWorkbook = $null
    $destinationSheets = $null

    try {
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $excel.DisplayAlerts = $false
        $excel.ScreenUpdating = $false
        $excel.EnableEvents = $false

        $workbooks = $excel.Workbooks
        $destinationWorkbook = $workbooks.Add()
        $destinationSheets = $destinationWorkbook.Worksheets
        $defaultSheetCount = $destinationSheets.Count

        foreach ($page in $pages) {
            $sourceWorkbook = $null
            $sourceSheets = $null
            $sourceSheet = $null
            $afterSheet = $null

            try {
                $sourceWorkbook = $workbooks.Open($page.Path, 0, $true)
                $sourceSheets = $sourceWorkbook.Worksheets

                if ($sourceSheets.Count -lt 1) {
                    throw "Source workbook has no worksheet: $($page.Path)"
                }

                $sourceSheet = $sourceSheets.Item(1)
                $afterSheet = $destinationSheets.Item($destinationSheets.Count)
                $sourceSheet.Copy($null, $afterSheet)
            }
            finally {
                Release-ComObject $afterSheet
                Release-ComObject $sourceSheet
                Release-ComObject $sourceSheets

                if ($sourceWorkbook) {
                    try {
                        $sourceWorkbook.Close($false)
                    }
                    finally {
                        Release-ComObject $sourceWorkbook
                    }
                }
            }
        }

        for ($index = 0; $index -lt $defaultSheetCount; $index++) {
            $defaultSheet = $null
            try {
                $defaultSheet = $destinationSheets.Item(1)
                $defaultSheet.Delete()
            }
            finally {
                Release-ComObject $defaultSheet
            }
        }

        try {
            $destinationWorkbook.CheckCompatibility = $false
        }
        catch {
        }

        $destinationWorkbook.SaveAs($temporaryPath, 56)
        $destinationWorkbook.Close($true)
        Release-ComObject $destinationWorkbook
        $destinationWorkbook = $null

        Release-ComObject $destinationSheets
        $destinationSheets = $null
        Release-ComObject $workbooks
        $workbooks = $null

        $excel.Quit()
        Release-ComObject $excel
        $excel = $null

        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()

        if (Test-Path -LiteralPath $outputPath -PathType Leaf) {
            [System.IO.File]::Replace($temporaryPath, $outputPath, $null)
        }
        else {
            [System.IO.File]::Move($temporaryPath, $outputPath)
        }

        if ($OpenAfter) {
            Open-XlsReadOnly -Path $outputPath
            return
        }

        [System.Windows.MessageBox]::Show(
            "Traveler compiled successfully.`n`n$outputPath",
            'E-Traveler'
        ) | Out-Null
    }
    catch {
        try {
            if ($destinationWorkbook) {
                $destinationWorkbook.Close($false)
            }
        }
        catch {
        }

        try {
            if ($excel) {
                $excel.Quit()
            }
        }
        catch {
        }

        Release-ComObject $destinationWorkbook
        Release-ComObject $destinationSheets
        Release-ComObject $workbooks
        Release-ComObject $excel

        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()

        [System.Windows.MessageBox]::Show(
            "Excel compilation failed. The previous compiled traveler, if any, was left unchanged.`n`n$($_.Exception.Message)",
            'E-Traveler'
        ) | Out-Null
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }
    }
}
