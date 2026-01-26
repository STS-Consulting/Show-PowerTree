

# Build file parameter hashtable (for some reason we cant add the path variable here)
function Build-ChildItemFileParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$ShowHiddenFiles,
        [Parameter(Mandatory = $false)]
        [string[]]$CommandLineIncludeExtension = @(),
        [Parameter(Mandatory = $false)]
        [string[]]$CommandLineExcludeExtension = @(),
        [Parameter(Mandatory = $false)]
        [hashtable]$FileSettings
    )

    $fileParameters = @{
        File        = $true
        ErrorAction = 'SilentlyContinue'
    }

    if ($ShowHiddenFiles) {
        $fileParameters.Add('Force', $true)
    }

    $includeExtensions = @()
    $excludeExtensions = @()

    # For Include Extensions - check if command line parameters are provided
    if ($CommandLineIncludeExtension -and $CommandLineIncludeExtension.Count -gt 0) {
        # Command-line parameters take precedence
        $includeExtensions = $CommandLineIncludeExtension
    } elseif ($FileSettings -and $FileSettings.IncludeExtensions -and $FileSettings.IncludeExtensions.Count -gt 0) {
        # Fall back to configuration file FileSettings if available
        $includeExtensions = $FileSettings.IncludeExtensions
    }

    # For Exclude Extensions - check if command line parameters are provided
    if ($CommandLineExcludeExtension -and $CommandLineExcludeExtension.Count -gt 0) {
        $excludeExtensions = $CommandLineExcludeExtension
    } elseif ($FileSettings -and $FileSettings.ExcludeExtensions -and $FileSettings.ExcludeExtensions.Count -gt 0) {
        $excludeExtensions = $FileSettings.ExcludeExtensions
    }

    # Format the extensions for PowerShell commands
    $normalizedIncludeExtension = Format-FileExtensions -Extensions $includeExtensions
    $normalizedExcludeExtension = Format-FileExtensions -Extensions $excludeExtensions

    # Add to parameters if not empty
    if ($normalizedIncludeExtension -and $normalizedIncludeExtension.Count -gt 0) {
        $fileParameters.Add('Include', $normalizedIncludeExtension)
    }

    if ($normalizedExcludeExtension -and $normalizedExcludeExtension.Count -gt 0) {
        $fileParameters.Add('Exclude', $normalizedExcludeExtension)
    }

    return $fileParameters
}
