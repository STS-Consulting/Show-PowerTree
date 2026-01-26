function Get-TreeConfigurationData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$TreeConfiguration
    )

    $configurationLines = @()

    # Sort configuration
    $sortByText = if ([string]::IsNullOrEmpty($TreeConfiguration.SortBy)) { 'Name' } else { $TreeConfiguration.SortBy }
    $direction = if ($TreeConfiguration.SortDescending) { 'Descending' } else { 'Ascending' }
    $configurationLines += 'Sort By'.PadRight(22) + " $sortByText $direction"

    # Display columns
    $displayColumns = @()
    foreach ($column in $TreeConfiguration.HeaderTable.HeaderColumns) {
        if ($column -ne 'Hierarchy') {
            $displayColumns += $column
        }
    }
    $displayText = if ($displayColumns.Count -gt 0) { $displayColumns -join ', ' } else { 'Hierarchy Only' }
    $configurationLines += 'Display Columns'.PadRight(22) + " $displayText"

    # Human readable sizes
    $humanReadableText = if ($TreeConfiguration.HumanReadableSize -ne $true) { 'False' } else { 'True' }
    $configurationLines += 'Human Readable Sizes'.PadRight(22) + " $humanReadableText"

    # Directory only
    $configurationLines += 'Directory Only'.PadRight(22) + " $($TreeConfiguration.DirectoryOnly.ToString())"

    # Show hidden files
    $configurationLines += 'Show Hidden Files'.PadRight(22) + " $($TreeConfiguration.ShowHiddenFiles.ToString())"

    # Prune empty folders
    $configurationLines += 'Prune Empty Folders'.PadRight(22) + " $($TreeConfiguration.PruneEmptyFolders.ToString())"

    # Maximum depth
    $maximumDepthText = if ($TreeConfiguration.MaximumDepth -eq -1) { 'Unlimited' } else { $TreeConfiguration.MaximumDepth.ToString() }
    $configurationLines += 'Maximum Depth'.PadRight(22) + " $maximumDepthText"

    # Excluded directories
    $excludedDirectoriesText = if ($TreeConfiguration.ExcludeDirectories -and $TreeConfiguration.ExcludeDirectories.Count -gt 0) {
        $TreeConfiguration.ExcludeDirectories -join ', '
    } else {
        'None'
    }
    $configurationLines += 'Excluded Directories'.PadRight(22) + " $excludedDirectoriesText"

    # File extension filtering
    $includeExtensions = @()
    $excludeExtensions = @()

    if ($TreeConfiguration.ChildItemFileParameters -and $TreeConfiguration.ChildItemFileParameters.ContainsKey('Include')) {
        $includeExtensions = $TreeConfiguration.ChildItemFileParameters['Include']
    }

    if ($TreeConfiguration.ChildItemFileParameters -and $TreeConfiguration.ChildItemFileParameters.ContainsKey('Exclude')) {
        $excludeExtensions = $TreeConfiguration.ChildItemFileParameters['Exclude']
    }

    $includeText = if ($includeExtensions.Count -gt 0) { $includeExtensions -join ', ' } else { 'None' }
    $excludeText = if ($excludeExtensions.Count -gt 0) { $excludeExtensions -join ', ' } else { 'None' }

    $configurationLines += 'Include File Types'.PadRight(22) + " $includeText"
    $configurationLines += 'Exclude File Types'.PadRight(22) + " $excludeText"

    # File size bounds
    if ($TreeConfiguration.FileSizeBounds) {
        $lowerBound = $TreeConfiguration.FileSizeBounds.LowerBound
        $upperBound = $TreeConfiguration.FileSizeBounds.UpperBound
        $humanReadableLowerBound = if ($lowerBound -ge 0) { Get-HumanReadableSize -Bytes $lowerBound -Format 'Compact' } else { $null }
        $humanReadableUpperBound = if ($upperBound -ge 0) { Get-HumanReadableSize -Bytes $upperBound -Format 'Compact' } else { $null }

        $sizeFilterText = switch ($true) {
            (($lowerBound -ge 0) -and ($upperBound -ge 0)) {
                "Between $humanReadableLowerBound and $humanReadableUpperBound"
            }
            (($lowerBound -ge 0) -and ($upperBound -lt 0)) {
                "Minimum $humanReadableLowerBound"
            }
            (($lowerBound -lt 0) -and ($upperBound -ge 0)) {
                "Maximum $humanReadableUpperBound"
            }
            default { 'None' }
        }

        $configurationLines += 'File Size Filter'.PadRight(22) + " $sizeFilterText"
    } else {
        $configurationLines += 'File Size Filter'.PadRight(22) + ' None'
    }

    $configurationLines += ''

    return $configurationLines
}
