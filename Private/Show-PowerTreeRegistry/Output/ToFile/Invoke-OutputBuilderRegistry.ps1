function Invoke-OutputBuilderRegistry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [TreeRegistryConfig]$TreeRegistryConfiguration,
        [bool]$ShowExecutionStats = $true,
        [bool]$ShowConfigurations = $true
    )

    $outputBuilder = New-Object System.Text.StringBuilder

    [void]$outputBuilder.AppendLine("# PowerTreeRegistry Output")
    [void]$outputBuilder.AppendLine("# Generated: $(Get-Date)")
    [void]$outputBuilder.AppendLine("# Registry Path: $($TreeRegistryConfiguration.Path)")
    [void]$outputBuilder.AppendLine("")

    if($ShowConfigurations){
        [void]$outputBuilder.AppendLine("Configuration:")
        [void]$outputBuilder.AppendLine(($TreeRegistryConfiguration.LineStyle.SingleLine * 13))
        $configurationData = Get-RegistryConfigurationData -TreeRegistryConfiguration $TreeRegistryConfiguration
        foreach ($configurationLine in $configurationData) {
            [void]$outputBuilder.AppendLine($configurationLine)
        }
        [void]$outputBuilder.AppendLine("")
    }

    # Add placeholder for execution stats if needed
    if ($ShowExecutionStats) {
        [void]$outputBuilder.AppendLine("Execution Stats:")
        [void]$outputBuilder.AppendLine(($TreeRegistryConfiguration.LineStyle.SingleLine * 15))
        [void]$outputBuilder.AppendLine("Append the stats here later!!")
        [void]$outputBuilder.AppendLine("")
    }

    return $outputBuilder
}
