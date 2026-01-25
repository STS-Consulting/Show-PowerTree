function Build-FileSizeParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$CommandLineMaximumSize,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$CommandLineMinimumSize,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$SettingsLineMaximumSize,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$SettingsLineMinimumSize
    )
    # Convert string values to bytes
    $commandMaximumBytes = ConvertTo-Bytes -SizeString $CommandLineMaximumSize
    $commandMinimumBytes = ConvertTo-Bytes -SizeString $CommandLineMinimumSize
    $settingsMaximumBytes = ConvertTo-Bytes -SizeString $SettingsLineMaximumSize
    $settingsMinimumBytes = ConvertTo-Bytes -SizeString $SettingsLineMinimumSize

    # Track whether values come from settings
    $maximumFromSettings = $commandMaximumBytes -lt 0
    $minimumFromSettings = $commandMinimumBytes -lt 0

    # Prefer command line values if provided
    $maximumSize = if ($commandMaximumBytes -ge 0) { $commandMaximumBytes } else { $settingsMaximumBytes }
    $minimumSize = if ($commandMinimumBytes -ge 0) { $commandMinimumBytes } else { $settingsMinimumBytes }

    # If both maximum and minimum are non-negative, validate. Also if one of the values came from the settings add it for clarity
    if ($maximumSize -ge 0 -and $minimumSize -ge 0 -and $maximumSize -lt $minimumSize) {
        $errorMessage = "Error: Maximum file size cannot be smaller than minimum file size.`n"
        $errorMessage += "  Maximum Size: $maximumSize bytes" + $(if ($maximumFromSettings) { ' (from configuration settings)' } else { '' }) + "`n"
        $errorMessage += "  Minimum Size: $minimumSize bytes" + $(if ($minimumFromSettings) { ' (from configuration settings)' } else { '' }) + "`n"

        Write-Error $errorMessage -ErrorAction Stop
    }

    return @{
        LowerBound   = $minimumSize
        UpperBound   = $maximumSize
        ShouldFilter = ($minimumSize -ge 0) -or ($maximumSize -ge 0)
    }
}
