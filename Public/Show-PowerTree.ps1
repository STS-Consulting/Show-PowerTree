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
        The maximum depth of the tree to display. Defaults to -1 (no limit) or the value in the configuration file.

    .PARAMETER PruneEmptyFolders
        If set, empty folders (or folders that become empty after filtering) are not displayed.

    .PARAMETER DisplayAll
        Enables display of all file attributes: CreationDate, LastAccessDate, ModificationDate, Size, and Mode.

    .PARAMETER DisplayMode
        Displays the file/directory mode (attributes).

    .PARAMETER DisplaySize
        Displays the size of Files and Directories.

    .PARAMETER DisplayModificationDate
        Displays the Last Modification Date.

    .PARAMETER DisplayCreationDate
        Displays the Creation Date.

    .PARAMETER DisplayLastAccessDate
        Displays the Last Access Date.

    .PARAMETER DirectoryOnly
        Displays only Directories, excluding Files.

    .PARAMETER ExcludeDirectories
        An array of Directory Names or patterns to exclude.

    .PARAMETER Sort
        Specifies the sorting criteria: 'Size', 'Name', 'ModificationDate', 'CreationDate', 'LastAccessDate'.

    .PARAMETER SortByModificationDate
        Sorts items by Last Modification Date.

    .PARAMETER SortByCreationDate
        Sorts items by Creation Date.

    .PARAMETER SortByLastAccessDate
        Sorts items by Last Access Date.

    .PARAMETER SortBySize
        Sorts items by Size.

    .PARAMETER SortByName
        Sorts items by Name.

    .PARAMETER Descending
        Sorts items in descending order.

    .PARAMETER FileSizeMinimum
        Excludes Files smaller than the specified size

    .PARAMETER FileSizeMaximum
        Excludes Files larger than the specified size.

    .PARAMETER FileSizeFilter
        Alias for FileSizeFilter. # (seems duplicate purpose, maybe legacy).

    .PARAMETER ExcludeExtensions
        Excludes files with specified extensions.

    .PARAMETER IncludeExtensions
        Includes only files with specified extensions.

    .PARAMETER ShowHiddenFiles
        Forces display of Hidden Files and Directories.

    .PARAMETER OutFile
        Writes the output to the specified file.

    .EXAMPLE
        Show-PowerTree

        Show all Files and Directories in current path.

    .EXAMPLE
        Show-PowerTree C:\Projects\MyApp

        Show Files and Directories in specified path.

    .EXAMPLE
        Show-PowerTree -Depth 2

        Limit display to 2 Directory levels.

    .EXAMPLE
        Show-PowerTree -PruneEmptyFolders

        Remove empty folders from the tree.

    .EXAMPLE
        Show-PowerTree -DirectoryOnly

        Show only directories, no files.

    .EXAMPLE
        Show-PowerTree -ExcludeDirectories node_modules,bin,obj

        Exclude specified directories.

    .EXAMPLE
        Show-PowerTree -IncludeExtensions md,markdown,ipynb

        Show only Markdown and Jupyter Notebook files.

    .EXAMPLE
        Show-PowerTree -ExcludeExtensions dll,exe,bin,com,bat,cmd

        Exclude DLL, executable, binary Files.

    .EXAMPLE
        Show-PowerTree -ShowHiddenFiles

        Show hidden Files and Directories.

    .EXAMPLE
        Show-PowerTree -FileSizeMinimum 1MB

        Show only Files larger than 1MB.

    .EXAMPLE
        Show-PowerTree -FileSizeMaximum 500KB

        Show only Files smaller than 500KB.

    .EXAMPLE
        Show-PowerTree -SortBySize

        Sort by File Size (ascending).

    .EXAMPLE
        Show-PowerTree -SortBySize -Descending

        Sort by File Size (descending).

    .EXAMPLE
        Show-PowerTree -SortByModificationDate

        Sort by Last Modification Date.

    .EXAMPLE
        Show-PowerTree -DisplaySize

        Display File Sizes in human-readable format.

    .EXAMPLE
        Show-PowerTree -DisplayModificationDate

        Display modification dates.

    .EXAMPLE
        Show-PowerTree -OutFile tree_output.txt

        Save output to tree_output.txt.

    .EXAMPLE
        Show-PowerTree -DisplaySize -SortBySize -Depth 5 -ExcludeDirectories .next,node_modules

        Show file sizes sorted on file size, 5 levels deep, excluding .next and node_modules.

    .EXAMPLE
        Show-PowerTree -PruneEmptyFolders -Depth 3 -DisplaySize -SortBySize -Descending

        Prune empty folders, 3 levels deep, show sizes descending.

    .EXAMPLE
        Show-PowerTree -ExcludeDirectories extensions -IncludeExtensions ps1, psm1, psd1, pssc, psrc, psc1, ps1xml, cdxml

        Exclude specific dirs, show only PowerShell files.

    .EXAMPLE
        Show-PowerTree -ShowHiddenFiles -FileSizeMinimum 1MB -SortByModificationDate

        Show hidden files, files larger than 1MB, sorted by modification date.

    .EXAMPLE
        Show-PowerTree -DisplaySize -DisplayMode -DisplayModificationDate

        Show sizes, modes, mod dates.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$LiteralPath = '.',

        [Parameter()]
        [Alias('l', 'level')]
        [int]$Depth = -1,

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
        [ValidateSet('size', 'name', 'ModificationDate', 'CreationDate', 'LastAccessDate', 'md', 'cd', 'la')]
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
                $PSItem -match '^\d+(?:\.\d+)?(b|kb|mb|gb|tb)?$'
            })]
        [Alias('fsmi')]
        [string]$FileSizeMinimum = '-1kb',

        [Parameter()]
        [ValidateScript({
                # Validate format of upper bound size filter
                $PSItem -match '^\d+(?:\.\d+)?(b|kb|mb|gb|tb)?$'
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
        [Alias('forceDirs', 'HiddenFolders')]
        [switch]$ShowHiddenFolders,

        [Parameter()]
        [Alias('o', 'of')]
        [string]$OutFile
    )



    if ($DisplayAll) {
        $DisplayCreationDate = $true
        $DisplayLastAccessDate = $true
        $DisplayModificationDate = $true
        $DisplaySize = $true
        $DisplayMode = $true
    }

    $treeStats = New-Object TreeStats

    # Ensure configuration file exists before loading settings
    Initialize-ConfigurationFile

    $jsonSettings = Get-SettingsFromJson -Mode 'FileSystem'

    $treeConfiguration = New-Object TreeConfig
    $treeConfiguration.Path = $LiteralPath
    $treeConfiguration.LineStyle = Build-TreeLineStyle -Style $jsonSettings.LineStyle
    $treeConfiguration.DirectoryOnly = $DirectoryOnly
    $excludedDirParameters = @{
        CommandLineExcludedDirectory = $ExcludeDirectories
        Settings                     = $jsonSettings
    }
    $treeConfiguration.ExcludeDirectories = Build-ExcludedDirectoryParameters @excludedDirParameters
    $sortingParameters = @{
        SortBySize             = $SortBySize
        SortByName             = $SortByName
        SortByCreationDate     = $SortByCreationDate
        SortByLastAccessDate   = $SortByLastAccessDate
        SortByModificationDate = $SortByModificationDate
        DefaultSort            = $jsonSettings.Sorting.By
        Sort                   = $Sort
    }
    $treeConfiguration.SortBy = Get-SortingMethod @sortingParameters
    $treeConfiguration.SortDescending = $Descending
    $treeConfiguration.SortFolders = $jsonSettings.Sorting.SortFolders
    $headerTableParameters = @{
        DisplayCreationDate     = $DisplayCreationDate
        DisplayLastAccessDate   = $DisplayLastAccessDate
        DisplayModificationDate = $DisplayModificationDate
        DisplaySize             = $DisplaySize
        DisplayMode             = $DisplayMode
        LineStyle               = $treeConfiguration.LineStyle
    }
    $treeConfiguration.HeaderTable = Get-HeaderTable @headerTableParameters

    $treeConfiguration.ShowConnectorLines = $jsonSettings.ShowConnectorLines
    $treeConfiguration.ShowHiddenFiles = $ShowHiddenFiles
    $treeConfiguration.MaximumDepth = if ($Depth -ne -1) { $Depth } else { $jsonSettings.MaximumDepth }
    $fileSizeParameters = @{
        CommandLineMaximumSize  = $FileSizeMaximum
        CommandlineMinimumSize  = $FileSizeMinimum
        SettingsLineMaximumSize = $jsonSettings.Files.FileSizeMaximum
        SettingsLineMinimumSize = $jsonSettings.Files.FileSizeMinimum
    }
    $treeConfiguration.FileSizeBounds = Build-FileSizeParameters @fileSizeParameters
    $treeConfiguration.OutFile = Add-DefaultExtension -FilePath $OutFile -IsRegistry $false

    $treeConfiguration.PruneEmptyFolders = $PruneEmptyFolders
    $treeConfiguration.HumanReadableSizes = $jsonSettings.HumanReadableSizes

    $outputBuilder = Invoke-OutputBuilder -TreeConfiguration $treeConfiguration -ShowExecutionStats $jsonSettings.ShowExecutionStats -ShowConfigurations $jsonSettings.ShowConfigurations

    # Main entry point
    $executionResultTime = Measure-Command {
        try {
            if (-not (Test-Path $LiteralPath)) {
                throw "Cannot find path '$LiteralPath'"
            }

            $ChildItemDirectoryParameters = Build-ChildItemDirectoryParameters -ShowHiddenFiles $ShowHiddenFiles -ShowHiddenFolders $ShowHiddenFolders
            $childItemFileParameters = @{
                ShowHiddenFiles             = $ShowHiddenFiles
                CommandLineIncludeExtension = $IncludeExtensions
                CommandLineExcludeExtension = $ExcludeExtensions
                FileSettings                = $jsonSettings.Files
            }
            $ChildItemFileParameters = Build-ChildItemFileParameters @childItemFileParameters

            if ($jsonSettings.ShowConfigurations) {
                Write-ConfigurationToHost -Configuration $treeConfiguration
            }

            $headerOutputParameters = @{
                HeaderTable   = $treeConfiguration.HeaderTable
                OutputBuilder = $outputBuilder
                LineStyle     = $treeConfiguration.LineStyle
            }
            Write-HeaderToOutput @headerOutputParameters

            $treeViewParameters = @{
                TreeConfiguration            = $treeConfiguration
                TreeStats                    = $treeStats
                ChildItemDirectoryParameters = $ChildItemDirectoryParameters
                ChildItemFileParameters      = $ChildItemFileParameters
                OutputBuilder                = $outputBuilder
            }
            Get-TreeView @treeViewParameters

        } catch {
            Write-Error "Details: $($PSItem.Exception.Message)"
            Write-Error "Location: $($PSItem.InvocationInfo.ScriptLineNumber), $($PSItem.InvocationInfo.PositionMessage)"
            Write-Verbose -Message "Exception details: $($PSItem | Format-List * -Force | Out-String)"
        }
    }

    if ($jsonSettings.ShowExecutionStats) {
        Show-TreeStats -TreeStats $treeStats -ExecutionTime $executionResultTime -OutputBuilder $outputBuilder -LineStyle $treeConfiguration.LineStyle -DisplaySize $DisplaySize
    }

    if ($null -ne $outputBuilder) {
        $outputBuilder.ToString() | Write-ToFile -FilePath $treeConfiguration.OutFile -OpenOutputFileOnFinish $jsonSettings.OpenOutputFileOnFinish

        $fullOutputPath = Resolve-Path $treeConfiguration.OutFile -ErrorAction SilentlyContinue
        if ($null -eq $fullOutputPath) {
            $fullOutputPath = $treeConfiguration.OutFile
        }

        Write-Information -MessageData ' ' -InformationAction Continue
        Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Output saved to: $($fullOutputPath)$($PSStyle.Reset)" -InformationAction Continue
    }

    Write-Information -MessageData ' ' -InformationAction Continue
}
