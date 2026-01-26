function Show-PowerTreeRegistry {
    <#
    .SYNOPSIS
        Displays a tree view of the Windows Registry.

    .DESCRIPTION
        The Show-PowerTreeRegistry cmdlet (alias 'ptreer', 'PowerRegistry') creates a visual representation
        of the Windows Registry keys and values. It supports filtering and output to file.

    .PARAMETER Path
        The registry path to start from. Defaults to current location.

    .PARAMETER OutFile
        File path to save the output.

    .PARAMETER NoValues
        Prevents display of registry values, showing only keys.

    .PARAMETER SortValuesByType
        Sorts registry values by their type.

    .PARAMETER UseRegistryDataTypes
        Displays usage of registry data types.

    .PARAMETER SortDescending
        Sorts keys and values in descending order.

    .PARAMETER DisplayItemCounts
        Displays the count of items in keys.

    .PARAMETER Exclude
        Array of keys to exclude.

    .PARAMETER Include
        Array of keys to include.

    .PARAMETER Depth
        Maximum depth of the tree traversal.

    .EXAMPLE
        Show-PowerTreeRegistry -Path 'HKLM:\Software\Microsoft' -Depth 2
        Displays the registry tree for Microsoft software keys up to depth 2.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = '.',

        [Parameter()]
        [Alias('o', 'of')]
        [string]$OutFile,

        [Parameter()]
        [Alias('nv')]
        [switch]$NoValues,

        [Parameter()]
        [Alias('st')]
        [switch]$SortValuesByType,

        [Parameter()]
        [Alias('dt', 'types', 'rdt')]
        [switch]$UseRegistryDataTypes,

        [Parameter()]
        [Alias('des', 'desc', 'descending')]
        [switch]$SortDescending,

        [Parameter()]
        [Alias('dic')]
        [switch]$DisplayItemCounts,

        [Parameter()]
        [Alias('e', 'exc')]
        [string[]]$Exclude = @(),

        [Parameter()]
        [Alias('i', 'inc')]
        [string[]]$Include = @(),

        [Parameter()]
        [Alias('l', 'level')]
        [int]$Depth = -1
    )

    if (-not $IsWindows) {
        throw 'This script can only be run on Windows.'
    }

    # Ensure configuration file exists before loading settings
    Initialize-ConfigurationFile

    $jsonSettings = Get-SettingsFromJson -Mode 'Registry'

    $treeRegistryConfiguration = New-Object treeRegistryConfig
    $treeRegistryConfiguration.Path = Get-Path -Path $Path
    $treeRegistryConfiguration.NoValues = $NoValues
    $treeRegistryConfiguration.Exclude = $Exclude
    $treeRegistryConfiguration.Include = $Include
    $treeRegistryConfiguration.MaximumDepth = if ($Depth -ne -1) { $Depth } else { $jsonSettings.MaximumDepth }
    $treeRegistryConfiguration.LineStyle = Build-TreeLineStyle -Style $jsonSettings.LineStyle
    $treeRegistryConfiguration.DisplayItemCounts = $DisplayItemCounts
    $treeRegistryConfiguration.SortValuesByType = $SortValuesByType
    $treeRegistryConfiguration.SortDescending = $SortDescending
    $treeRegistryConfiguration.UseRegistryDataTypes = $UseRegistryDataTypes
    $treeRegistryConfiguration.OutFile = Add-DefaultExtension -FilePath $OutFile -IsRegistry $true

    $outputBuilder = $null
    $output = $null
    $registryStats = $null

    $executionResultTime = Measure-Command {
        $hasOutputFile = -not [string]::IsNullOrEmpty($treeRegistryConfiguration.OutFile)

        if ($hasOutputFile) {
            $outputBuilder = Invoke-OutputBuilderRegistry -TreeRegistryConfiguration $treeRegistryConfiguration -ShowConfigurations $jsonSettings.ShowConfigurations
            $output = [Collections.Generic.List[string]]::new()
            $registryStats = Get-TreeRegistryView -TreeRegistryConfiguration $treeRegistryConfiguration -OutputCollection $output

            foreach ($line in $output) {
                [void]$outputBuilder.AppendLine($line)
            }

        } else {
            if ($jsonSettings.ShowConfigurations) {
                Write-ConfigurationToHost -Configuration $treeRegistryConfiguration
            }
            $registryStats = Get-TreeRegistryView -TreeRegistryConfiguration $treeRegistryConfiguration
        }
    }

    if ($null -ne $registryStats -and $jsonSettings.ShowExecutionStats) {
        $hasOutputFile = -not [string]::IsNullOrEmpty($treeRegistryConfiguration.OutFile)

        if ($hasOutputFile) {
            [void](Show-RegistryStats -RegistryStats $registryStats -ExecutionTime $executionResultTime -LineStyle $treeRegistryConfiguration.LineStyle -OutputBuilder $outputBuilder)
            $outputBuilder.ToString() | Out-File -FilePath $treeRegistryConfiguration.OutFile -Encoding UTF8
        } else {
            Show-RegistryStats -RegistryStats $registryStats -ExecutionTime $executionResultTime -LineStyle $treeRegistryConfiguration.LineStyle
        }
    } elseif (-not [string]::IsNullOrEmpty($treeRegistryConfiguration.OutFile)) {
        $outputBuilder.ToString() | Out-File -FilePath $treeRegistryConfiguration.OutFile -Encoding UTF8
    }

    if (-not [string]::IsNullOrEmpty($treeRegistryConfiguration.OutFile)) {
        $fullOutputPath = Resolve-Path $treeRegistryConfiguration.OutFile -ErrorAction SilentlyContinue
        if ($null -eq $fullOutputPath) {
            $fullOutputPath = $treeRegistryConfiguration.OutFile
        }
        Write-Information -MessageData ' ' -InformationAction Continue
        Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Output saved to: $($fullOutputPath)$($PSStyle.Reset)" -InformationAction Continue
        Write-Information -MessageData ' ' -InformationAction Continue
        #TODO make own file:
        if ($jsonSettings.OpenOutputFileOnFinish) {
            try {
                Write-Verbose -Message "Opening file: $fullOutputPath "

                # Use the appropriate method to open the file based on OS
                if ($IsWindows -or $null -eq $IsWindows) {
                    # On Windows or PowerShell 5.1 where $IsWindows is not defined
                    Start-Process $fullOutputPath
                } elseif ($IsMacOS) {
                    # On macOS
                    Start-Process 'open' -ArgumentList $fullOutputPath
                } elseif ($IsLinux) {
                    # On Linux, try xdg-open first
                    try {
                        Start-Process 'xdg-open' -ArgumentList $fullOutputPath
                    } catch {
                        # If xdg-open fails, try other common utilities
                        try { Start-Process -FilePath 'nano' -ArgumentList $fullOutputPath } catch {
                            Write-Verbose -Message 'Could not open file with xdg-open or nano'
                        }
                    }
                }
            } catch {
                Write-Warning "Could not open file after writing: $PSItem"
            }
        }
    }
}
