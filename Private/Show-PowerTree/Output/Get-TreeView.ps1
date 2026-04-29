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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCABda2MnTP2hzZc
# 6utSNxL0MXL6JE5J1JTqwMe1gCt/iaCCFnYwggM4MIICIKADAgECAhA1A5UPpKQt
# h0lLtSSMfIl8MA0GCSqGSIb3DQEBCwUAMDQxMjAwBgNVBAMMKUF1dGhlbnRpY29k
# ZSBDb2RlU2lnbmluZ0NlcnQgMjYwNC4yNy4xNTEyMB4XDTI2MDQyNzIyMDI1OVoX
# DTI3MDQyNzIyMjI1OVowNDEyMDAGA1UEAwwpQXV0aGVudGljb2RlIENvZGVTaWdu
# aW5nQ2VydCAyNjA0LjI3LjE1MTIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQDM4SI9GjFaeoy3uMdX9JApaOSreWv/HQktvICY4j35GdXfQuCWtqJhdrT7
# vXlzmKGH0OHDvtgSGldQOXjX2mOlmnEDMsQILaiyc2hLd43muw8K0YrHaU9h4zDW
# 3NEoJUrvNyEBA97v7DjElO859gkEIJldpJk9GQLFnIqru8aYu32K/+97e2gUZlVC
# +uEQQWS2j5UhGFuV9ayJjLzx/2AxFxCVqNTa7mXRzMoW8vIJcgKXJQKoZ4wL+5Nw
# podlKD6YiNtWmXkD6oKN3FfTKVb9EOgjVH3NPhfpEYaYzY1qaT/4dEJU+hwBpIoB
# 65MUxXfLCdN+HGjP+r0hl/II12wJAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDAT
# BgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUOaEQ7+DyXYmtkkf2nAhHfhAH
# 35IwDQYJKoZIhvcNAQELBQADggEBAChV7yHef2mnAYv927iHi/8wTDTRgnYHfudu
# YHcp5x4XQjWDPjpaYOlUTCYpMtegwB/6nqiWTqvoNdqw0RWIbe4pArcYg1yMqKMY
# foeLoDKDq43Q6EmhPz17+4QG70mnCHUCaLL6WkovOjo42A3IsV8L1sy4hpcZq4z6
# T3KPt0Mf6qfqpGBwM103vKvE1W8UeODkIlWoOHgvWsqtCSWLjkZcPLN7uun/FE7m
# m51K24hYSZI2ZqX300D92b3mY+1cr9yvFDQoDes46HTTaht5QP9wvp6hPgR6NGAN
# +EhTCDkgWmef6M8Wbk2mdyz/rRc9sBVK+4e/ha3CJvNrH/4VCyUwggWNMIIEdaAD
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
# q8WhbaM2tszWkPZPubdcMIIG7TCCBNWgAwIBAgIQCoDvGEuN8QWC0cR2p5V0aDAN
# BgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQs
# IEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5n
# IFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMB4XDTI1MDYwNDAwMDAwMFoXDTM2MDkw
# MzIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MTswOQYDVQQDEzJEaWdpQ2VydCBTSEEyNTYgUlNBNDA5NiBUaW1lc3RhbXAgUmVz
# cG9uZGVyIDIwMjUgMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANBG
# rC0Sxp7Q6q5gVrMrV7pvUf+GcAoB38o3zBlCMGMyqJnfFNZx+wvA69HFTBdwbHwB
# SOeLpvPnZ8ZN+vo8dE2/pPvOx/Vj8TchTySA2R4QKpVD7dvNZh6wW2R6kSu9RJt/
# 4QhguSssp3qome7MrxVyfQO9sMx6ZAWjFDYOzDi8SOhPUWlLnh00Cll8pjrUcCV3
# K3E0zz09ldQ//nBZZREr4h/GI6Dxb2UoyrN0ijtUDVHRXdmncOOMA3CoB/iUSROU
# INDT98oksouTMYFOnHoRh6+86Ltc5zjPKHW5KqCvpSduSwhwUmotuQhcg9tw2YD3
# w6ySSSu+3qU8DD+nigNJFmt6LAHvH3KSuNLoZLc1Hf2JNMVL4Q1OpbybpMe46Yce
# NA0LfNsnqcnpJeItK/DhKbPxTTuGoX7wJNdoRORVbPR1VVnDuSeHVZlc4seAO+6d
# 2sC26/PQPdP51ho1zBp+xUIZkpSFA8vWdoUoHLWnqWU3dCCyFG1roSrgHjSHlq8x
# ymLnjCbSLZ49kPmk8iyyizNDIXj//cOgrY7rlRyTlaCCfw7aSUROwnu7zER6EaJ+
# AliL7ojTdS5PWPsWeupWs7NpChUk555K096V1hE0yZIXe+giAwW00aHzrDchIc2b
# Qhpp0IoKRR7YufAkprxMiXAJQ1XCmnCfgPf8+3mnAgMBAAGjggGVMIIBkTAMBgNV
# HRMBAf8EAjAAMB0GA1UdDgQWBBTkO/zyMe39/dfzkXFjGVBDz2GM6DAfBgNVHSME
# GDAWgBTvb1NK6eQGfHrK4pBW9i/USezLTjAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0l
# AQH/BAwwCgYIKwYBBQUHAwgwgZUGCCsGAQUFBwEBBIGIMIGFMCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXQYIKwYBBQUHMAKGUWh0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGlu
# Z1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNydDBfBgNVHR8EWDBWMFSgUqBQhk5odHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3RhbXBp
# bmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIw
# CwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQBlKq3xHCcEua5gQezRCESe
# Y0ByIfjk9iJP2zWLpQq1b4URGnwWBdEZD9gBq9fNaNmFj6Eh8/YmRDfxT7C0k8FU
# FqNh+tshgb4O6Lgjg8K8elC4+oWCqnU/ML9lFfim8/9yJmZSe2F8AQ/UdKFOtj7Y
# MTmqPO9mzskgiC3QYIUP2S3HQvHG1FDu+WUqW4daIqToXFE/JQ/EABgfZXLWU0zi
# TN6R3ygQBHMUBaB5bdrPbF6MRYs03h4obEMnxYOX8VBRKe1uNnzQVTeLni2nHkX/
# QqvXnNb+YkDFkxUGtMTaiLR9wjxUxu2hECZpqyU1d0IbX6Wq8/gVutDojBIFeRlq
# AcuEVT0cKsb+zJNEsuEB7O7/cuvTQasnM9AWcIQfVjnzrvwiCZ85EE8LUkqRhoS3
# Y50OHgaY7T/lwd6UArb+BOVAkg2oOvol/DJgddJ35XTxfUlQ+8Hggt8l2Yv7roan
# cJIFcbojBcxlRcGG0LIhp6GvReQGgMgYxQbV1S3CrWqZzBt1R9xJgKf47CdxVRd/
# ndUlQ05oxYy2zRWVFjF7mcr4C34Mj3ocCVccAvlKV9jEnstrniLvUxxVZE/rptb7
# IRE2lskKPIJgbaP5t2nGj/ULLi49xTcBZU8atufk+EMF/cWuiC7POGT75qaL6vdC
# vHlshtjdNXOCIUjsarfNZzGCBSQwggUgAgEBMEgwNDEyMDAGA1UEAwwpQXV0aGVu
# dGljb2RlIENvZGVTaWduaW5nQ2VydCAyNjA0LjI3LjE1MTICEDUDlQ+kpC2HSUu1
# JIx8iXwwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKA
# ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg+j/JXLwGFSX9keStwEL5QyOz7fWE
# DSNmufb3XpTyhiAwDQYJKoZIhvcNAQEBBQAEggEAwk2qGj5Ble/3aSgLtxli+bAa
# fVqUjL5aTK8mlu56Fjdok8WN+gBoNRfcrGVZo05EKfWG9iWWe1NPx1fIT316q+LW
# cxB2CCm2Ue/4Hednje8OEEtYUJxAKwYbCCqHtACRSNIRLwcB7DPGD3r4okX60NGl
# MNzAmtwyZ1Zx3lT0VEX/BR87y1yqIGJpD3T6EVIefn2fbqMHAivg0B1rKfmrrtBv
# CuMrsLbwLcDrAzYylgmSMAE8bUDsmjQI8AYEc4jtPL9j8PmcILlG3pe1WHK/0LOh
# /4Ky0ZjMYxgIGDKNZlqZQf2euDPttiMZx35CxNTItjrtf1h6vxC5sLktmAyqbKGC
# AyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhL
# jfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjA0MjkyMTEwNDJaMC8GCSqGSIb3DQEJ
# BDEiBCB5Zv7LfEmCBNp1LVd1lRDJLCP6GC3EOz4hJDhsh26pjjANBgkqhkiG9w0B
# AQEFAASCAgAB3PZ/6vhKuUz/65+Yr8CIhuIfNfrVwrYXYdsYLxGCsPeZSiUUjkTF
# q1zgKFhmFNMl+En/6oj61jXGbb2/bzhG+4+p+qhp4N3cNB08yDZ4leWsWdM2wWKs
# 84aqFtZ5+zf1Mpbqvke+3Sg45fPhtUrHT1NGwemHdMdd6a2R7gNSztOcbic/u8Ku
# CQJ67VPQayyBiAqhVP7LOsn9sHVDFbWKmsow3nDDiy+GSpgCZAWWobpfciL+IbyS
# TnLmE3QNjMEJryphjltPQizdlJY7/+KVcwXxrnmFG38EkBrlXWm2bWrXV1I/xV5d
# n2hsiToKZQG4nZiFu/smuGpv5ttffbgJxYH6jPvmyrO+aRpJKBcBp/nRIxEY4q7o
# Zr22WKxoBqXDb3SUEgsMMmuwFBnKzzyaNRpEskcukLwiO3+4dwIfUpX0bulBxdcq
# STJTdi1c5a2yhJCo7y4IsUrv+ZHVu/C5Qmj59o+hHq53RlipbNkd4QF82zfgxgyO
# sMddml9qAJ7RYaIn7fTzLoiNFeyt0iFu1AWtIyURXlzqS+rit9oQcgfGKbF3hasH
# BGIBXrWZjG3Sar5xIKt5vumVOfmclNnOH3oa8Lc6qHSrCMkkJcH8ywUsiLKw2Szo
# tUAyP4G/PlfFeOWizygrYqf5RWkQvVT31zNdZtMCzvgOkpVebszkgg==
# SIG # End signature block
