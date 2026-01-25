function Show-RegistryStats {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [RegistryStats]$RegistryStats,

        [Parameter(Mandatory = $true)]
        [System.TimeSpan]$ExecutionTime,

        [Parameter(Mandatory = $false)]
        [hashtable]$LineStyle = @{ SingleLine = '-' },

        [Parameter(Mandatory = $false)]
        [System.Text.StringBuilder]$OutputBuilder = $null
    )

    $formattedTime = Format-ExecutionTime -ExecutionTime $ExecutionTime

    $headers = @(
        'Keys',
        'Values',
        'Total Items',
        'Maximum Depth',
        'Execution Time'
    )

    $totalItems = $RegistryStats.KeysProcessed + $RegistryStats.ValuesProcessed

    $values = @(
        $RegistryStats.KeysProcessed,
        $RegistryStats.ValuesProcessed,
        $totalItems,
        $RegistryStats.MaximumDepthReached,
        $formattedTime
    )

    $spacing = '    '

    $headerLine = ''
    foreach ($header in $headers) {
        $headerLine += $header + $spacing
    }

    $underscoreLine = ''
    foreach ($header in $headers) {
        $underscoreLine += ($LineStyle.SingleLine * $header.Length) + $spacing
    }

    $valuesLine = ''
    for ($iteration = 0; $iteration -lt $headers.Count; $iteration++) {
        $value = $values[$iteration].ToString()
        $valuesLine += $value.PadRight($headers[$iteration].Length) + $spacing
    }

    if ($OutputBuilder -ne $null) {
        # Replace the placeholder line with actual stats using StringBuilder.Replace
        $placeholderLine = 'Append the stats here later!!'

        $statsContent = @"
$headerLine
$underscoreLine
$valuesLine
"@

        # Direct replacement without clearing the entire StringBuilder
        [void]$OutputBuilder.Replace($placeholderLine, $statsContent)
    } else {
        if ($null -ne $global:PSStyle -and $null -ne $global:PSStyle.Formatting -and $null -ne $global:PSStyle.Formatting.TableHeader) {
            $headerColor = $global:PSStyle.Formatting.TableHeader
            $resetColor = $global:PSStyle.Reset

            Write-Host ''
            Write-Host "$headerColor$headerLine$resetColor"
            Write-Host "$headerColor$underscoreLine$resetColor"
            Write-Host $valuesLine
            Write-Host ''
        } else {
            Write-Host ''
            Write-Host $headerLine -ForegroundColor Cyan
            Write-Host $underscoreLine -ForegroundColor DarkCyan
            Write-Host $valuesLine
            Write-Host ''
        }
    }
}
