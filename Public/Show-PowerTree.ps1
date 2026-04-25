function Show-PowerTree {
    <#
    .SYNOPSIS
        Displays a directory tree with advanced filtering and sorting options.

    .DESCRIPTION
        The Show-PowerTree cmdlet (alias ptree) generates a visual representation of a directory structure.
        It supports filtering by file size, extensions, and dates, as well as sorting by various criteria.
        It can also export the output to a file and display execution statistics.

    .PARAMETER LiteralPath
        The path to the directory to visualize. Defaults to the current directory.

    .PARAMETER Depth
        The maximum depth of the tree to display. Defaults to -1 (no limit) or the value in config.

    .PARAMETER Examples
        Displays usage examples.

    .PARAMETER PruneEmptyFolders
        If set, empty folders (or folders that become empty after filtering) are not displayed.

    .PARAMETER DisplayAll
        Enables display of all file attributes: CreationDate, LastAccessDate, ModificationDate, Size, and Mode.

    .PARAMETER DisplayMode
        Displays the file/directory mode (attributes).

    .PARAMETER DisplaySize
        Displays the size of files and directories.

    .PARAMETER DisplayModificationDate
        Displays the last modification date.

    .PARAMETER DisplayCreationDate
        Displays the creation date.

    .PARAMETER DisplayLastAccessDate
        Displays the last access date.

    .PARAMETER DirectoryOnly
        Displays only directories, excluding files.

    .PARAMETER ExcludeDirectories
        An array of directory names or patterns to exclude.

    .PARAMETER Sort
        Specifies the sorting criteria: 'size', 'name', 'md', 'cd', 'la'.

    .PARAMETER SortByModificationDate
        Sorts items by modification date.

    .PARAMETER SortByCreationDate
        Sorts items by creation date.

    .PARAMETER SortByLastAccessDate
        Sorts items by last access date.

    .PARAMETER SortBySize
        Sorts items by size.

    .PARAMETER SortByName
        Sorts items by name.

    .PARAMETER Descending
        Sorts items in descending order.

    .PARAMETER FileSizeMinimum
        Excludes files smaller than the specified size (e.g., '1kb', '10mb').

    .PARAMETER FileSizeMaximum
        Excludes files larger than the specified size.

    .PARAMETER FileSizeFilter
        Alias for FileSizeFilter (seems duplicate purpose, maybe legacy).

    .PARAMETER ExcludeExtensions
        Excludes files with specified extensions.

    .PARAMETER IncludeExtensions
        Includes only files with specified extensions.

    .PARAMETER ShowHiddenFiles
        Forces display of hidden files and directories.

    .PARAMETER OutFile
        Writes the output to the specified file.

    .EXAMPLE
        Show-PowerTree -Path "C:\Projects" -Depth 2
        Displays the tree structure of C:\Projects up to 2 levels deep.

    .EXAMPLE
        Show-PowerTree -DisplaySize -SortBySize -Descending
        Displays the current directory tree showing sizes, sorted by size descending.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$LiteralPath = '.',

        [Parameter()]
        [Alias('l', 'level')]
        [int]$Depth = -1,

        [Parameter()]
        [Alias('ex', 'example')]
        [switch]$Examples,

        [Parameter()]
        [Alias('prune', 'p')]
        [switch]$PruneEmptyFolders,

        [Parameter()]
        [Alias('da')]
        [switch]$DisplayAll,

        [Parameter()]
        [Alias('dm', 'm')]
        [switch]$DisplayMode,

        [Parameter()]
        [Alias('s', 'size')]
        [switch]$DisplaySize,

        [Parameter()]
        [Alias('dmd')]
        [switch]$DisplayModificationDate,

        [Parameter()]
        [Alias('dcd')]
        [switch]$DisplayCreationDate,

        [Parameter()]
        [Alias('dla')]
        [switch]$DisplayLastAccessDate,

        [Parameter()]
        [Alias('d', 'dir')]
        [switch]$DirectoryOnly,

        [Parameter()]
        [Alias('e', 'exclude')]
        [string[]]$ExcludeDirectories = @(),

        [Parameter()]
        [ValidateSet('size', 'name', 'md', 'cd', 'la')]
        [string]$Sort,

        [Parameter()]
        [Alias('smd')]
        [switch]$SortByModificationDate,

        [Parameter()]
        [Alias('scd')]
        [switch]$SortByCreationDate,

        [Parameter()]
        [Alias('sla', 'sld')]
        [switch]$SortByLastAccessDate,

        [Parameter()]
        [Alias('ss')]
        [switch]$SortBySize,

        [Parameter()]
        [Alias('sn')]
        [switch]$SortByName,

        [Parameter()]
        [Alias('des', 'desc')]
        [switch]$Descending,

        [Parameter()]
        [ValidateScript({
                # Validate format of lower bound size filter
                $_ -match '^\d+(?:\.\d+)?(b|kb|mb|gb|tb)?$'
            })]
        [Alias('fsmi')]
        [string]$FileSizeMinimum = '-1kb',

        [Parameter()]
        [ValidateScript({
                # Validate format of upper bound size filter
                $_ -match '^\d+(?:\.\d+)?(b|kb|mb|gb|tb)?$'
            })]
        [Alias('fsma')]
        [string]$FileSizeMaximum = '-1kb',

        [Alias('fs', 'filesize')]
        [string]$FileSizeFilter,

        [Parameter()]
        [Alias('ef')]
        [string[]]$ExcludeExtensions = @(),

        [Parameter()]
        [Alias('if')]
        [string[]]$IncludeExtensions = @(),

        [Parameter()]
        [Alias('force')]
        [switch]$ShowHiddenFiles,

        [Parameter()]
        [Alias('o', 'of')]
        [string]$OutFile
    )

    if ($Examples) {
        Write-Examples
        return
    }

    if ($DisplayAll) {
        $DisplayCreationDate = $true
        $DisplayLastAccessDate = $true
        $DisplayModificationDate = $true
        $DisplaySize = $true
        $DisplayMode = $true
    }

    $treeStats = New-Object TreeStats

    # Ensure config file exists before loading settings
    Initialize-ConfigFile

    $jsonSettings = Get-SettingsFromJson -Mode 'FileSystem'

    $treeConfig = New-Object TreeConfig
    $treeConfig.Path = $LiteralPath
    $treeConfig.LineStyle = Build-TreeLineStyle -Style $jsonSettings.LineStyle
    $treeConfig.DirectoryOnly = $DirectoryOnly
    $treeConfig.ExcludeDirectories = Build-ExcludedDirectoryParams -CommandLineExcludedDir $ExcludeDirectories `
        -Settings $jsonSettings
    $treeConfig.SortBy = Get-SortingMethod -SortBySize $SortBySize `
        -SortByName $SortByName `
        -SortByCreationDate $SortByCreationDate `
        -SortByLastAccessDate $SortByLastAccessDate `
        -SortByModificationDate $SortByModificationDate `
        -DefaultSort $jsonSettings.Sorting.By `
        -Sort $Sort
    $treeConfig.SortDescending = $Descending
    $treeConfig.SortFolders = $jsonSettings.Sorting.SortFolders
    $treeConfig.HeaderTable = Get-HeaderTable -DisplayCreationDate $DisplayCreationDate `
        -DisplayLastAccessDate $DisplayLastAccessDate `
        -DisplayModificationDate $DisplayModificationDate `
        -DisplaySize $DisplaySize `
        -DisplayMode $DisplayMode `
        -LineStyle $treeConfig.LineStyle

    $treeConfig.ShowConnectorLines = $jsonSettings.ShowConnectorLines
    $treeConfig.ShowHiddenFiles = $ShowHiddenFiles
    $treeConfig.MaxDepth = if ($Depth -ne -1) { $Depth } else { $jsonSettings.MaxDepth }
    $treeConfig.FileSizeBounds = Build-FileSizeParams -CommandLineMaxSize $FileSizeMaximum `
        -CommandlineMinSize $FileSizeMinimum `
        -SettingsLineMaxSize $jsonSettings.Files.FileSizeMaximum `
        -SettingsLineMinSize $jsonSettings.Files.FileSizeMinimum
    $treeConfig.OutFile = Add-DefaultExtension -FilePath $OutFile `
        -IsRegistry $false

    $treeConfig.PruneEmptyFolders = $PruneEmptyFolders
    $treeConfig.HumanReadableSizes = $jsonSettings.HumanReadableSizes

    $outputBuilder = Invoke-OutputBuilder -TreeConfig $treeConfig -ShowExecutionStats $jsonSettings.ShowExecutionStats -ShowConfigurations $jsonSettings.ShowConfigurations

    # Main entry point
    $executionResultTime = Measure-Command {
        try {
            if (-not (Test-Path $LiteralPath)) {
                throw "Cannot find path '$LiteralPath'"
            }

            $ChildItemDirectoryParams = Build-ChildItemDirectoryParams $ShowHiddenFiles
            $ChildItemFileParams = Build-ChildItemFileParams -ShowHiddenFiles $ShowHiddenFiles `
                -CommandLineIncludeExt $IncludeExtensions `
                -CommandLineExcludeExt $ExcludeExtensions `
                -FileSettings $jsonSettings.Files

            if ($jsonSettings.ShowConfigurations) {
                Write-ConfigurationToHost -Config $treeConfig
            }

            Write-HeaderToOutput -HeaderTable $treeConfig.HeaderTable `
                -OutputBuilder $outputBuilder `
                -LineStyle $treeConfig.LineStyle

            Get-TreeView -TreeConfig $treeConfig `
                -TreeStats $treeStats `
                -ChildItemDirectoryParams $ChildItemDirectoryParams `
                -ChildItemFileParams $ChildItemFileParams `
                -OutputBuilder $outputBuilder

        } catch {
            Write-Error "Details: $($_.Exception.Message)"
            Write-Error "Location: $($_.InvocationInfo.ScriptLineNumber), $($_.InvocationInfo.PositionMessage)"
            Write-Verbose "Exception details: $($PSItem | Format-List * -Force | Out-String)"
        }
    }

    if ($jsonSettings.ShowExecutionStats) {
        Show-TreeStats -TreeStats $treeStats -ExecutionTime $executionResultTime -OutputBuilder $outputBuilder -LineStyle $treeConfig.LineStyle -DisplaySize $DisplaySize
    }

    if ($null -ne $outputBuilder) {
        $outputBuilder.ToString() | Write-ToFile -FilePath $treeConfig.OutFile -OpenOutputFileOnFinish $jsonSettings.OpenOutputFileOnFinish

        $fullOutputPath = Resolve-Path $treeConfig.OutFile -ErrorAction SilentlyContinue
        if ($null -eq $fullOutputPath) {
            $fullOutputPath = $treeConfig.OutFile
        }

        Write-Information -MessageData ' ' -InformationAction Continue
        Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Output saved to: $($fullOutputPath)$($PSStyle.Reset)" -InformationAction Continue
    }

    Write-Information -MessageData ' ' -InformationAction Continue
}
