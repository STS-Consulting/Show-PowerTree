class TreeConfig {
    [string]$Path
    [bool]$DirectoryOnly
    [string[]]$ExcludeDirectories
    [string]$SortBy
    [bool]$SortDescending
    [bool]$SortFolders
    [hashtable]$ChildItemDirectoryParameters
    [hashtable]$ChildItemFileParameters
    [hashtable]$HeaderTable
    [bool]$ShowConnectorLines
    [bool]$ShowHiddenFiles
    [int]$MaximumDepth
    [hashtable]$FileSizeBounds
    [string]$OutFile
    [bool]$PruneEmptyFolders
    [hashtable]$LineStyle
    [bool]$HumanReadableSizes
}

class TreeRegistryConfig {
    [string]$Path
    [bool]$NoValues
    [string[]]$Exclude
    [string[]]$Include
    [int]$MaximumDepth
    [hashtable]$LineStyle
    [bool]$DisplayItemCounts
    [bool]$SortValuesByType
    [bool]$SortDescending
    [bool]$UseRegistryDataTypes
    [string]$OutFile
}

class RegistryStats {
    [int]$KeysProcessed = 0
    [int]$ValuesProcessed = 0
    [int]$MaximumDepthReached = 0

    [void] UpdateDepth([int]$depth) {
        if ($depth -gt $this.MaximumDepthReached) {
            $this.MaximumDepthReached = $depth
        }
    }
}

class TreeStats {
    [long]$FilesPrinted = 0
    [long]$FoldersPrinted = 0
    [int]$MaximumDepth = 0
    [long]$TotalSize = 0
    [System.IO.FileInfo]$LargestFile = $null
    [string]$LargestFolder = ''
    [long]$LargestFolderSize = 0

    [void] AddFile([System.IO.FileInfo]$file) {
        $this.FilesPrinted++
        $this.TotalSize += $file.Length

        # Track largest file
        if ($null -eq $this.LargestFile -or $file.Length -gt $this.LargestFile.Length) {
            $this.LargestFile = $file
        }
    }

    [void] UpdateLargestFolder([string]$folderPath, [long]$folderSize) {
        if ($folderSize -gt $this.LargestFolderSize) {
            $this.LargestFolder = $folderPath
            $this.LargestFolderSize = $folderSize
        }
    }

    [void] UpdateMaximumDepth([int]$depth) {
        if ($depth -gt $this.MaximumDepth) {
            $this.MaximumDepth = $depth
        }
    }
}
