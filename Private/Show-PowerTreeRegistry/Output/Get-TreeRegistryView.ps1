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

# SIG # Begin signature block
# MIIcRAYJKoZIhvcNAQcCoIIcNTCCHDECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAF188MNlQSCUH1
# UYvCtMfzzHG67pVrxle8WkiJLdKl3qCCFnYwggM4MIICIKADAgECAhA1A5UPpKQt
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
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgyCC8rFQl2QV6zs0pnqUEcXvyJa/F
# tNK0JjbXOMRLnmIwDQYJKoZIhvcNAQEBBQAEggEAj0ji+Sx1lOlnfXWKq5Z9ICWr
# cqcSe0jHsfOQcOSW4ojzabHAikbjIlJs5sME4aCLcqjZZ7/Ay87BNWI5tw5hqrcg
# ODEq1LWUKOQDnMnNnOdHmcJoK95KtSb2ka+9vdLAcXubejBgHHmGwtxrsK2iA5FP
# jzBIhSchqDIQYgOfMInOAX1eOari9YQmprdvYPWd2SHCa9WKyuACQSG/zG5Xj54T
# jf2X0r8rfcnZBEf8pkm3Au4yVLJ3HoeaDwIprnw13/EkACKU0CC37/vPtfmaf2yQ
# QoZJuy589eGZa0Vlkd0k6cUuUJK6SaJ8sdgICrZsjmXwxmxK9/n8DXibjt16AqGC
# AyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhL
# jfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjA0MjgwMzU2MjRaMC8GCSqGSIb3DQEJ
# BDEiBCAIqLnW8ciegRsNz4xpCftfD48XLh2Q0nL3KO7bny2IgTANBgkqhkiG9w0B
# AQEFAASCAgC59ibouJcQdXG+H5dXfsq1MOD0WTaGzWgIubAHYxA30zTKnHnh6IYI
# /X3MukLmPCtW20pAsElm7xHkWeU9cr+TR+ebtIlqrX8L97p9cz1U4za5vuGITWu9
# StVM5o3oak5niE8oKO8eLKIrOavd2M2pQO0tZIbvgpsUV/txSzQW9hoB25tMuvni
# GYUqi2TrONViIqy6I31XBAxrEjEbEHJ8FBwDZYxSMkf2ORoneApqMTqUyusEYuNe
# 0OXmJsMmZbv2AE0S1R9WCEipuzVJjjlLCnD2vjAKrrQdNyM1u5cWRPhquGHWDDyj
# a8sSHfI2uCcN1/De84jVlaoH03xWFeTP5uj5DSSgGy64vW7bGgMYWjq9Fvqe86gL
# e6DH7EVyIO1bfysMOUhbhdbRClW1E3woafqCRW4tr/fzQChV7tyUaeXPHWTOJ9mL
# pwkiAIuWLTvrObExJndJT0wYBQhKcsTPjmL+9id/4Mi7+ybCx/ezbb+xi+hPCDIV
# BOhiqn7YIjaJDvMU5ml8sBenkBiyK+IM0A4Dg/vxZ55c+yt7ai2I8U8MvOPovNNt
# +wdptIITSTg0To4rojf6P9R5aHjU5Q1LyNa1zsfp2n4CHhOxIiDj3nD6KeLarQt6
# 9FTjR1Z0lZKM/znmDWNIYHzzP4TfkspF/X9XacdJUa5VtPATERqQvA==
# SIG # End signature block
