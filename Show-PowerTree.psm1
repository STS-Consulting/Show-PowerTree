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
# MIIcLAYJKoZIhvcNAQcCoIIcHTCCHBkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAVKTHj+fm0zRVI
# Lg3yMTc7avVJoabD2/gRvC0eABVueaCCFmYwggMoMIICEKADAgECAhBSDm+iYBGr
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
# IgQgAg6JpcSlbT+mOgjX8sBRunqOgstUX+ccrUh86v1wQ+UwDQYJKoZIhvcNAQEB
# BQAEggEAPS7DYwrq/PJiYWwKzgMTDVuHIH/LTl/GtpaWajXvsI/FwmPvnlsQDVOz
# KqOfgAEAYnp1wzXVLkEm943w8DtO6Hvy/D4/VBbvkCFShHd86QaPhxAQgmKGpDsK
# 0Evz6oHS2H7Gsz332nN3W4N15QOCAKnE+vfqfVQbnis0VE15jJM70DaDZdHgT8iR
# XAmrzyeCDN7debxJtNFaaLTpFccxA/LYj4cQcwVeJWqa3j9hlyX8LDNWYel8JqVx
# mp0GlrrVzdjNp/JSfQhALjzmVorIxUWEjtOz7VJictL7sOBj4gnPXSV3Qqp7XGvH
# z+pBA6skxEiNheGTNB29ewsbWZzOIqGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIID
# DwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFB
# MD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5
# NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIB
# BQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0y
# NjAyMDMwNjU1NDJaMC8GCSqGSIb3DQEJBDEiBCDtFbcIq+dTgiLdhBpk0b/7nqJg
# gOV/QYtvV26hNJl/qjANBgkqhkiG9w0BAQEFAASCAgAd6OkPPYnUPe/RzJw++XAy
# +K7doSXY8DyH8HNFE+cxHQRL4dlwEOLR0N4S6Yu1QCUXbVuihba5ysnBJtj18Wqw
# 4PAiHEMGxiuDrFraNzX6DPe2TxIhJ/HBvP3CEzIw/JSRH6W76+1J9CH5xkrNg44D
# jbWIQ0AFstZPDxcrOPbq6RqbQoxAjSrKibyauQCjf5m/Obn/x9oCJ7TcE2uErZFO
# w4H37pXhUUNzSt/df+iCAbXEneO/A5b/rbU2eCMKyo0eYZ5WQvzUQ4RUxSn/Ou2v
# MFLZk+cnWOxNKvnOWWBoe8WEJn0V8q5anRyGo+nCKSkT6bZ6ZJ0XpAxmRbx/f3Tg
# L9en7JoymBv8tohVejTB10X8uv3jJkeL9buiD52Pox+s+A70BBzkpPovI/MeMco+
# 23XKpNJrIBCDNtZbyExcEkm1Soata2mEpQ2uKxXlZQA0Uwqp7mz62oVd81bSlG3e
# GS9WBD4NnlPC2rHzAceZpLs8tI9qTcGZAeVQJsqYABCa93AIf3q1OqikYo5d3INk
# hcoNL0/+XN8AWDYjHXhtzph2dGjhmY6Y6XLrOkI9m/nbgMRjNxuDblL019tSdp+j
# nQWNypQ89QYLL9bXCTK/nU2RFGpI2IdqUXiIkyP8SF4e1Bwh9RdY5J6vuVxlf1iS
# ul5sQFhmYYQBwcZ5Ppt65A==
# SIG # End signature block
