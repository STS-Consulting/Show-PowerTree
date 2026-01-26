function Get-TreeView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [TreeConfig]$TreeConfiguration,
        [Parameter(Mandatory = $true)]
        [hashtable]$ChildItemDirectoryParameters,
        [Parameter(Mandatory = $true)]
        [hashtable]$ChildItemFileParameters,
        [Parameter(Mandatory = $true)]
        [TreeStats]$TreeStats,
        [string]$CurrentPath = $TreeConfiguration.Path,
        [string]$TreeIndent = '',
        [bool]$Last = $false,
        [bool]$IsRoot = $true,
        [int]$CurrentDepth = 0,
        [Parameter(Mandatory = $false)]
        [System.Text.StringBuilder]$OutputBuilder = $null,
        [Parameter(Mandatory = $false)]
        [switch]$IsEmptyCheck = $false
    )

    if ($TreeConfiguration.MaximumDepth -ne -1 -and $CurrentDepth -ge $TreeConfiguration.MaximumDepth) {
        return $false
    }

    if ($IsRoot) {
        $TreeStats.MaximumDepth += 1
    }

    $TreeStats.UpdateMaximumDepth($CurrentDepth)

    # Get directories filtering out excluded directories
    $dirItems = Get-ChildItem @ChildItemDirectoryParameters -LiteralPath $CurrentPath
    $directories = if ($null -ne $dirItems -and $dirItems.Count -gt 0) {
        $filteredDirs = $dirItems | Where-Object {
            $TreeConfiguration.ExcludeDirectories.Count -eq 0 -or $TreeConfiguration.ExcludeDirectories -notcontains $PSItem.Name
        }

        if ($null -ne $filteredDirs -and $filteredDirs.Count -gt 0) {
            if ($TreeConfiguration.SortFolders) {
                Group-Items -Items $filteredDirs -SortBy $TreeConfiguration.SortBy -SortDescending $TreeConfiguration.SortDescending
            } else {
                $filteredDirs
            }
        } else {
            @()
        }
    } else {
        @()
    }

    $files = if (-not $TreeConfiguration.DirectoryOnly) {
        $fileList = Get-ChildItem -LiteralPath $CurrentPath @ChildItemFileParameters

        if ($null -ne $fileList -and $fileList.Count -gt 0) {
            $filteredBySize = Get-FilesByFilteredSize $fileList -FileSizeBounds $TreeConfiguration.FileSizeBounds
            Group-Items -Items $filteredBySize -SortBy $TreeConfiguration.SortBy -SortDescending $TreeConfiguration.SortDescending
        } else {
            @()
        }
    } else {
        @()
    }

    # Return true immediately if this is just an empty check and we have files
    if ($IsEmptyCheck -and -not $TreeConfiguration.DirectoryOnly -and $files.Count -gt 0) {
        return $true
    }

    # If this is just an empty check and we have no files but we do have directories,
    # we need to check if any of those directories are non-empty after filtering
    if ($IsEmptyCheck -and $files.Count -eq 0 -and $directories.Count -gt 0) {
        foreach ($directory in $directories) {
            $treeViewParameters = @{
                TreeConfiguration            = $TreeConfiguration
                TreeStats                    = $TreeStats
                ChildItemDirectoryParameters = $ChildItemDirectoryParameters
                ChildItemFileParameters      = $ChildItemFileParameters
                CurrentPath                  = $directory.FullName
                TreeIndent                   = ''
                Last                         = $false
                IsRoot                       = $false
                CurrentDepth                 = ($CurrentDepth + 1)
                OutputBuilder                = $null
                IsEmptyCheck                 = $true
            }
            $directoryHasContent = Get-TreeView @treeViewParameters

            if ($directoryHasContent) {
                return $true
            }
        }
        # If we get here, all subdirectories were empty or filtered out
        return $false
    }

    # For empty check with no files and no directories, return false
    if ($IsEmptyCheck -and $files.Count -eq 0 -and $directories.Count -eq 0) {
        return $false
    }

    # Initialize the hasVisibleContent variable - true if we have visible files
    $hasVisibleContent = (-not $TreeConfiguration.DirectoryOnly -and $files.Count -gt 0)

    # Filter directories for pruning if enabled
    $visibleDirectories = @()
    if ($directories.Count -gt 0) {
        foreach ($directory in $directories) {
            $skipDirectory = $false
            if ($TreeConfiguration.PruneEmptyFolders) {
                $treeViewParameters = @{
                    TreeConfiguration            = $TreeConfiguration
                    TreeStats                    = $TreeStats
                    ChildItemDirectoryParameters = $ChildItemDirectoryParameters
                    ChildItemFileParameters      = $ChildItemFileParameters
                    CurrentPath                  = $directory.FullName
                    TreeIndent                   = ''
                    Last                         = $false
                    IsRoot                       = $false
                    CurrentDepth                 = ($CurrentDepth + 1)
                    OutputBuilder                = $null
                    IsEmptyCheck                 = $true
                }
                $directoryHasContent = Get-TreeView @treeViewParameters

                if (-not $directoryHasContent) {
                    $skipDirectory = $true
                }
            }

            if (-not $skipDirectory) {
                $visibleDirectories += $directory
                $hasVisibleContent = $true
            }
        }
    }

    # Calculate total items and process them in the correct order
    $totalItems = $files.Count + $visibleDirectories.Count
    $currentItemIndex = 0

    # Process files first (they appear before directories in tree output)
    if (-not $TreeConfiguration.DirectoryOnly -and $files.Count -gt 0) {
        foreach ($file in $files) {
            $currentItemIndex++
            $isLastItem = ($currentItemIndex -eq $totalItems)

            # Build the tree prefix for files
            $treeBranch = if ($isLastItem) { $TreeConfiguration.lineStyle.LastBranch } else { $TreeConfiguration.lineStyle.Branch }
            $treePrefix = if ($IsRoot) { $treeBranch } else { "$TreeIndent$treeBranch" }

            $outputLineParameters = @{
                HeaderTable        = $TreeConfiguration.HeaderTable
                Item               = $file
                TreePrefix         = $treePrefix
                HumanReadableSizes = $TreeConfiguration.HumanReadableSizes
            }
            $outputInfo = Build-OutputLine @outputLineParameters

            $isReparsePoint = (
                ($file.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -or
                (($file.PSObject.Properties.Match('LinkType').Count -gt 0) -and ($file.LinkType -eq 'HardLink'))
            )
            $oneDriveStatus = Get-OneDriveStatus -Item $file
            $isReparsePointNonOneDrive = $isReparsePoint -and ($oneDriveStatus -eq 'NotOneDrive')

            if ($null -eq $OutputBuilder -and $null -ne $global:PSStyle -and $null -ne $global:PSStyle.Foreground) {
                $regions = @()

                if ($outputInfo.NamePosition -ge 0 -and $outputInfo.NameLength -gt 0) {
                    $nameColor = switch ($oneDriveStatus) {
                        'OnlineOnly' { $global:PSStyle.Foreground.BrightCyan }
                        'LocallyAvailable' { $global:PSStyle.Foreground.Green }
                        'AlwaysAvailable' { $global:PSStyle.Foreground.BrightGreen }
                        default {
                            if ($isReparsePointNonOneDrive) { $global:PSStyle.Foreground.Red } else { $null }
                        }
                    }
                    if ($null -ne $nameColor) {
                        $regions += @{ Start = $outputInfo.NamePosition; Length = $outputInfo.NameLength; Color = $nameColor }
                    }
                }

                if ($outputInfo.SizeColorInfo -and $outputInfo.SizePosition -ge 0 -and $outputInfo.SizeLength -gt 0 -and $null -ne $outputInfo.SizeColorInfo.AnsiColor) {
                    $regions += @{ Start = $outputInfo.SizePosition; Length = $outputInfo.SizeLength; Color = $outputInfo.SizeColorInfo.AnsiColor }
                }

                if ($regions.Count -gt 0) {
                    $regions = $regions | Sort-Object -Property Start

                    $cursor = 0
                    $lineLength = $outputInfo.Line.Length
                    $resetColor = $global:PSStyle.Reset
                    $coloredLine = ''

                    foreach ($region in $regions) {
                        $start = [Math]::Min($region.Start, $lineLength)
                        $length = [Math]::Min($region.Length, [Math]::Max(0, $lineLength - $start))

                        if ($start -gt $cursor) {
                            $coloredLine += $outputInfo.Line.Substring($cursor, $start - $cursor)
                        }

                        $segment = if ($length -gt 0) { $outputInfo.Line.Substring($start, $length) } else { '' }
                        $coloredLine += "$($region.Color)$segment$resetColor"
                        $cursor = $start + $length
                    }

                    if ($cursor -lt $lineLength) {
                        $coloredLine += $outputInfo.Line.Substring($cursor)
                    }

                    $coloredLine += $resetColor
                    Write-Information -MessageData $coloredLine -InformationAction Continue
                    continue
                }
            }

            if ($outputInfo.SizeColorInfo -and $outputInfo.SizePosition -ge 0 -and $outputInfo.SizeLength -gt 0) {
                $before = $outputInfo.Line.Substring(0, $outputInfo.SizePosition)
                $size = $outputInfo.Line.Substring($outputInfo.SizePosition, $outputInfo.SizeLength)
                $after = $outputInfo.Line.Substring($outputInfo.SizePosition + $outputInfo.SizeLength)

                if ($null -ne $OutputBuilder) {
                    [void]$OutputBuilder.AppendLine($outputInfo.Line)
                } else {
                    if ($null -ne $outputInfo.SizeColorInfo.AnsiColor) {
                        Write-Information -MessageData "$before$($outputInfo.SizeColorInfo.AnsiColor)$size$($global:PSStyle.Reset)$after$($global:PSStyle.Reset)" -InformationAction Continue
                    } else {
                        # Fallback: Just print the whole line without color if no ANSI, or simple concat
                        Write-Information -MessageData "$before$size$after$($global:PSStyle.Reset)" -InformationAction Continue
                    }
                }
            } else {
                Write-OutputLine -Line $outputInfo.Line -OutputBuilder $OutputBuilder
            }

            $TreeStats.AddFile($file)
        }
    }

    # Process directories
    foreach ($directory in $visibleDirectories) {
        $currentItemIndex++
        $isLastItem = ($currentItemIndex -eq $totalItems)

        # Print connector line to make it look prettier, can be turned on/off in settings
        if ($TreeConfiguration.ShowConnectorLines -and $files.Count -gt 0) {
            $hierarchyPos = $TreeConfiguration.HeaderTable.Indentations['Hierarchy']
            $connector = ' ' * $hierarchyPos + "$TreeIndent$($TreeConfiguration.lineStyle.Vertical)"
            Write-OutputLine -Line $connector -OutputBuilder $OutputBuilder
        }

        # Create the directory prefix with appropriate tree symbols
        $treeBranch = if ($isLastItem) { $TreeConfiguration.lineStyle.LastBranch } else { $TreeConfiguration.lineStyle.Branch }
        $treePrefix = if ($IsRoot) { $treeBranch } else { "$TreeIndent$treeBranch" }

        # Build and output the directory line
        $outputLineParameters = @{
            HeaderTable        = $TreeConfiguration.HeaderTable
            Item               = $directory
            TreePrefix         = $treePrefix
            HumanReadableSizes = $TreeConfiguration.HumanReadableSizes
        }
        $outputInfo = Build-OutputLine @outputLineParameters

        if ($null -eq $OutputBuilder -and $outputInfo.NamePosition -ge 0 -and $outputInfo.NameLength -gt 0 -and $null -ne $global:PSStyle -and $null -ne $global:PSStyle.Foreground) {
            $beforeName = $outputInfo.Line.Substring(0, [Math]::Min($outputInfo.NamePosition, $outputInfo.Line.Length))
            $nameSection = $outputInfo.Line.Substring([Math]::Min($outputInfo.NamePosition, $outputInfo.Line.Length), [Math]::Min($outputInfo.NameLength, [Math]::Max(0, $outputInfo.Line.Length - $outputInfo.NamePosition)))
            $afterName = if (($outputInfo.NamePosition + $outputInfo.NameLength) -lt $outputInfo.Line.Length) { $outputInfo.Line.Substring($outputInfo.NamePosition + $outputInfo.NameLength) } else { '' }

            $isHiddenDirectory = ($directory.Attributes -band [System.IO.FileAttributes]::Hidden)
            $isReparseDirectory = (
                ($directory.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -or
                (($directory.PSObject.Properties.Match('LinkType').Count -gt 0) -and ($directory.LinkType -eq 'HardLink'))
            )
            $oneDriveDirStatus = Get-OneDriveStatus -Item $directory
            $isReparseDirectoryNonOneDrive = $isReparseDirectory -and ($oneDriveDirStatus -eq 'NotOneDrive')
            $directoryColor = if ($oneDriveDirStatus -eq 'OnlineOnly') {
                $global:PSStyle.Foreground.BrightCyan
            } elseif ($oneDriveDirStatus -eq 'LocallyAvailable') {
                $global:PSStyle.Foreground.Green
            } elseif ($oneDriveDirStatus -eq 'AlwaysAvailable') {
                $global:PSStyle.Foreground.BrightGreen
            } elseif ($isReparseDirectoryNonOneDrive) {
                $global:PSStyle.Foreground.Red
            } elseif ($isHiddenDirectory) {
                $global:PSStyle.Foreground.Yellow
            } else {
                $global:PSStyle.Foreground.BrightYellow
            }
            $resetColor = $global:PSStyle.Reset
            Write-Information -MessageData "$beforeName$directoryColor$nameSection$resetColor$afterName$resetColor" -InformationAction Continue
        } else {
            Write-OutputLine -Line $outputInfo.Line -OutputBuilder $OutputBuilder
        }

        $TreeStats.FoldersPrinted++

        # Use the already calculated folder size for the stats
        if ($outputInfo.DirectorySize -gt 0) {
            $TreeStats.UpdateLargestFolder($directory.FullName, $outputInfo.DirectorySize)
        }

        # Calculate the new tree indent for child items
        $newTreeIndent = if ($IsRoot) {
            if ($isLastItem) { $TreeConfiguration.lineStyle.Space } else { $TreeConfiguration.lineStyle.VerticalLine }
        } else {
            if ($isLastItem) { "$TreeIndent$($TreeConfiguration.lineStyle.Space)" } else { "$TreeIndent$($TreeConfiguration.lineStyle.VerticalLine)" }
        }

        # Recursively process the directory
        $treeViewParameters = @{
            TreeConfiguration            = $TreeConfiguration
            TreeStats                    = $TreeStats
            ChildItemDirectoryParameters = $ChildItemDirectoryParameters
            ChildItemFileParameters      = $ChildItemFileParameters
            CurrentPath                  = $directory.FullName
            TreeIndent                   = $newTreeIndent
            Last                         = $isLastItem
            IsRoot                       = $false
            CurrentDepth                 = ($CurrentDepth + 1)
            OutputBuilder                = $OutputBuilder
        }
        Get-TreeView @treeViewParameters
    }

    # Return whether this directory has any visible content after filtering
    return $hasVisibleContent
}
