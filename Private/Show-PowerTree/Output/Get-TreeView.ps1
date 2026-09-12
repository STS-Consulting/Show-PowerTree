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
                    Microsoft.PowerShell.Utility\Write-Information -MessageData $coloredLine -InformationAction Continue
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
                        Microsoft.PowerShell.Utility\Write-Information -MessageData "$before$($outputInfo.SizeColorInfo.AnsiColor)$size$($global:PSStyle.Reset)$after$($global:PSStyle.Reset)" -InformationAction Continue
                    } else {
                        # Fallback: Just print the whole line without color if no ANSI, or simple concat
                        Microsoft.PowerShell.Utility\Write-Information -MessageData "$before$size$after$($global:PSStyle.Reset)" -InformationAction Continue
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
            Microsoft.PowerShell.Utility\Write-Information -MessageData "$beforeName$directoryColor$nameSection$resetColor$afterName$resetColor" -InformationAction Continue
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

# SIG # Begin signature block
# MIIcRAYJKoZIhvcNAQcCoIIcNTCCHDECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCOxM3ZUpridpoH
# xcKJqrbtcxjVBPsGMrrCoMkP17FxDqCCFnYwggM4MIICIKADAgECAhBq68etXxgs
# l0IzUnGnriXYMA0GCSqGSIb3DQEBCwUAMDQxMjAwBgNVBAMMKUF1dGhlbnRpY29k
# ZSBDb2RlU2lnbmluZ0NlcnQgMjYwOC4zMC4yMTM5MB4XDTI2MDgzMTA0MjkyNFoX
# DTI3MDgzMTA0NDkyNFowNDEyMDAGA1UEAwwpQXV0aGVudGljb2RlIENvZGVTaWdu
# aW5nQ2VydCAyNjA4LjMwLjIxMzkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQDdJxoL2uUcJvum1pKa1VHYOTI3J6OR1BT5eYATKlN3JKjyNnKX9J4xF+SU
# R2GH9rXl2BqGZxBiRJRUORzw8dRx64Lt+O4LRDoB9nLrIDB7BR792m+2rLa6LplB
# o899uNObHkf1sLe3H8VU82Cbet0jC8wuhdZtXPQ2Y+Z+W+1knLDEY80dnCXcO+5l
# Vdv/UralKO/Iugx/OTulLFmSPV6DbSpqILn/EiIB1xDUsJvuRc/M/JQDDnqY5zNK
# ebxmc686/4zx6Stsiowa/xN0cbuVEwbepBwVTRJFUafLXIo+KtRiylMcL1lEM/fT
# 5+9FHTjvlnrQtEuHj78KawkXQxIdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDAT
# BgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUXAahq4JHkDCDfcmaMghq01gw
# lSowDQYJKoZIhvcNAQELBQADggEBAJxnSVTvVOf6APMUdus7Op+YThqeLtKb3g5f
# BKGDvAfed6YX1EndJ7QwBYftzuf5zdEgMuUI8Ktlv7576G9TvdcPsUi4KQvOS+DF
# KjuUB+tYa6dk9Bqf00ZrwkERkBu7drtNnSxhCUKeEFIKs11glGtUhC5K0WVyN+8U
# GejJ0u5dh2MPhlXllMqCsYARGvtHQayvjbpNZBsqzNFWJJsmFjMhx+oEtaAw4weC
# jbvCCbGqawBHOx/oTro2ba7LmQkHcLmXQp/6eUyoYc+r7/QY8aBT9tHmCeDcus5x
# tNwKWLcjLhSLbXD7faZbk1Uh+200mSjDhPhvX9vL9IeBKak+OIkwggWNMIIEdaAD
# AgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYT
# AlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2Vy
# dC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0y
# MjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAf
# BgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4Smn
# PVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6f
# qVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O
# 7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZ
# Vu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4F
# fYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLm
# qaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMre
# Sx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/ch
# srIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+U
# DCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xM
# dT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUb
# AgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFd
# ZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAO
# BgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRw
# Oi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0f
# BD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNz
# dXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEM
# BQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLt
# pIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouy
# XtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jS
# TEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAc
# AgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2
# h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQwgga0MIIEnKADAgECAhANx6xXBf8hmS5A
# QyIMOkmGMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxE
# aWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMT
# GERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yNTA1MDcwMDAwMDBaFw0zODAx
# MTQyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNB
# NDA5NiBTSEEyNTYgMjAyNSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQC0eDHTCphBcr48RsAcrHXbo0ZodLRRF51NrY0NlLWZloMsVO1DahGPNRcy
# bEKq+RuwOnPhof6pvF4uGjwjqNjfEvUi6wuim5bap+0lgloM2zX4kftn5B1IpYzT
# qpyFQ/4Bt0mAxAHeHYNnQxqXmRinvuNgxVBdJkf77S2uPoCj7GH8BLuxBG5AvftB
# dsOECS1UkxBvMgEdgkFiDNYiOTx4OtiFcMSkqTtF2hfQz3zQSku2Ws3IfDReb6e3
# mmdglTcaarps0wjUjsZvkgFkriK9tUKJm/s80FiocSk1VYLZlDwFt+cVFBURJg6z
# MUjZa/zbCclF83bRVFLeGkuAhHiGPMvSGmhgaTzVyhYn4p0+8y9oHRaQT/aofEnS
# 5xLrfxnGpTXiUOeSLsJygoLPp66bkDX1ZlAeSpQl92QOMeRxykvq6gbylsXQskBB
# BnGy3tW/AMOMCZIVNSaz7BX8VtYGqLt9MmeOreGPRdtBx3yGOP+rx3rKWDEJlIqL
# XvJWnY0v5ydPpOjL6s36czwzsucuoKs7Yk/ehb//Wx+5kMqIMRvUBDx6z1ev+7ps
# NOdgJMoiwOrUG2ZdSoQbU2rMkpLiQ6bGRinZbI4OLu9BMIFm1UUl9VnePs6BaaeE
# WvjJSjNm2qA+sdFUeEY0qVjPKOWug/G6X5uAiynM7Bu2ayBjUwIDAQABo4IBXTCC
# AVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU729TSunkBnx6yuKQVvYv
# 1Ensy04wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/
# BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggr
# BgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVo
# dHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0
# LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjAL
# BglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBABfO+xaAHP4HPRF2cTC9vgvI
# tTSmf83Qh8WIGjB/T8ObXAZz8OjuhUxjaaFdleMM0lBryPTQM2qEJPe36zwbSI/m
# S83afsl3YTj+IQhQE7jU/kXjjytJgnn0hvrV6hqWGd3rLAUt6vJy9lMDPjTLxLgX
# f9r5nWMQwr8Myb9rEVKChHyfpzee5kH0F8HABBgr0UdqirZ7bowe9Vj2AIMD8liy
# rukZ2iA/wdG2th9y1IsA0QF8dTXqvcnTmpfeQh35k5zOCPmSNq1UH410ANVko43+
# Cdmu4y81hjajV/gxdEkMx1NKU4uHQcKfZxAvBAKqMVuqte69M9J6A47OvgRaPs+2
# ykgcGV00TYr2Lr3ty9qIijanrUR3anzEwlvzZiiyfTPjLbnFRsjsYg39OlV8cipD
# oq7+qNNjqFzeGxcytL5TTLL4ZaoBdqbhOhZ3ZRDUphPvSRmMThi0vw9vODRzW6Ax
# nJll38F0cuJG7uEBYTptMSbhdhGQDpOXgpIUsWTjd6xpR6oaQf/DJbg3s6KCLPAl
# Z66RzIg9sC+NJpud/v4+7RWsWCiKi9EOLLHfMR2ZyJ/+xhCx9yHbxtl5TPau1j/1
# MIDpMPx0LckTetiSuEtQvLsNz3Qbp7wGWqbIiOWCnb5WqxL3/BAPvIXKUjPSxyZs
# q8WhbaM2tszWkPZPubdcMIIG7TCCBNWgAwIBAgIQCE/cM09+RU7bww+P+ZIYNTAN
# BgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQs
# IEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5n
# IFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMB4XDTI2MDgwNTAwMDAwMFoXDTM3MTEw
# NDIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MTswOQYDVQQDEzJEaWdpQ2VydCBTSEEyNTYgUlNBNDA5NiBUaW1lc3RhbXAgUmVz
# cG9uZGVyIDIwMjYgMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALZ7
# pvLJ/s1K+NSbTGWz/TjGMPh8CQ6RucZCLv5anHzWJjF/NWJrFIhy24fcpKXlgRik
# y4WAawDfU3YP0BMxt9l3Dm5oCG5Z69AqEN1kgHg2epx+l+lZBcmJCcN0ASURML5u
# FIS80sZsDwO3BSkUxDjLJhBI+qiZP3aixAC/qEGLjsBNlLol9VZ7pfGEXiMlneJI
# C5/YKuizVzNFKZZEeoy/0B8Zm+nzKBgSWG52lCO1w+nCg6XpCtklTJXeIg283hw7
# TmmsZXR+SMbjbrEOvZ3fP2VxIgeR28Y90ZStd3F9VuA5RVynb/whITPAo9b75Zr4
# Ta6Mj3URm26QZYMn/FnbuTegcoRcFEZ9FOqM5T6MTdtr/n74lIT/ug0eeOzmZ6QT
# Fg33otX+bFRsIolvykE1jive4PuESaT8zzVeFWDAMDtozNgLctkGD1ZjkEyZtJrL
# l5ya0m5doH/ScpaZCZVl6pNUOCybMc/kxC6EAmSJY24L0yYKD1Nkddsnb/ItVKi/
# 2nXpQNMu1PT5prW83vV8d67WowuUs0HdY4H8AMLGvdL/WHEj3ZnqMqAQQP9u3Ai9
# t+5eQ02GDwy0ODjdzi0xlp70W+ow63/0++YDEX1M0iwgUHwbrJvfpklkZQvw3+kv
# 3vUPItdwroczk9icflf55W1zOEKAcJVAIXpcMCU9AgMBAAGjggGVMIIBkTAMBgNV
# HRMBAf8EAjAAMB0GA1UdDgQWBBQUyWOKMC7USvtulPPm40B+9ezN4jAfBgNVHSME
# GDAWgBTvb1NK6eQGfHrK4pBW9i/USezLTjAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0l
# AQH/BAwwCgYIKwYBBQUHAwgwgZUGCCsGAQUFBwEBBIGIMIGFMCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXQYIKwYBBQUHMAKGUWh0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGlu
# Z1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNydDBfBgNVHR8EWDBWMFSgUqBQhk5odHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3RhbXBp
# bmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIw
# CwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQCNxTphHp1SCt+ZrAmAfn0o
# QLFr0mLywSLaDXQIENoyKqxrFbJblzCVP/pkXmwXOdrOpWygLzlT12os5ipDCy35
# RBCg2UMeApEtrfGhz45F4Wt4WGdNdIbRWt3YTYJmpR+b7lr4d7Uwn+H600u4D7Rn
# OGf8Wj4UNgAdZkfHhHv1mx9EVh71SJelcEN/oORSjXzdjfw1iZH9d8Nh/thn6hH2
# 3d+VsPAr6GAYyzSA02nXD1nYLI7Ijmiv+xLCiYC41DSFYL3GhTiy0PxpawPtGRya
# BVGzq+UiTfM8pD7KVyF5aQyWP4KhVGUUTnmm/RlYJoW3TiXA/+t0YcT2oRVBm3JE
# TjajHug2AL+v5jhtKVnd3D0rbHXEu27o+Q8p4sEWPMqKDB+qbceb6T/6WcwTwXmQ
# 9lOCLLYcsQeSWmvKqzpAec9etE14jOQAzLKWdE3w/TCaKtLRaRT7LCkRYVnhA2D7
# 3FLje1O5b3HR5eHs0NzU/+xX7NbEdcofy0W3Wdwd1XOqtlpg/JgwtKfZM5dqO94l
# bUveOiJBI+xZEbGRsMNbXmMREUTgu+Oca7Y73MPWcslIx2VhkSKSXjDbD6rgg39H
# 5Mh7QfieAIjWagkJNt68Yfim6cjEzVSiLSeZfdkr5dtFPTW6jATlWJdYeeDRGCya
# tf8R1hSjzSvdN8yWQPT9gzGCBSQwggUgAgEBMEgwNDEyMDAGA1UEAwwpQXV0aGVu
# dGljb2RlIENvZGVTaWduaW5nQ2VydCAyNjA4LjMwLjIxMzkCEGrrx61fGCyXQjNS
# caeuJdgwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKA
# ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgNt8V3DZZz7F0YXUMnZIyofZeB37v
# DTZPqo2aAlBlqMgwDQYJKoZIhvcNAQEBBQAEggEAfmiavJ/joHv7l7W+otlgDMH7
# O4OyJkSUmjI0lLvpXZdfjgIvaqTd476Ap5hzDgtGPMuEtYC+mif79U/4cxxsvuFC
# aJPQCMxLz8lPfnVPvh2WDW8PwfXctA2GedO4svdb3IRF2LpRIxZV1tTvOrCFABFZ
# m/3WMIJ3Vh2JIkQ1SelpGSiO/L39GOlejvuLhaxW6gRG/MIUYO1B8cOalMVFfnxi
# Mj42LuEkkwfJU23lEg6OzhikH0cpWvWhEVUbNbV97F92zQmRc5WPZ3hQAcHGZWHS
# fIaXE4l4sGfPIPdiMpjoL/qUQAj4xfUEDijcumdTCdZ7e2/hJqNMuxhHpJcKV6GC
# AyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAhP3DNP
# fkVO28MPj/mSGDUwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjA5MTIwNzE5NThaMC8GCSqGSIb3DQEJ
# BDEiBCBrFe2Jky/ilSE0pcaOEtKs7IPFE9bb/bb58OuW6n27ZTANBgkqhkiG9w0B
# AQEFAASCAgANykOjpDwVVSdx6vsSG7unYaL99SsduyetFA0M6uHhPRe/L2PkiTuW
# /at9jOqs62BcV0i8Xzf7ItiVvEkw4vRQm6Ma1enRXvKisbsweDYrJeQxFDtGZNOf
# OxVV1Med9hLDvUtsOOvaHENI7iJtMqYlVwfBWsXfNplxllVOYeyGM2beTKZn49zM
# mf3MvWx0Orqq3EYONBeTRGVPgZHqgbQe4JZYnWhyemgXm6NdJuFija6sGc9OuWF4
# 96UwvoILAN5q8IBZExDLqNx/VqgEfCiK/4WpJcYZTjAsZYwHkYCU4qNC7wVY+/ko
# rcGFPmhG/hIbZizLUOz5q14kEno0J+KQTowZOGUDjw2iotT3mFzNo7/2zb7N/t2q
# 1k9wqz3JL+9vcI5VJiGpY/8uPsAmqniGFw83Q3suv4hy6vdmhlmOGsiZuN1Qjm2h
# vtr1fMqsEVXDMdRePF3Ri7uAMD2GuQE4T4ZMN5aYvPKO3K5w+ksyqz9BW+g+NoAy
# onRYQMbSRNbU5hlRjMXkR+9wGNKxf5fziuLw5SLoPWvzYDknD+pdTvhC76X8nP3U
# K3yf5SsgPzcHxjqO7+EYjQ331Fi5oAi6tSBGADDtkK+fVa8qzrX0JMD42HIVcZCT
# cbBQpKRFDSawjG5uDj77AY6Uq14VYfeb9GitOQHscYfi2tp6xrGOug==
# SIG # End signature block
