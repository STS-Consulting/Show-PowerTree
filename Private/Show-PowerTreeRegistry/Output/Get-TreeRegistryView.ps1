function Get-TreeRegistryView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [TreeRegistryConfig]$TreeRegistryConfiguration,
        [Parameter(Mandatory = $false)]
        [string]$CurrentPath = $TreeRegistryConfiguration.Path,
        [Parameter(Mandatory = $false)]
        [bool]$EscapeWildcards = $false,
        [Parameter(Mandatory = $false)]
        [string]$TreeIndent = '',
        [Parameter(Mandatory = $false)]
        [bool]$IsRoot = $true,
        [Parameter(Mandatory = $false)]
        [int]$CurrentDepth = 0,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[string]]$OutputCollection = $null,
        [Parameter(Mandatory = $false)]
        [RegistryStats]$Stats = $null
    )

    if ($IsRoot -and $null -eq $Stats) {
        $Stats = [RegistryStats]::new()
    }

    if ($null -ne $Stats) {
        $Stats.UpdateDepth($CurrentDepth)
    }

    # Only escape if we're in a recursive call
    $pathToUse = if ($EscapeWildcards) {
        $CurrentPath -replace '\*', '[*]' -replace '\?', '[?]'
    } else {
        $CurrentPath
    }

    $collectingOutput = $null -ne $OutputCollection

    if ($IsRoot) {
        if ($collectingOutput) {
            $OutputCollection.Add('Type         Hierarchy')
            $OutputCollection.Add($TreeRegistryConfiguration.lineStyle.RegistryHeaderSeparator)
            $keyName = Split-Path $CurrentPath -Leaf
            $OutputCollection.Add("Key          $TreeIndent$keyName")
        } else {
            if ($null -ne $global:PSStyle -and $null -ne $global:PSStyle.Formatting -and $null -ne $global:PSStyle.Formatting.TableHeader) {
                $headerColor = $global:PSStyle.Formatting.TableHeader
                $resetColor = $global:PSStyle.Reset
                Write-Host "$headerColor`Type         Hierarchy$resetColor"
                Write-Host "$TreeRegistryConfiguration.lineStyle.RegistryHeaderSeparator"
                $keyName = Split-Path $CurrentPath -Leaf
                Write-Host "Key          $TreeIndent$keyName"
            } else {
                Write-Host 'Type         Hierarchy' -ForegroundColor Magenta
                Write-Host $TreeRegistryConfiguration.lineStyle.RegistryHeaderSeparator
                $keyName = Split-Path $CurrentPath -Leaf
                Write-Host "Key          $TreeIndent$keyName"
            }
        }
    }

    if ($TreeRegistryConfiguration.MaximumDepth -ne -1 -and $CurrentDepth -ge $TreeRegistryConfiguration.MaximumDepth) {
        if ($IsRoot) {
            return $Stats
        }
        return
    }

    $registryItemsParameters = @{
        RegistryPath         = $pathToUse
        DisplayItemCounts    = $TreeRegistryConfiguration.DisplayItemCounts
        SortValuesByType     = $TreeRegistryConfiguration.SortValuesByType
        SortDescending       = $TreeRegistryConfiguration.SortDescending
        UseRegistryDataTypes = $TreeRegistryConfiguration.UseRegistryDataTypes
        Exclude              = $TreeRegistryConfiguration.Exclude
        Include              = $TreeRegistryConfiguration.Include
    }
    $allItems = Get-RegistryItems @registryItemsParameters

    if ($null -ne $Stats) {
        $keyCount = ($allItems | Where-Object { $PSItem.TypeName -eq 'Key' }).Count
        $valueCount = ($allItems | Where-Object { $PSItem.TypeName -ne 'Key' }).Count

        $Stats.KeysProcessed += $keyCount
        $Stats.ValuesProcessed += $valueCount
    }

    foreach ($item in $allItems) {
        if ($item.isLast) {
            $itemPrefix = "$TreeIndent$($TreeRegistryConfiguration.lineStyle.LastBranch)"
            $newTreeIndent = "$TreeIndent$($TreeRegistryConfiguration.lineStyle.Space)"
        } else {
            $itemPrefix = "$TreeIndent$($TreeRegistryConfiguration.lineStyle.Branch)"
            $newTreeIndent = "$TreeIndent$($TreeRegistryConfiguration.lineStyle.VerticalLine)"
        }

        if ($item.TypeName -eq 'Key') {
            # Count information is for when DisplayItemCounts is true
            $countInformation = ''
            if ($TreeRegistryConfiguration.DisplayItemCounts) {
                $countInformation = " ($($item.SubKeyCount) keys, $($item.ValueCount) values)"
            }

            if ($collectingOutput) {
                $OutputCollection.Add("$($item.TypeName.PadRight(12)) $itemPrefix$($item.Name)$countInformation")
            } else {
                Write-Host "$($item.TypeName.PadRight(12)) $itemPrefix$($item.Name)" -NoNewline

                if ($null -ne $global:PSStyle -and $null -ne $global:PSStyle.Formatting) {
                    # Use FormatAccent or Verbose for metadata like counts
                    $countColor = if ($null -ne $global:PSStyle.Formatting.FormatAccent) { $global:PSStyle.Formatting.FormatAccent } else { $global:PSStyle.Formatting.Verbose }
                    $resetColor = $global:PSStyle.Reset
                    Write-Host "$countColor$countInformation$resetColor"
                } else {
                    Write-Host $countInformation -ForegroundColor DarkCyan
                }
            }

            Get-TreeRegistryView -TreeRegistryConfiguration $TreeRegistryConfiguration -CurrentPath $item.Path -EscapeWildcards $true -TreeIndent $newTreeIndent -IsRoot $false -CurrentDepth ($CurrentDepth + 1) -OutputCollection $OutputCollection -Stats $Stats

        } else {
            # Writing the subkey
            if ($collectingOutput) {
                if (-not $TreeRegistryConfiguration.NoValues) {
                    $OutputCollection.Add("$($item.TypeName.PadRight(12)) $itemPrefix$($item.Name) = $($item.Value)")
                } else {
                    $OutputCollection.Add("$($item.TypeName.PadRight(12)) $itemPrefix$($item.Name)")
                }
            } else {
                Write-Host "$($item.TypeName.PadRight(12)) $itemPrefix" -NoNewline

                if ($null -ne $global:PSStyle -and $null -ne $global:PSStyle.Foreground) {
                    $nameColor = $global:PSStyle.Foreground.BrightBlack
                    $valueColor = $global:PSStyle.Foreground.Yellow
                    $resetColor = $global:PSStyle.Reset

                    Write-Host "$nameColor$($item.Name)$resetColor" -NoNewline
                    if (-not $TreeRegistryConfiguration.NoValues) {
                        Write-Host ' = ' -NoNewline
                        Write-Host "$valueColor$($item.Value)$resetColor"
                    } else {
                        Write-Host ''
                    }
                } else {
                    Write-Host $item.Name -ForegroundColor DarkGray -NoNewline
                    if (-not $TreeRegistryConfiguration.NoValues) {
                        Write-Host ' = ' -NoNewline
                        Write-Host $item.Value -ForegroundColor Yellow
                    } else {
                        Write-Host ''
                    }
                }
            }
        }
    }

    if ($IsRoot) {
        return $Stats
    }
}
