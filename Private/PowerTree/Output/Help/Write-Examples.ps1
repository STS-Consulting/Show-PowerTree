
function Write-Examples {
    [CmdletBinding()]
    param()
    Write-Information -Information Action Continue -MessageData ''
    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)EXAMPLES:$(PSStyle.Reset)"
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)POWERFUL COMBINED SCENARIOS:$(PSStyle.Reset)"
    Write-Information -Information Action Continue -MessageData '  PowerTree -s -ss -Depth 5 -e .next,node_modules  Show file sizes sorted on file size, 5 levels deep, excluding .next and node_modules'
    Write-Information -Information Action Continue -MessageData '  PowerTree -p -Depth 3 -s -ss -desc               Prune empty folders, 3 levels deep, show sizes descending'
    Write-Information -Information Action Continue -MessageData '  PowerTree -e node_modules,bin -if ps1,md         Exclude specific dirs, show only PS1 and MD files'
    Write-Information -Information Action Continue -MessageData '  PowerTree -force -fsmi 1MB -smd                  Show hidden files, files larger than 1MB, sorted by modification date'
    Write-Information -Information Action Continue -MessageData '  PowerTree -s -dm -dmd                            Show sizes, modes, mod dates'
    Write-Information -Information Action Continue -MessageData '  PowerTree -o project_summary.txt -p              Save output to file, prune empty folders'
    Write-Information -Information Action Continue -MessageData '  PowerTree -ef dll,exe -fsma 10MB                 Exclude DLL and EXE, show files smaller than 10MB'
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)EXAMPLE PER CATEGORY:$(PSStyle.Reset)"
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)BASIC USAGE:$(PSStyle.Reset)"
    Write-Information -Information Action Continue -MessageData '  PowerTree                               Show all files and directories in current path'
    Write-Information -Information Action Continue -MessageData '  PowerTree C:\Projects\MyApp             Show files and directories in specified path'
    Write-Information -Information Action Continue -MessageData '  PowerTree -Depth 2                      Limit display to 2 directory levels'
    Write-Information -Information Action Continue -MessageData '  PowerTree -PruneEmptyFolders            Remove empty folders from the tree'
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)FILE & DIRECTORY FILTERING:$(PSStyle.Reset)"
    Write-Information -Information Action Continue -MessageData '  PowerTree -DirectoryOnly                Show only directories, no files'
    Write-Information -Information Action Continue -MessageData '  PowerTree -d                            Short form for DirectoryOnly'
    Write-Information -Information Action Continue -MessageData '  PowerTree -e node_modules,bin,obj       Exclude specified directories'
    Write-Information -Information Action Continue -MessageData '  PowerTree -if ps1,txt,log               Show only PowerShell, text, and log files'
    Write-Information -Information Action Continue -MessageData '  PowerTree -ef dll,exe,bin               Exclude DLL, executable, and binary files'
    Write-Information -Information Action Continue -MessageData '  PowerTree -force                        Show hidden files and directories'
    Write-Information -Information Action Continue -MessageData '  PowerTree -p                            Prune and remove empty folders'
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)DEPTH & FOLDER CONTROL:$(PSStyle.Reset)"
    Write-Information -Information Action Continue -MessageData '  PowerTree -Depth 3                      Show only up to 3 directory levels'
    Write-Information -Information Action Continue -MessageData '  PowerTree -Depth 1                      Show only first-level directories and files'
    Write-Information -Information Action Continue -MessageData '  PowerTree -p -Depth 2                   Prune empty folders, limit to 2 levels'
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)SIZE-BASED FILTERING:$(PSStyle.Reset)"
    Write-Information -Information Action Continue -MessageData '  PowerTree -fsmi 1MB                     Show only files larger than 1MB'
    Write-Information -Information Action Continue -MessageData '  PowerTree -fsma 500KB                   Show only files smaller than 500KB'
    Write-Information -Information Action Continue -MessageData '  PowerTree -fsmi 100KB -fsma 10MB        Show files between 100KB and 10MB in size'
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)SORTING OPTIONS:$(PSStyle.Reset)"
    Write-Information -Information Action Continue -MessageData '  PowerTree -ss                           Sort by file size (ascending)'
    Write-Information -Information Action Continue -MessageData '  PowerTree -Sort size                    Alternative syntax for sorting by size'
    Write-Information -Information Action Continue -MessageData '  PowerTree -ss -desc                     Sort by file size (descending)'
    Write-Information -Information Action Continue -MessageData '  PowerTree -smd                          Sort by last modification date'
    Write-Information -Information Action Continue -MessageData '  PowerTree -Sort md                      Alternative syntax for sorting by modification date'
    Write-Information -Information Action Continue -MessageData '  PowerTree -scd                          Sort by creation date'
    Write-Information -Information Action Continue -MessageData '  PowerTree -sla                          Sort by last access date'
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)DISPLAY OPTIONS:$(PSStyle.Reset)"
    Write-Information -Information Action Continue -MessageData '  PowerTree -s                            Display file sizes in human-readable format'
    Write-Information -Information Action Continue -MessageData '  PowerTree -dm                           Display file/folder attributes (d,a,r,h,s,l)'
    Write-Information -Information Action Continue -MessageData '  PowerTree -dmd                          Display modification dates'
    Write-Information -Information Action Continue -MessageData '  PowerTree -dcd                          Display creation dates'
    Write-Information -Information Action Continue -MessageData '  PowerTree -dla                          Display last access dates'
    Write-Information -Information Action Continue -MessageData '  PowerTree -s -dmd -dm                   Show sizes, modification dates, and attributes'
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)OUTPUT OPTIONS:$(PSStyle.Reset)"
    Write-Information -Information Action Continue -MessageData '  PowerTree -o tree_output                Save output to tree_output.txt'
    Write-Information -Information Action Continue -MessageData '  PowerTree -o C:\temp\tree.md            Save output to specified file path'
    Write-Information -Information Action Continue -MessageData ''

    Write-Information -Information Action Continue -MessageData "$(PSStyle.Formatting.Verbose)ADVANCED COMBINED EXAMPLES:$(PSStyle.Reset)"
    Write-Information -Information Action Continue -MessageData '  PowerTree -s -ss -desc -e node_modules  Show sizes, sort by size (descending), exclude node_modules'
    Write-Information -Information Action Continue -MessageData '  PowerTree -if ps1,log -dmd              Show only PS1 and log files with modification dates'
    Write-Information -Information Action Continue -MessageData '  PowerTree -s -ss -desc -fsmi 10MB       Find large files (>10MB), sort by size descending'
    Write-Information -Information Action Continue -MessageData '  PowerTree -p -Depth 2 -s                Prune empty folders, show 2 levels with sizes'
    Write-Information -Information Action Continue -MessageData ''
}
