# Define script-level variables
$script:ModuleRoot = $PSScriptRoot
New-Alias -Name 'ptree' -Value 'Show-PowerTree'
New-Alias -Name 'PowerTree' -Value 'Show-PowerTree'
New-Alias -Name 'Start-PowerTree' -Value 'Show-PowerTree'
New-Alias -Name 'Edit-PtreeConfig' -Value 'Edit-PowerTreeConfiguration'
New-Alias -Name 'Edit-Ptree' -Value 'Edit-PowerTreeConfiguration'
New-Alias -Name 'Edit-PowerTree' -Value 'Edit-PowerTreeConfiguration'
New-Alias -Name 'ptreer' -Value 'Show-PowerTreeRegistry'
New-Alias -Name 'PowerRegistry' -Value 'Show-PowerTreeRegistry'

# Explicitly list files to import to avoid wildcard issues
# Order matters: Classes -> Constants/Enums -> Functions -> Public

# 1. Classes
$ClassesFile = Join-Path -Path $PSScriptRoot -ChildPath 'Private\Shared\DataModel\Classes.ps1'
if (Test-Path $ClassesFile) {
    try {
        . $ClassesFile
        Write-Verbose -Message "Imported class definitions from $ClassesFile"
    } catch {
        Write-Error "Failed to import class definitions from $ClassesFile`: $PSItem"
    }
} else {
    Write-Error "Critical: Classes file not found at $ClassesFile"
}

# 2. Private Functions (Explicit Order)
$PrivateFiles = @(
    # Configuration / Constants
    'Private\Show-PowerTree\Configuration\Constants.ps1',
    'Private\Shared\Build-TreeLineStyle.ps1',

    # Helpers needed early
    'Private\Show-PowerTree\Size\Conversion\Convert-ToBytes.ps1',
    'Private\Show-PowerTree\Filtering\Format-FileExtensions.ps1',
    'Private\Show-PowerTree\Size\Get-HumanReadableSize.ps1',
    'Private\Show-PowerTree\Size\Get-SizeColor.ps1',
    'Private\Show-PowerTree\Size\Get-FilesByFilteredSize.ps1',

    # Param Helpers
    'Private\Show-PowerTree\Configuration\ParamHelpers\Build-ChildItemDirectoryParameters.ps1',
    'Private\Show-PowerTree\Configuration\ParamHelpers\Build-ChildItemFileParameters.ps1',
    'Private\Show-PowerTree\Configuration\ParamHelpers\Build-ExcludeDirectoryParameters.ps1',
    'Private\Show-PowerTree\Configuration\ParamHelpers\Build-FileSizeParameters.ps1',

    # Output / Formatting
    'Private\Show-PowerTree\Output\Build-OutputLine.ps1',
    'Private\Show-PowerTree\Output\Get-TreeConfigurationData.ps1',
    'Private\Show-PowerTree\Output\Get-TreeView.ps1',
    'Private\Show-PowerTree\Output\Header\Get-HeaderTable.ps1',
    'Private\Show-PowerTree\Output\Header\Write-HeaderOutput.ps1',

    'Private\Show-PowerTree\Output\Show-TreeStats.ps1',
    'Private\Show-PowerTree\Output\ToFile\Invoke-OutputBuilder.ps1',
    'Private\Show-PowerTree\Output\ToFile\Write-ToFile.ps1',
    'Private\Show-PowerTree\Output\Write-OutputLine.ps1',

    # Sorting
    'Private\Show-PowerTree\Sorting\Get-SortingMethod.ps1',

    # Registry support
    'Private\Show-PowerTreeRegistry\Configuration\ParamHelpers\Get-Path.ps1',
    'Private\Show-PowerTreeRegistry\Filtering\Get-RegistryItems.ps1',
    'Private\Show-PowerTreeRegistry\Filtering\Set-LastItemFlag.ps1',
    'Private\Show-PowerTreeRegistry\Filtering\Test-FilterMatch.ps1',
    'Private\Show-PowerTreeRegistry\Output\Get-RegistryConfigurationData.ps1',
    'Private\Show-PowerTreeRegistry\Output\Get-TreeRegistryView.ps1',
    'Private\Show-PowerTreeRegistry\Output\Show-RegistryStats.ps1',
    'Private\Show-PowerTreeRegistry\Output\ToFile\Invoke-OutputBuilderRegistry.ps1',
    'Private\Show-PowerTreeRegistry\Sorting\Invoke-RegistryItemSorting.ps1',

    # Shared / Common
    'Private\Shared\DataModel\ClassLoader.ps1',
    'Private\Shared\Get-OneDriveStatus.ps1',
    'Private\Shared\JsonConfiguration\Get-ConfigurationPaths.ps1',
    'Private\Shared\JsonConfiguration\Get-DefaultConfiguration.ps1',
    'Private\Shared\JsonConfiguration\Get-SettingsFromJson.ps1',
    'Private\Shared\JsonConfiguration\Initialize-ConfigurationFile.ps1',
    'Private\Shared\Output\Add-DefaultExtension.ps1',
    'Private\Shared\Output\Convert-StatsInOutputFile.ps1',
    'Private\Shared\Output\Format-ExecutionTime.ps1',
    'Private\Shared\Output\Write-ConfigurationToHost.ps1'
)

foreach ($file in $PrivateFiles) {
    # Normalize path separators
    $relativePath = $file -replace '[\\/]', [System.IO.Path]::DirectorySeparatorChar
    $fullPath = Join-Path -Path $PSScriptRoot -ChildPath $relativePath
    if (Test-Path $fullPath) {
        try {
            . $fullPath
        } catch {
            Write-Error "Failed to import private function $file`: $PSItem"
        }
    } else {
        Write-Warning "Private function file not found: $file (Expected at: $fullPath)"
    }
}

# 3. Public Functions
$PublicFiles = @(
    'Public\Edit-PowerTreeConfiguration.ps1',
    'Public\Show-PowerTree.ps1',
    'Public\Show-PowerTreeRegistry.ps1'
)

foreach ($file in $PublicFiles) {
    # Normalize path separators
    $relativePath = $file -replace '[\\/]', [System.IO.Path]::DirectorySeparatorChar
    $fullPath = Join-Path -Path $PSScriptRoot -ChildPath $relativePath
    if (Test-Path $fullPath) {
        try {
            . $fullPath
        } catch {
            Write-Error "Failed to import public function $file`: $PSItem"
        }
    } else {
        Write-Warning "Public function file not found: $file (Expected at: $fullPath)"
    }
}

# Export public functions
Export-ModuleMember -Function 'Show-PowerTree', 'Edit-PowerTreeConfiguration', 'Show-PowerTreeRegistry'
Export-ModuleMember -Function 'Show-PowerTree', 'Edit-PowerTreeConfiguration', 'Show-PowerTreeRegistry' -Alias 'ptree', 'PowerTree', 'Start-PowerTree', 'Edit-PtreeConfig', 'Edit-Ptree', 'Edit-PowerTree', 'ptreer', 'PowerRegistry'

# SIG # Begin signature block
# MIIcRAYJKoZIhvcNAQcCoIIcNTCCHDECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAVKTHj+fm0zRVI
# Lg3yMTc7avVJoabD2/gRvC0eABVueaCCFnYwggM4MIICIKADAgECAhA1A5UPpKQt
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
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgAg6JpcSlbT+mOgjX8sBRunqOgstU
# X+ccrUh86v1wQ+UwDQYJKoZIhvcNAQEBBQAEggEAImW3uRQrq0cgua6uVjlwzaJ5
# 7BdPYCBGg9ALudxRt2a8876Yj0VTvNHSPbrovurJyo3sBW/ddfWIwTVb/ae/XRmX
# raBaAyUep2exE/CA4LHn2RiEGdMor/W7mh9k9C+qF9e0YSaLZUcNe9kCRyXBbxEA
# c9giP9hyglEUyEmy6j507jrUSm4h+t7pSa7tcybrY73DM1n4FUV208yKKoou/3AR
# zllk8zR/SEqJ8BbBmCB+q1FruIoqMjkAZAcH+OZ4PTTP33s2cZoChA4RoEj4PPHZ
# FPE7PlqbN677jY5pYQkt02lCeApR129FvJ5Wx/IDVPjellmkKtZjKiBftv1yz6GC
# AyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhL
# jfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjA0MjkxOTU4MjdaMC8GCSqGSIb3DQEJ
# BDEiBCAFWh6XmwlomxniJM6Op1vQIhy7H/hi5pgHgao1lJPGiDANBgkqhkiG9w0B
# AQEFAASCAgBmaaSBRQNI99V5y1HOBjz5IP7fsxIfVEgEXAMeW5h5FZgeeB084AM4
# aEj3y2x+LX1jRqPkaXttowgRfq2oUoRTq25fxjOVB3JZyrmgl9hKZUSpJ665PLTe
# 7yt9lCZKtgvXWF1NAuETNHxFcb6JYI14moEUQjAFmAtbzHSPavVvfEnB5bMZ3yX1
# A9AmQq6Fxb5Yjn2Zz70b4dbRM49c14Y0vtZs2tP5uqEK9lUyK7XLFL4Hyxmp/tH4
# w6VTqXMKh9QEc1X0s8hG7wphFO8UzYNQGJsUCDbKLJ7bSt1AwYte0Sm6LJO3wHSB
# 823/0ltNIXaDAjadx44FieMZBfXcDM7QLxXItlXZj7BJwj1Yb9SdEmFVHsP1UfUn
# IJShfLEhKoNgcxGsWl+3tmVSG5uSVJjAPhXNqibzdDicThbdqd5xZWLM8PiF3/09
# VfFQ2fnvwEL8MpIwPicMs6/ZHA/WgRJJsr/qvv4gbjMSfXENWtMa+dPE/sFtC4Qh
# G3k74awZnN1XcznmplFFsavt6+ZmQERzJMEco3mrJXnb5/ScSF4GpU+ZOYuX2acO
# ZuKxLEvyvcTY+58ioaLY5KVKITvNhSSLv4NCUd3mbCqfiw9BpnGGSdIZQTspwgzZ
# FUBwWB+JUXswPbTSEJDNYjZWggN6RRxNo7nD2rWEWaZfs3U+qRpsuw==
# SIG # End signature block
