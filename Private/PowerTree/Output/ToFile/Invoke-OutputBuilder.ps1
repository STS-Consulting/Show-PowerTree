function Invoke-OutputBuilder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [TreeConfig]$TreeConfiguration,
        [bool]$ShowExecutionStats,
        [bool]$ShowConfigurations = $true
    )

    # Only create OutputBuilder if we need to save to a file
    if ([string]::IsNullOrEmpty($TreeConfiguration.OutFile)) {
        return $null
    }

    $outputBuilder = New-Object System.Text.StringBuilder

    # Add file header
    [void]$outputBuilder.AppendLine('# PowerTree Output')
    [void]$outputBuilder.AppendLine("# Generated: $(Get-Date)")
    [void]$outputBuilder.AppendLine("# Path: $($TreeConfiguration.Path)")
    if (-not [string]::IsNullOrEmpty($TreeConfiguration.OutFile)) {
        [void]$outputBuilder.AppendLine("# Output File: $($TreeConfiguration.OutFile)")
    }

    if ($ShowConfigurations) {
        # Get configuration lines for file output
        $configurationLines = Get-TreeConfigurationData -TreeConfiguration $TreeConfiguration

        foreach ($line in $configurationLines) {
            [void]$outputBuilder.AppendLine($line)
        }
    }

    if ($ShowExecutionStats) {
        [void]$outputBuilder.AppendLine('Append the stats here later!!')
    }

    return $outputBuilder
}
