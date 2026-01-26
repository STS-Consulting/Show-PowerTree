function Get-RegistryConfigurationData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [TreeRegistryConfig]$TreeRegistryConfiguration
    )

    $configurationData = @()

    $sortByText = if ($TreeRegistryConfiguration.SortValuesByType) { 'Type' } else { 'Registry Order' }
    $direction = if ($TreeRegistryConfiguration.SortDescending) { 'Descending' } else { 'Ascending' }
    $configurationData += @{ Key = 'Sort By'; Value = "$sortByText $direction" }

    $dataTypeText = if ($TreeRegistryConfiguration.UseRegistryDataTypes) {
        'REG_SZ, REG_DWORD, etc.'
    } else {
        'String, DWord, etc.'
    }
    $configurationData += @{ Key = 'Type Format'; Value = $dataTypeText }
    $configurationData += @{ Key = 'NoValues'; Value = $TreeRegistryConfiguration.NoValues }
    $configurationData += @{ Key = 'DisplayItemCounts'; Value = $TreeRegistryConfiguration.DisplayItemCounts }
    $configurationData += @{ Key = 'SortValuesByType'; Value = $TreeRegistryConfiguration.SortValuesByType }

    if ($TreeRegistryConfiguration.MaximumDepth -ne -1) {
        $configurationData += @{ Key = 'Maximum Depth'; Value = $TreeRegistryConfiguration.MaximumDepth }
    } else {
        $configurationData += @{ Key = 'Maximum Depth'; Value = 'Unlimited' }
    }

    if ($TreeRegistryConfiguration.Include -and $TreeRegistryConfiguration.Include.Count -gt 0) {
        $configurationData += @{ Key = 'Include (Values)'; Value = ($TreeRegistryConfiguration.Include -join ', ') }
    } else {
        $configurationData += @{ Key = 'Include (Values)'; Value = 'None' }
    }

    if ($TreeRegistryConfiguration.Exclude -and $TreeRegistryConfiguration.Exclude.Count -gt 0) {
        $configurationData += @{ Key = 'Exclude (Keys/Values)'; Value = ($TreeRegistryConfiguration.Exclude -join ', ') }
    } else {
        $configurationData += @{ Key = 'Exclude (Keys/Values)'; Value = 'None' }
    }


    $maxKeyLength = ($configurationData | ForEach-Object { $PSItem.Key.Length } | Measure-Object -Maximum).Maximum + 1

    $formattedData = $configurationData | ForEach-Object {
        $paddedKey = $PSItem.Key.PadRight($maxKeyLength)
        "$paddedKey $($PSItem.Value)"
    }

    return $formattedData
}
