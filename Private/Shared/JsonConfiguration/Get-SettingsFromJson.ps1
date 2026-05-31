function Get-SettingsFromJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('FileSystem', 'Registry')]
        [string]$Mode,

        [string[]]$ConfigurationPaths = (Get-ConfigurationPaths)
    )

    $defaultSettings = Get-DefaultConfiguration

    try {
        Write-Verbose -Message 'Searching for configuration files in the following locations:'
        foreach ($path in $ConfigurationPaths) {
            Write-Verbose -Message "  - $path"

            if (Test-Path $path) {
                $fileContent = Get-Content -Path $path -Raw -ErrorAction Stop
                $settings = $fileContent | ConvertFrom-Json -ErrorAction Stop

                Write-Verbose -Message "Settings loaded from $path"

                # Base hashtable with shared settings
                $settingsHashtable = @{
                    ShowConnectorLines     = if ($null -ne $settings.Shared.ShowConnectorLines) { $settings.Shared.ShowConnectorLines } else { $defaultSettings.Shared.ShowConnectorLines }
                    ShowExecutionStats     = if ($null -ne $settings.Shared.ShowExecutionStats) { $settings.Shared.ShowExecutionStats } else { $defaultSettings.Shared.ShowExecutionStats }
                    ShowConfigurations     = if ($null -ne $settings.Shared.ShowConfigurations) { $settings.Shared.ShowConfigurations } else { $defaultSettings.Shared.ShowConfigurations }
                    LineStyle              = if ($settings.Shared.LineStyle) { $settings.Shared.LineStyle } else { $defaultSettings.Shared.LineStyle }
                    OpenOutputFileOnFinish = if ($null -ne $settings.Shared.OpenOutputFileOnFinish) { $settings.Shared.OpenOutputFileOnFinish } else { $defaultSettings.Shared.OpenOutputFileOnFinish }
                }

                # Add mode-specific settings
                switch ($Mode) {
                    'FileSystem' {
                        $settingsHashtable += @{
                            MaximumDepth      = if ($null -ne $settings.FileSystem.MaximumDepth) { $settings.FileSystem.MaximumDepth } elseif ($null -ne $settings.FileSystem.MaxDepth) { $settings.FileSystem.MaxDepth } else { $defaultSettings.FileSystem.MaximumDepth }
                            ExcludeDirectories = if ($settings.FileSystem.ExcludeDirectories -is [array]) { $settings.FileSystem.ExcludeDirectories } else { $defaultSettings.FileSystem.ExcludeDirectories }
                            HumanReadableSizes = if ($null -ne $settings.FileSystem.HumanReadableSizes) { $settings.FileSystem.HumanReadableSizes } else { $defaultSettings.FileSystem.HumanReadableSizes }
                            Files              = @{
                                ExcludeExtensions = if ($settings.FileSystem.Files.ExcludeExtensions -is [array]) { $settings.FileSystem.Files.ExcludeExtensions } else { $defaultSettings.FileSystem.Files.ExcludeExtensions }
                                IncludeExtensions = if ($settings.FileSystem.Files.IncludeExtensions -is [array]) { $settings.FileSystem.Files.IncludeExtensions } else { $defaultSettings.FileSystem.Files.IncludeExtensions }
                                FileSizeMinimum   = if ($settings.FileSystem.Files.FileSizeMinimum) { $settings.FileSystem.Files.FileSizeMinimum } else { $defaultSettings.FileSystem.Files.FileSizeMinimum }
                                FileSizeMaximum   = if ($settings.FileSystem.Files.FileSizeMaximum) { $settings.FileSystem.Files.FileSizeMaximum } else { $defaultSettings.FileSystem.Files.FileSizeMaximum }
                            }
                            Sorting            = @{
                                By          = if ($settings.FileSystem.Sorting.By) { $settings.FileSystem.Sorting.By } else { $defaultSettings.FileSystem.Sorting.By }
                                SortFolders = if ($null -ne $settings.FileSystem.Sorting.SortFolders) { $settings.FileSystem.Sorting.SortFolders } else { $defaultSettings.FileSystem.Sorting.SortFolders }
                            }
                        }
                    }
                    'Registry' {
                        $settingsHashtable += @{
                            MaximumDepth = if ($null -ne $settings.Registry.MaximumDepth) { $settings.Registry.MaximumDepth } elseif ($null -ne $settings.Registry.MaxDepth) { $settings.Registry.MaxDepth } else { $defaultSettings.Registry.MaximumDepth }
                            ExcludeKeys = if ($settings.Registry.ExcludeKeys -is [array]) { $settings.Registry.ExcludeKeys } else { $defaultSettings.Registry.ExcludeKeys }
                        }
                    }
                }

                Write-Verbose -Message ("Parsed $Mode Settings: " + ($settingsHashtable | ConvertTo-Json -Depth 5))
                return $settingsHashtable
            }
        }

        Write-Verbose -Message 'Configuration file not found in any of the potential locations. Using default settings.'
        return Get-FlattenedDefaultSettings -Mode $Mode -DefaultSettings $defaultSettings

    } catch {
        Write-Error "Error loading settings file: $($PSItem.Exception.Message)" -ErrorAction Continue
        Write-Verbose -Message 'Using default settings instead.'
        return Get-FlattenedDefaultSettings -Mode $Mode -DefaultSettings $defaultSettings
    }
}

function Get-FlattenedDefaultSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Mode,
        [Parameter(Mandatory = $true)]
        [hashtable]$DefaultSettings
    )

    $flattened = @{
        ShowConnectorLines = $DefaultSettings.Shared.ShowConnectorLines
        ShowExecutionStats = $DefaultSettings.Shared.ShowExecutionStats
        LineStyle          = $DefaultSettings.Shared.LineStyle
        Sorting            = $DefaultSettings.FileSystem.Sorting
    }

    switch ($Mode) {
        'FileSystem' {
            $flattened += @{
                MaximumDepth       = $DefaultSettings.FileSystem.MaximumDepth
                ExcludeDirectories = $DefaultSettings.FileSystem.ExcludeDirectories
                HumanReadableSizes = $DefaultSettings.FileSystem.HumanReadableSizes
                Files              = $DefaultSettings.FileSystem.Files
            }
        }
        'Registry' {
            $flattened += @{
                MaximumDepth    = $DefaultSettings.Registry.MaximumDepth
                DisplayValues   = $DefaultSettings.Registry.DisplayValues
                ExcludeKeys     = $DefaultSettings.Registry.ExcludeKeys
                ValueTypes      = $DefaultSettings.Registry.ValueTypes
                EscapeWildcards = $DefaultSettings.Registry.EscapeWildcards
            }
        }
    }

    return $flattened
}

# SIG # Begin signature block
# MIIcRAYJKoZIhvcNAQcCoIIcNTCCHDECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDTEyul/7oDgRVX
# eYjno0+0LPheHOGH3SnrQjTHDaBIg6CCFnYwggM4MIICIKADAgECAhAXnbjlqWZv
# uU+9AGMD/IcFMA0GCSqGSIb3DQEBCwUAMDQxMjAwBgNVBAMMKUF1dGhlbnRpY29k
# ZSBDb2RlU2lnbmluZ0NlcnQgMjYwNS4wNi4xMzI2MB4XDTI2MDUwNjIwMTYwNFoX
# DTI3MDUwNjIwMzYwNFowNDEyMDAGA1UEAwwpQXV0aGVudGljb2RlIENvZGVTaWdu
# aW5nQ2VydCAyNjA1LjA2LjEzMjYwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQDgmQPwmZ8pamXWV3OpU62nN4i0tWv+CBFIM7GzaPdaZe4vjp1a+oylSUQD
# 2lJUs9QdA5VZ1q4Jxq/pD2CFlTIS1ZTwdWkHHtxBXS+rI6InVSODffmXokV7tjw0
# dRlRi7PCLNmNQnr7IYp/ldJ8R0UvnMTEHgxg5OcIfqkN968kv4cyXOMgaSoLPp6m
# FgGOiD8CvJPyrptTh45OUhtIJuh6Rk2utfO5PcYrDDq7Ov7B5BmDVWvvJ3XyZEse
# 5c+GGVL+SWFO/+QDATanT8wUM+0v+t3qkuKc6jU9EwDi5etYUK69PfAeZWQBxXzH
# ZTf2EESlbXpwZvdvWqH1g8ebOj3xAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDAT
# BgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUGjEuXccQjyNJPpFvTGTa6Y1C
# LIcwDQYJKoZIhvcNAQELBQADggEBAJcEQMoDXuqpU+bNovJ52Weou2B5r9jYhh2R
# whY+2tOoVcK5TH1J6jFTydshZ8OuRLCVOV4dy4vgfHiGNKS7UzYphyu0uVYhkVH5
# t2rIaxtwFBi+QlkpxE6/akBrTmBYwuh0HDAdTzo7OjtjpKXjZKS1U8zRaSUXLiMK
# dTgZN6B5I1tLF3KdESndz3C2tZHZECuHKmTuhnibsXL3xLp3yJUL9ka+DZehpiJ2
# c8JkdiNEw4Dd2n5bKrVhRy/SqllvLmX4cmv4iSYDSVNSg8SrE8jER1jdhVa8DjW9
# wome0QT2RXNE2c67k+eUUGeJ3/gFuxnJMLAHrc7vHpa9qEVPxQIwggWNMIIEdaAD
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
# dGljb2RlIENvZGVTaWduaW5nQ2VydCAyNjA1LjA2LjEzMjYCEBeduOWpZm+5T70A
# YwP8hwUwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKA
# ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg+0REHVcLMvfxRdoZirG/NT44w5Ol
# ZLfUFm1IXdS8GBIwDQYJKoZIhvcNAQEBBQAEggEALN57eCjR68IdXHGntq8MDsUd
# yPfP4//YfbchHVNvx98re9X50K7ZCs9rGcIAoWrlN3ZvazGmckmCu8nGD9Wt7K9M
# uO20KwJ1A/UJNAL/3uH+tiq8WgRO/sRJpN/nEdxaFGI5X95eNgxkCurwtAJj7WYR
# T2HCBrqFKB2XqdkkBJjLwj5OmR23GcsgyYg9DJ1ymA5GkvJpL/tte/b7xPlZQnq5
# I3yunSUcsveaggB6bKdUETFS2/itbMRzRZXA4verqt7692F7tjcfAiTMfCaXCZjJ
# 2LWEIWlsWTwgSpVBnKxnk8MfXwxGDtrvK583DLxAEKLVxm0OyHmzXOeSOV71/6GC
# AyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhL
# jfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjA1MzEwNjE3NThaMC8GCSqGSIb3DQEJ
# BDEiBCDwtkkNNTLlZsfTH7bYlXXGOEoicBTsKN8Xidy7P6LLJzANBgkqhkiG9w0B
# AQEFAASCAgCgx1aL//c+M8YlHT5CAj2TSg4tR8x0sNi5DVsxKJAEeDPkv7rVq0eA
# 3HeNkN5gKJ78r2HvWSqycDLnT59E2QiWuRrH5eijxMQa65EMCK5QtVC9UvbZY12D
# QERni4QgQ9b2IcAoKD1y5Hun2+CSKrxphAa/mrh/61qENHb1tRPv/yw82iNCupov
# PvL3uysAcWvQTePHtubHB2klH8AWrjgy1MDsNAlMfozRi4CpiB9UpMGegxMHCqYZ
# plkjcX38hYEp0LgSvkMsZxFtqp7XPvmeg5uY9IUxIYHLgV1KLQNZuxFXUxMP+4JM
# zXAAb+7XwvfqjQvPwylifg1l2j5OI2uLij06aXlUy5L40lHCGFjjNRyZVfw4VNfC
# 0pH83UM1Ii1E6jBNjAzvJBQbUySTco0LKgN5e4xZJT0ilE3RzGoR9x9pITCZWAF1
# kEs4ExuAa52NjNWi2qvRUCR8DSkf2PV3F0x3RjEvgFqfn/mvkM/PwMp65lkZWnkQ
# d+4BUBmTjiUU1W62kArVWs3HbgtCwHpeU3369Zz1sMHqr/5LztIAlz2QX52lJ8v7
# uOTP3E7vKLcs9/IIb4anjjWTCbwhSO0ibA2O0o29N9AhPR4bwBBesALVLNVGjjbn
# zyAfrgEnOC60gLZlesa94c8YSLnIKSpu9lMSoY88GNInahGpH/Rs4Q==
# SIG # End signature block
