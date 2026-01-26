function Show-TreeStats {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$TreeStats,

        [Parameter(Mandatory = $true)]
        [System.TimeSpan]$ExecutionTime,

        [Parameter(Mandatory = $false)]
        [System.Text.StringBuilder]$OutputBuilder = $null,

        [Parameter(Mandatory = $false)]
        [hashtable]$LineStyle = @{ SingleLine = '-' },

        [Parameter(Mandatory = $false)]
        [bool]$DisplaySize = $false
    )

    $formattedTime = Format-ExecutionTime -ExecutionTime $ExecutionTime

    $headers = @(
        'Files',
        'Folders',
        'Total Items',
        'Maximum Depth',
        'Total Size',
        'Execution Time'
    )

    $totalItemsPrinted = $TreeStats.FilesPrinted + $TreeStats.FoldersPrinted

    $values = @(
        $TreeStats.FilesPrinted,
        $TreeStats.FoldersPrinted,
        $totalItemsPrinted,
        $TreeStats.MaximumDepth,
        $(Get-HumanReadableSize -Bytes $TreeStats.TotalSize -Format 'Padded'),
        $formattedTime
    )

    $spacing = '    '

    $headerLine = ''
    foreach ($header in $headers) {
        $headerLine += $header + $spacing
    }

    $underscoreLine = ''
    foreach ($header in $headers) {
        $underscoreLine += $LineStyle.SingleLine * $header.Length + $spacing
    }

    $valuesLine = ''
    for ($iteration = 0; $iteration -lt $headers.Count; $iteration++) {
        $value = $values[$iteration].ToString()
        $valuesLine += $value.PadRight($headers[$iteration].Length) + $spacing
    }

    $largestFilePath = if ($null -ne $TreeStats.LargestFile) { $TreeStats.LargestFile.FullName } else { 'None' }
    $largestFileSize = if ($null -ne $TreeStats.LargestFile) { Get-HumanReadableSize -Bytes $TreeStats.LargestFile.Length -Format 'Padded' } else { '0 B' }
    $largestFolderSize = Get-HumanReadableSize -Bytes $TreeStats.LargestFolderSize -Format 'Padded'

    if ($null -ne $OutputBuilder) {
        $placeholderText = 'Append the stats here later!!'

        $statsContent = @"
$headerLine
$underscoreLine
$valuesLine

"@

        if ($DisplaySize) {
            $statsContent += @"

Largest File: $largestFileSize $largestFilePath
Largest Folder: $largestFolderSize $($TreeStats.LargestFolder)

"@
        }

        [void]$OutputBuilder.Replace($placeholderText, $statsContent)
    } else {
        if ($null -ne $global:PSStyle -and $null -ne $global:PSStyle.Formatting -and $null -ne $global:PSStyle.Formatting.TableHeader) {
            $headerColor = $global:PSStyle.Formatting.TableHeader
            $resetColor = $global:PSStyle.Reset

            Write-Information -MessageData ' ' -InformationAction Continue
            Write-Information -MessageData "$headerColor$headerLine$resetColor" -InformationAction Continue
            Write-Information -MessageData "$headerColor$underscoreLine$resetColor" -InformationAction Continue
            Write-Information -MessageData $valuesLine -InformationAction Continue

            if ($DisplaySize) {
                Write-Information -MessageData ' ' -InformationAction Continue
                Write-Information -MessageData "$headerColor`Largest File:$resetColor $largestFileSize $largestFilePath" -InformationAction Continue
                Write-Information -MessageData "$headerColor`Largest Folder:$resetColor $largestFolderSize $($TreeStats.LargestFolder)" -InformationAction Continue
            }
        } else {
            Write-Information -MessageData ' ' -InformationAction Continue
            Write-Information -MessageData $headerLine -InformationAction Continue
            Write-Information -MessageData $underscoreLine -InformationAction Continue
            Write-Information -MessageData $valuesLine -InformationAction Continue

            if ($DisplaySize) {
                Write-Information -MessageData ' ' -InformationAction Continue
                # Fallback colors are tricky with Write-Information, stripping them or using default text.
                # Assuming PSStyle is available since we mandate PS 7.5+
                Write-Information -MessageData "Largest File: $largestFileSize $largestFilePath" -InformationAction Continue
                Write-Information -MessageData "Largest Folder: $largestFolderSize $($TreeStats.LargestFolder)" -InformationAction Continue
            }
        }
    }
}
