function Write-Help {
    [CmdletBinding()]
    param()
    Write-Information -InformationAction Continue -MessageData ''
    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)BASIC OPTIONS:"$(PSStyle.Reset)
    Write-Information -Information Action Continue -MessageData '  -LiteralPath, -p <LiteralPath>                    Specify path to search (default: current directory)'
    Write-Information -Information Action Continue -MessageData '  -Verbose                            Show verbose output'
    Write-Information -Information Action Continue -MessageData '  -ShowHiddenFiles, -force            Show hidden files and directories'
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)HELP OPTIONS:"$(PSStyle.Reset)
    Write-Information -Information Action Continue -MessageData '  -Help, -h                           You are here :)'
    Write-Information -Information Action Continue -MessageData '  -Version, -v                        Print current version'
    Write-Information -Information Action Continue -MessageData '  -ModuleInfo, -i, -info              Print PowerTree information'
    Write-Information -Information Action Continue -MessageData '  -CheckForUpdates, -check            Check for available updates'
    Write-Information -Information Action Continue -MessageData '  -Examples, -ex, -example            Print examples'
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)FOLDER FILTERING"$(PSStyle.Reset)
    Write-Information -Information Action Continue -MessageData '  -Depth -l -level <number>                   Limit display to specified number of directory levels'
    Write-Information -Information Action Continue -MessageData '  -ExcludeDirectories, -e, -exclude           Exclude specified directory(s)'
    Write-Information -Information Action Continue -MessageData '  -PruneEmptyFolders, -p                      Exclude empty folders from output, also excludes empty folders caused by filters'
    Write-Information -Information Action Continue -MessageData '  -DirectoryOnly, -d                          Display only directories (no files)'
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)FILE FILTERING:"$(PSStyle.Reset)
    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Warning)   Multiple files should be comma separated"$(PSStyle.Reset)
    Write-Information -Information Action Continue -MessageData '  -IncludeExtensions, -if                     Include only files with specified extension(s)'
    Write-Information -Information Action Continue -MessageData '  -ExcludeExtensions, -ef                     Exclude files with specified extension(s)'
    Write-Information -Information Action Continue -MessageData '  -FileSizeMinimum -fsmi <size format>        Filters out all sizes below this size'
    Write-Information -Information Action Continue -MessageData '  -FileSizeMaximum -fsma <size format>        Filters out all sizes above this size'
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)DISPLAY OPTIONS:"$(PSStyle.Reset)
    Write-Information -Information Action Continue -MessageData '  -OutFile, -o, -of <filepath>                Save output to specified file path (defaults to .txt if no extension specified)'
    Write-Information -Information Action Continue -MessageData '  -DisplaySize, -s, -size                     Display file sizes in human-readable format'
    Write-Information -Information Action Continue -MessageData '  -DisplayMode, -m, -dm                       Display mode of in file/folder (d - dir, a - archive, r - Read-only, h - hidden, s - system, l - reparse point, symlink etc)'
    Write-Information -Information Action Continue -MessageData '  -DisplayModificationDate, -dmd,             Display modification date'
    Write-Information -Information Action Continue -MessageData '  -DisplayCreationDate, -dcd,                 Display creation date'
    Write-Information -Information Action Continue -MessageData '  -DisplayLastAccessDate, -dla,               Display last access date'
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)SORTING OPTIONS:"$(PSStyle.Reset)
    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Warning)   You can use either the consolidated -Sort parameter OR individual sort switches:"$(PSStyle.Reset)
    Write-Information -Information Action Continue -MessageData '  -SortBySize, -ss, -Sort size                Sort by size'
    Write-Information -Information Action Continue -MessageData '  -SortByName, -sn, -Sort name                Sort alphabetically by name (default)'
    Write-Information -Information Action Continue -MessageData '  -SortByModificationDate, -smd, -Sort md     Sort by last modified date'
    Write-Information -Information Action Continue -MessageData '  -SortByCreationDate, -scd, -Sort cd         Sort by creation date'
    Write-Information -Information Action Continue -MessageData '  -SortByLastAccessDate, -sla, -Sort la       Sort by last access date'
    Write-Information -Information Action Continue -MessageData '  -Descending, -des, -desc                    Sort in Descending order'
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)EXAMPLES:"$(PSStyle.Reset)
    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Warning)  PowerTree -Examples for more examples"$(PSStyle.Reset)
    Write-Information -Information Action Continue -MessageData '  PowerTree                               Show all files and directories in current path'
    Write-Information -Information Action Continue -MessageData '  PowerTree -Sort size                    Sort by size'
    Write-Information -Information Action Continue -MessageData '  PowerTree -ss -desc                     Sort by size (Descending)'
    Write-Information -Information Action Continue -MessageData '  PowerTree -DisplayDate md               Show modification dates for files'
    Write-Information -Information Action Continue -MessageData '  PowerTree -e node_modules,bin           Exclude node_modules and bin directories'
    Write-Information -Information Action Continue -MessageData '  PowerTree -if ps1,txt                   Show only PowerShell scripts and text files'
    Write-Information -Information Action Continue -MessageData '  PowerTree -s -ss                        Show and sort by file sizes'
    Write-Information -Information Action Continue -MessageData '  PowerTree -o C:\temp\output.txt         Save output to specified file'
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData ''
    Write-CheckForUpdates
}
