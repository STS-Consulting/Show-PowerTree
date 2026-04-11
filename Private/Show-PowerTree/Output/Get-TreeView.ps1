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
# MIIcLAYJKoZIhvcNAQcCoIIcHTCCHBkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCABda2MnTP2hzZc
# 6utSNxL0MXL6JE5J1JTqwMe1gCt/iaCCFmYwggMoMIICEKADAgECAhBSDm+iYBGr
# iEa7joroOpM5MA0GCSqGSIb3DQEBCwUAMCwxKjAoBgNVBAMMIUF1dGhlbnRpY29k
# ZSBDb2RlU2lnbmluZ0NlcnQgMjUwNjAeFw0yNTA2MjQwNDE1MDJaFw0yNjA2MjQw
# NDM1MDJaMCwxKjAoBgNVBAMMIUF1dGhlbnRpY29kZSBDb2RlU2lnbmluZ0NlcnQg
# MjUwNjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANZc5uW9b35U8sm6
# K6q2uMsPC858n8/PQTYq/W+zJxNmG857R3Ul9j6+i8q+h13l1xokkn3ac5R9ZE9X
# 154ObTmBJ+Chpo/o/2fBR4fUJk8Vr6ayKo30CSH/CDOrEVbGaUCRd8Qn4/KlTLNs
# 2W+f3Yz8BUTJVWWyv0dwy/4M1Zd9bR821ZHLXxSHljLcMvGtM8Z3PCzGKYoc4rzy
# Srn/rq4dVhMiSoFlB5ap+1XjNtothuX6jsOapbMl7DnP5m408U19on9pa0P7pYq5
# 53MCcG+ey5iP1nov59owcgSys4hOcxEqtN+A+hfQk16mqT5d6ZR6D6h93tO5qNg7
# mU1+tAkCAwEAAaNGMEQwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUF
# BwMDMB0GA1UdDgQWBBS1bvdiW88c2QGbM+WPEf+fAEhZczANBgkqhkiG9w0BAQsF
# AAOCAQEAUnUKQWGJP+XnEoS9aCgi2ob7DogZUtpGHGvXGe9FmhkpoDb/VDEl/qQe
# QmQb3sYEBg+ZnVqocREbm72U+7Moq5L8tZZ2NOAfmcaWbAmd4jRdMlJzBNuXDnmP
# KWYsOaXFirU9i18/Ws2GL5MG6Xpff5WRo7MIJ5iKghIkGVi+l/Io/5mBzpkSyrrO
# hYpbMY8OV6TXc4jqEut4nvmB4jrJAzpmVpFuyw0ERxwp0jUFoK95w2ftrYaDmPuP
# 1BREeZ8GjSIk+kw6jHy0CzlK9w/HTOTxgt2CdzHZKEwddUf91dHwC5GvdPjuy1VX
# +Z6HHKm8nqHZPR6ejw6j9ohfyIBHSzCCBY0wggR1oAMCAQICEA6bGI750C3n79tQ
# 4ghAGFowDQYJKoZIhvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERp
# Z2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMb
# RGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTIyMDgwMTAwMDAwMFoXDTMx
# MTEwOTIzNTk1OVowYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IElu
# YzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQg
# VHJ1c3RlZCBSb290IEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# v+aQc2jeu+RdSjwwIjBpM+zCpyUuySE98orYWcLhKac9WKt2ms2uexuEDcQwH/Mb
# pDgW61bGl20dq7J58soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNwwrK6dZlq
# czKU0RBEEC7fgvMHhOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs06wXGXuxb
# Grzryc/NrDRAX7F6Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e5TXnMcva
# k17cjo+A2raRmECQecN4x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtVgkEy19sE
# cypukQF8IUzUvK4bA3VdeGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85tRFYF/ck
# XEaPZPfBaYh2mHY9WV1CdoeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+SkjqePdwA
# 5EUlibaaRBkrfsCUtNJhbesz2cXfSwQAzH0clcOP9yGyshG3u3/y1YxwLEFgqrFj
# GESVGnZifvaAsPvoZKYz0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzlDlJRR3S+
# Jqy2QXXeeqxfjT/JvNNBERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFrb7GrhotP
# wtZFX50g/KEexcCPorF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCATowggE2MA8G
# A1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiuHA9PMB8G
# A1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQEAwIBhjB5
# BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0
# LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDBFBgNVHR8EPjA8MDqgOKA2hjRodHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3Js
# MBEGA1UdIAQKMAgwBgYEVR0gADANBgkqhkiG9w0BAQwFAAOCAQEAcKC/Q1xV5zhf
# oKN0Gz22Ftf3v1cHvZqsoYcs7IVeqRq7IviHGmlUIu2kiHdtvRoU9BNKei8ttzjv
# 9P+Aufih9/Jy3iS8UgPITtAq3votVs/59PesMHqai7Je1M/RQ0SbQyHrlnKhSLSZ
# y51PpwYDE3cnRNTnf+hZqPC/Lwum6fI0POz3A8eHqNJMQBk1RmppVLC4oVaO7KTV
# Peix3P0c2PR3WlxUjG/voVA9/HYJaISfb8rbII01YBwCA8sgsKxYoA5AY8WYIsGy
# WfVVa88nq2x2zm8jLfR+cWojayL/ErhULSd+2DrZ8LaHlv1b0VysGMNNn3O3Aamf
# V6peKOK5lDCCBrQwggScoAMCAQICEA3HrFcF/yGZLkBDIgw6SYYwDQYJKoZIhvcN
# AQELBQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcG
# A1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3Rl
# ZCBSb290IEc0MB4XDTI1MDUwNzAwMDAwMFoXDTM4MDExNDIzNTk1OVowaTELMAkG
# A1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdp
# Q2VydCBUcnVzdGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNIQTI1NiAyMDI1
# IENBMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALR4MdMKmEFyvjxG
# wBysddujRmh0tFEXnU2tjQ2UtZmWgyxU7UNqEY81FzJsQqr5G7A6c+Gh/qm8Xi4a
# PCOo2N8S9SLrC6Kbltqn7SWCWgzbNfiR+2fkHUiljNOqnIVD/gG3SYDEAd4dg2dD
# GpeZGKe+42DFUF0mR/vtLa4+gKPsYfwEu7EEbkC9+0F2w4QJLVSTEG8yAR2CQWIM
# 1iI5PHg62IVwxKSpO0XaF9DPfNBKS7Zazch8NF5vp7eaZ2CVNxpqumzTCNSOxm+S
# AWSuIr21Qomb+zzQWKhxKTVVgtmUPAW35xUUFREmDrMxSNlr/NsJyUXzdtFUUt4a
# S4CEeIY8y9IaaGBpPNXKFifinT7zL2gdFpBP9qh8SdLnEut/GcalNeJQ55IuwnKC
# gs+nrpuQNfVmUB5KlCX3ZA4x5HHKS+rqBvKWxdCyQEEGcbLe1b8Aw4wJkhU1JrPs
# FfxW1gaou30yZ46t4Y9F20HHfIY4/6vHespYMQmUiote8ladjS/nJ0+k6Mvqzfpz
# PDOy5y6gqztiT96Fv/9bH7mQyogxG9QEPHrPV6/7umw052AkyiLA6tQbZl1KhBtT
# asySkuJDpsZGKdlsjg4u70EwgWbVRSX1Wd4+zoFpp4Ra+MlKM2baoD6x0VR4RjSp
# WM8o5a6D8bpfm4CLKczsG7ZrIGNTAgMBAAGjggFdMIIBWTASBgNVHRMBAf8ECDAG
# AQH/AgEAMB0GA1UdDgQWBBTvb1NK6eQGfHrK4pBW9i/USezLTjAfBgNVHSMEGDAW
# gBTs1+OC0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAww
# CgYIKwYBBQUHAwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8v
# b2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDow
# OKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRS
# b290RzQuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkq
# hkiG9w0BAQsFAAOCAgEAF877FoAc/gc9EXZxML2+C8i1NKZ/zdCHxYgaMH9Pw5tc
# BnPw6O6FTGNpoV2V4wzSUGvI9NAzaoQk97frPBtIj+ZLzdp+yXdhOP4hCFATuNT+
# ReOPK0mCefSG+tXqGpYZ3essBS3q8nL2UwM+NMvEuBd/2vmdYxDCvwzJv2sRUoKE
# fJ+nN57mQfQXwcAEGCvRR2qKtntujB71WPYAgwPyWLKu6RnaID/B0ba2H3LUiwDR
# AXx1Neq9ydOal95CHfmTnM4I+ZI2rVQfjXQA1WSjjf4J2a7jLzWGNqNX+DF0SQzH
# U0pTi4dBwp9nEC8EAqoxW6q17r0z0noDjs6+BFo+z7bKSBwZXTRNivYuve3L2oiK
# NqetRHdqfMTCW/NmKLJ9M+MtucVGyOxiDf06VXxyKkOirv6o02OoXN4bFzK0vlNM
# svhlqgF2puE6FndlENSmE+9JGYxOGLS/D284NHNboDGcmWXfwXRy4kbu4QFhOm0x
# JuF2EZAOk5eCkhSxZON3rGlHqhpB/8MluDezooIs8CVnrpHMiD2wL40mm53+/j7t
# FaxYKIqL0Q4ssd8xHZnIn/7GELH3IdvG2XlM9q7WP/UwgOkw/HQtyRN62JK4S1C8
# uw3PdBunvAZapsiI5YKdvlarEvf8EA+8hcpSM9LHJmyrxaFtoza2zNaQ9k+5t1ww
# ggbtMIIE1aADAgECAhAKgO8YS43xBYLRxHanlXRoMA0GCSqGSIb3DQEBCwUAMGkx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4
# RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYg
# MjAyNSBDQTEwHhcNMjUwNjA0MDAwMDAwWhcNMzYwOTAzMjM1OTU5WjBjMQswCQYD
# VQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lD
# ZXJ0IFNIQTI1NiBSU0E0MDk2IFRpbWVzdGFtcCBSZXNwb25kZXIgMjAyNSAxMIIC
# IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0EasLRLGntDqrmBWsytXum9R
# /4ZwCgHfyjfMGUIwYzKomd8U1nH7C8Dr0cVMF3BsfAFI54um8+dnxk36+jx0Tb+k
# +87H9WPxNyFPJIDZHhAqlUPt281mHrBbZHqRK71Em3/hCGC5KyyneqiZ7syvFXJ9
# A72wzHpkBaMUNg7MOLxI6E9RaUueHTQKWXymOtRwJXcrcTTPPT2V1D/+cFllESvi
# H8YjoPFvZSjKs3SKO1QNUdFd2adw44wDcKgH+JRJE5Qg0NP3yiSyi5MxgU6cehGH
# r7zou1znOM8odbkqoK+lJ25LCHBSai25CFyD23DZgPfDrJJJK77epTwMP6eKA0kW
# a3osAe8fcpK40uhktzUd/Yk0xUvhDU6lvJukx7jphx40DQt82yepyekl4i0r8OEp
# s/FNO4ahfvAk12hE5FVs9HVVWcO5J4dVmVzix4A77p3awLbr89A90/nWGjXMGn7F
# QhmSlIUDy9Z2hSgctaepZTd0ILIUbWuhKuAeNIeWrzHKYueMJtItnj2Q+aTyLLKL
# M0MheP/9w6CtjuuVHJOVoIJ/DtpJRE7Ce7vMRHoRon4CWIvuiNN1Lk9Y+xZ66laz
# s2kKFSTnnkrT3pXWETTJkhd76CIDBbTRofOsNyEhzZtCGmnQigpFHti58CSmvEyJ
# cAlDVcKacJ+A9/z7eacCAwEAAaOCAZUwggGRMAwGA1UdEwEB/wQCMAAwHQYDVR0O
# BBYEFOQ7/PIx7f391/ORcWMZUEPPYYzoMB8GA1UdIwQYMBaAFO9vU0rp5AZ8esri
# kFb2L9RJ7MtOMA4GA1UdDwEB/wQEAwIHgDAWBgNVHSUBAf8EDDAKBggrBgEFBQcD
# CDCBlQYIKwYBBQUHAQEEgYgwgYUwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp
# Z2ljZXJ0LmNvbTBdBggrBgEFBQcwAoZRaHR0cDovL2NhY2VydHMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0VHJ1c3RlZEc0VGltZVN0YW1waW5nUlNBNDA5NlNIQTI1NjIw
# MjVDQTEuY3J0MF8GA1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGluZ1JTQTQwOTZTSEEyNTYy
# MDI1Q0ExLmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJ
# KoZIhvcNAQELBQADggIBAGUqrfEcJwS5rmBB7NEIRJ5jQHIh+OT2Ik/bNYulCrVv
# hREafBYF0RkP2AGr181o2YWPoSHz9iZEN/FPsLSTwVQWo2H62yGBvg7ouCODwrx6
# ULj6hYKqdT8wv2UV+Kbz/3ImZlJ7YXwBD9R0oU62PtgxOao872bOySCILdBghQ/Z
# LcdC8cbUUO75ZSpbh1oipOhcUT8lD8QAGB9lctZTTOJM3pHfKBAEcxQFoHlt2s9s
# XoxFizTeHihsQyfFg5fxUFEp7W42fNBVN4ueLaceRf9Cq9ec1v5iQMWTFQa0xNqI
# tH3CPFTG7aEQJmmrJTV3Qhtfparz+BW60OiMEgV5GWoBy4RVPRwqxv7Mk0Sy4QHs
# 7v9y69NBqycz0BZwhB9WOfOu/CIJnzkQTwtSSpGGhLdjnQ4eBpjtP+XB3pQCtv4E
# 5UCSDag6+iX8MmB10nfldPF9SVD7weCC3yXZi/uuhqdwkgVxuiMFzGVFwYbQsiGn
# oa9F5AaAyBjFBtXVLcKtapnMG3VH3EmAp/jsJ3FVF3+d1SVDTmjFjLbNFZUWMXuZ
# yvgLfgyPehwJVxwC+UpX2MSey2ueIu9THFVkT+um1vshETaWyQo8gmBto/m3acaP
# 9QsuLj3FNwFlTxq25+T4QwX9xa6ILs84ZPvmpovq90K8eWyG2N01c4IhSOxqt81n
# MYIFHDCCBRgCAQEwQDAsMSowKAYDVQQDDCFBdXRoZW50aWNvZGUgQ29kZVNpZ25p
# bmdDZXJ0IDI1MDYCEFIOb6JgEauIRruOiug6kzkwDQYJYIZIAWUDBAIBBQCggYQw
# GAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGC
# NwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQx
# IgQg+j/JXLwGFSX9keStwEL5QyOz7fWEDSNmufb3XpTyhiAwDQYJKoZIhvcNAQEB
# BQAEggEAQjm1R1Y9iHnMSzCYxlMsw8Czd6wVgKBNiP4gv9JeebKqPfFVR3idcYy/
# TMY3/isaIB5ejwQGiZyO0xJBxJSJKYKWBUpGukB6kARIJvQ0tTFhJhAERTmQW0zD
# zuJpiuKww5OdOuWNM+bg8eal0JVJWQ85oiYfMlu8gutr1lF1hMTFZG8bBWUjxflr
# qDN7alUIFVZNbmV/EmMRKeYMX80ZJilv6suTcfv2SFtub67u5fh5pu5xGIkdk2G+
# SoNOav4LNUaXRvc7FkVbJY19E98H4hq0EYtlviTmuGfN3qrZobYPf/c6c3HGPPXH
# zYBBzhYET6pMR7aZ/YT2DLwUKfDwmqGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIID
# DwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFB
# MD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5
# NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIB
# BQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0y
# NjA0MTEwNjE5MjdaMC8GCSqGSIb3DQEJBDEiBCBpWPzFv/CirmADo8DyG+rXJxN6
# 7DCPu4nmoo7ubDOc1zANBgkqhkiG9w0BAQEFAASCAgA06fT9wZ1Lu0eLI91f0sOj
# OBeMMtCBtnkuikIrC/fmMY+7pIonttIhqrhwpWh1FwEryB9PyOVlhQJLDNHmmgv6
# Vcshzm3BkHuaYTqKeS1YKPUKzWsOOobPc5NNFok/6SLCJUo/6d218F8+tDJIfgf3
# XhBSk8GbH6ybz1JhKTzLv99+tpWcHha2LAQ/Q4pJ9qk9RV7HhbHXzq7KLl0sjnP+
# kat+FMekXm6Yjb/MJe0MaZCuwwrUCl+Y0pjEkn5dK4AusQqVz5w0bChwLMxs/aNO
# L2sWY7yD3IkW5AEaUHBe0xPkPRfSPiUifCrR0iFDdDoKkHz4d7tmKjyo83gJfbs0
# OLfZ6hDng+AsUtw9GUrW3yqNnzbKNiuSXh86ZOkvQhI0nKLkdBM+fhlHHjrZ7UeT
# fgtXV1d/47zNHyL90e02tpYKJ2dmgWtFBzAe4dgHo0du9801IwuhzsdowlmvpJhY
# yOGOq4LGe2hfZjvT2twTBszrDjkhw7Jp/Hyj7DB0z3ZnOL9RW1Q8qOH3lgAJnf+S
# rbPgIhwgkMwOfJf0mfMmCPO2EtT33yHLiXTPLL3wo1dzv9PLv/PiqYw5YtX1t8l7
# vmfq3qEvQMAAIyVYTZ4K+71H1WEbT03wuMmPFzkTGe2t1sQm4rmmo7Fu/ISZuSkP
# 2lD2xfIuYP75XecdzbLXYA==
# SIG # End signature block
