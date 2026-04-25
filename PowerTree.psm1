# Define script-level variables
$script:ModuleRoot = $PSScriptRoot
New-Alias -Name 'ptree' -Value 'Show-PowerTree'
New-Alias -Name 'PowerTree' -Value 'Show-PowerTree'
New-Alias -Name 'Start-PowerTree' -Value 'Show-PowerTree'
New-Alias -Name 'Edit-PtreeConfig' -Value 'Edit-PowerTreeConfig'
New-Alias -Name 'Edit-Ptree' -Value 'Edit-PowerTreeConfig'
New-Alias -Name 'Edit-PowerTree' -Value 'Edit-PowerTreeConfig'
New-Alias -Name 'ptreer' -Value 'Show-PowerTreeRegistry'
New-Alias -Name 'PowerRegistry' -Value 'Show-PowerTreeRegistry'

# Explicitly list files to import to avoid wildcard issues
# Order matters: Classes -> Constants/Enums -> Functions -> Public

# 1. Classes
$ClassesFile = Join-Path -Path $PSScriptRoot -ChildPath 'Private\Shared\DataModel\Classes.ps1'
if (Test-Path $ClassesFile) {
    try {
        . $ClassesFile
        Write-Verbose -Message "Imported class definitions from $ClassesFile"
    } catch {
        Write-Error "Failed to import class definitions from $ClassesFile`: $PSItem"
    }
} else {
    Write-Error "Critical: Classes file not found at $ClassesFile"
}

# 2. Private Functions (Explicit Order)
$PrivateFiles = @(
    # Configuration / Constants
    'Private\PowerTree\Configuration\Constants.ps1',
    'Private\Shared\Build-TreeLineStyle.ps1',

    # Helpers needed early
    'Private\PowerTree\Size\Conversion\Convert-ToBytes.ps1',
    'Private\PowerTree\Filtering\Format-FileExtensions.ps1',
    'Private\PowerTree\Size\Get-HumanReadableSize.ps1',
    'Private\PowerTree\Size\Get-SizeColor.ps1',
    'Private\PowerTree\Size\Get-FilesByFilteredSize.ps1',

    # Param Helpers
    'Private\PowerTree\Configuration\ParamHelpers\Build-ChildItemDirectoryParams.ps1',
    'Private\PowerTree\Configuration\ParamHelpers\Build-ChildItemFileParams.ps1',
    'Private\PowerTree\Configuration\ParamHelpers\Build-ExcludeDirectoryParams.ps1',
    'Private\PowerTree\Configuration\ParamHelpers\Build-FileSizeParam.ps1',

    # Output / Formatting
    'Private\PowerTree\Output\Build-OutputLine.ps1',
    'Private\PowerTree\Output\Get-TreeConfigurationData.ps1',
    'Private\PowerTree\Output\Get-TreeView.ps1',
    'Private\PowerTree\Output\Header\Get-HeaderTable.ps1',
    'Private\PowerTree\Output\Header\Write-HeaderOutput.ps1',
    'Private\PowerTree\Output\Help\Write-Examples.ps1',
    'Private\PowerTree\Output\Help\Write-Help.ps1',
    'Private\PowerTree\Output\Show-TreeStats.ps1',
    'Private\PowerTree\Output\ToFile\Invoke-OutputBuilder.ps1',
    'Private\PowerTree\Output\ToFile\Write-ToFile.ps1',
    'Private\PowerTree\Output\Write-OutputLine.ps1',

    # Sorting
    'Private\PowerTree\Sorting\Get-SortingMethod.ps1',

    # Registry support
    'Private\PowerTreeRegistry\Configuration\ParamHelpers\Get-Path.ps1',
    'Private\PowerTreeRegistry\Filtering\Get-RegistryItems.ps1',
    'Private\PowerTreeRegistry\Filtering\Set-LastItemFlag.ps1',
    'Private\PowerTreeRegistry\Filtering\Test-FilterMatch.ps1',
    'Private\PowerTreeRegistry\Output\Get-RegistryConfigurationData.ps1',
    'Private\PowerTreeRegistry\Output\Get-TreeRegistryView.ps1',
    'Private\PowerTreeRegistry\Output\Show-RegistryStats.ps1',
    'Private\PowerTreeRegistry\Output\ToFile\Invoke-OutputBuilderRegistry.ps1',
    'Private\PowerTreeRegistry\Sorting\Invoke-RegistryItemSorting.ps1',

    # Shared / Common
    'Private\Shared\DataModel\ClassLoader.ps1',
    'Private\Shared\JsonConfig\Get-ConfigPaths.ps1',
    'Private\Shared\JsonConfig\Get-DefaultConfig.ps1',
    'Private\Shared\JsonConfig\Get-SettingsFromJson.ps1',
    'Private\Shared\JsonConfig\Initialize-ConfigFile.ps1',
    'Private\Shared\Output\Add-DefaultExtension.ps1',
    'Private\Shared\Output\Convert-StatsInOutputFile.ps1',
    'Private\Shared\Output\Format-ExecutionTime.ps1',
    'Private\Shared\Output\Write-ConfigurationToHost.ps1'
)

foreach ($file in $PrivateFiles) {
    # Normalize path separators
    $relativePath = $file -replace '[\\/]', [System.IO.Path]::DirectorySeparatorChar
    $fullPath = Join-Path -Path $PSScriptRoot -ChildPath $relativePath
    if (Test-Path $fullPath) {
        try {
            . $fullPath
        } catch {
            Write-Error "Failed to import private function $file`: $PSItem"
        }
    } else {
        Write-Warning "Private function file not found: $file (Expected at: $fullPath)"
    }
}

# 3. Public Functions
$PublicFiles = @(
    'Public\Edit-PowerTreeConfig.ps1',
    'Public\Show-PowerTree.ps1',
    'Public\Show-PowerTreeRegistry.ps1'
)

foreach ($file in $PublicFiles) {
    # Normalize path separators
    $relativePath = $file -replace '[\\/]', [System.IO.Path]::DirectorySeparatorChar
    $fullPath = Join-Path -Path $PSScriptRoot -ChildPath $relativePath
    if (Test-Path $fullPath) {
        try {
            . $fullPath
        } catch {
            Write-Error "Failed to import public function $file`: $PSItem"
        }
    } else {
        Write-Warning "Public function file not found: $file (Expected at: $fullPath)"
    }
}

# Export public functions
Export-ModuleMember -Function 'Show-PowerTree', 'Edit-PowerTreeConfig', 'Show-PowerTreeRegistry'
Export-ModuleMember -Function 'Show-PowerTree', 'Edit-PowerTreeConfig', 'Show-PowerTreeRegistry' -Alias 'ptree', 'PowerTree', 'Start-PowerTree', 'Edit-PtreeConfig', 'Edit-Ptree', 'Edit-PowerTree', 'ptreer', 'PowerRegistry'
