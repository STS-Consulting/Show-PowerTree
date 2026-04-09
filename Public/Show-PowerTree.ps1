function Show-PowerTree {
    <#
    .SYNOPSIS
        Displays a directory tree with advanced filtering and sorting options.

    .DESCRIPTION
        The Show-PowerTree cmdlet (alias ptree) generates a visual representation of a directory structure.
        It supports filtering by file size, extensions, and dates, as well as sorting by various criteria.
        It can also export the output to a file and display execution statistics.

    .PARAMETER LiteralPath
        The path to the directory to visualize. Defaults to the current directory.

    .PARAMETER Depth
        The maximum depth of the tree to display. Defaults to -1 (no limit) or the value in the configuration file.

    .PARAMETER PruneEmptyFolders
        If set, empty folders (or folders that become empty after filtering) are not displayed.

    .PARAMETER DisplayAll
        Enables display of all file attributes: CreationDate, LastAccessDate, ModificationDate, Size, and Mode.

    .PARAMETER DisplayMode
        Displays the file/directory mode (attributes).

    .PARAMETER DisplaySize
        Displays the size of Files and Directories.

    .PARAMETER DisplayModificationDate
        Displays the Last Modification Date.

    .PARAMETER DisplayCreationDate
        Displays the Creation Date.

    .PARAMETER DisplayLastAccessDate
        Displays the Last Access Date.

    .PARAMETER DirectoryOnly
        Displays only Directories, excluding Files.

    .PARAMETER ExcludeDirectories
        An array of Directory Names or patterns to exclude.

    .PARAMETER Sort
        Specifies the sorting criteria: 'Size', 'Name', 'ModificationDate', 'CreationDate', 'LastAccessDate'.

    .PARAMETER SortByModificationDate
        Sorts items by Last Modification Date.

    .PARAMETER SortByCreationDate
        Sorts items by Creation Date.

    .PARAMETER SortByLastAccessDate
        Sorts items by Last Access Date.

    .PARAMETER SortBySize
        Sorts items by Size.

    .PARAMETER SortByName
        Sorts items by Name.

    .PARAMETER Descending
        Sorts items in descending order.

    .PARAMETER FileSizeMinimum
        Excludes Files smaller than the specified size

    .PARAMETER FileSizeMaximum
        Excludes Files larger than the specified size.

    .PARAMETER FileSizeFilter
        Alias for FileSizeFilter. # (seems duplicate purpose, maybe legacy).

    .PARAMETER ExcludeExtensions
        Excludes files with specified extensions.

    .PARAMETER IncludeExtensions
        Includes only files with specified extensions.

    .PARAMETER ShowHiddenFiles
        Forces display of Hidden Files and Directories.

    .PARAMETER OutFile
        Writes the output to the specified file.

    .EXAMPLE
        Show-PowerTree

        Show all Files and Directories in current path.

    .EXAMPLE
        Show-PowerTree C:\Projects\MyApp

        Show Files and Directories in specified path.

    .EXAMPLE
        Show-PowerTree -Depth 2

        Limit display to 2 Directory levels.

    .EXAMPLE
        Show-PowerTree -PruneEmptyFolders

        Remove empty folders from the tree.

    .EXAMPLE
        Show-PowerTree -DirectoryOnly

        Show only directories, no files.

    .EXAMPLE
        Show-PowerTree -ExcludeDirectories node_modules,bin,obj

        Exclude specified directories.

    .EXAMPLE
        Show-PowerTree -IncludeExtensions md,markdown,ipynb

        Show only Markdown and Jupyter Notebook files.

    .EXAMPLE
        Show-PowerTree -ExcludeExtensions dll,exe,bin,com,bat,cmd

        Exclude DLL, executable, binary Files.

    .EXAMPLE
        Show-PowerTree -ShowHiddenFiles

        Show hidden Files and Directories.

    .EXAMPLE
        Show-PowerTree -FileSizeMinimum 1MB

        Show only Files larger than 1MB.

    .EXAMPLE
        Show-PowerTree -FileSizeMaximum 500KB

        Show only Files smaller than 500KB.

    .EXAMPLE
        Show-PowerTree -SortBySize

        Sort by File Size (ascending).

    .EXAMPLE
        Show-PowerTree -SortBySize -Descending

        Sort by File Size (descending).

    .EXAMPLE
        Show-PowerTree -SortByModificationDate

        Sort by Last Modification Date.

    .EXAMPLE
        Show-PowerTree -DisplaySize

        Display File Sizes in human-readable format.

    .EXAMPLE
        Show-PowerTree -DisplayModificationDate

        Display modification dates.

    .EXAMPLE
        Show-PowerTree -OutFile tree_output.txt

        Save output to tree_output.txt.

    .EXAMPLE
        Show-PowerTree -DisplaySize -SortBySize -Depth 5 -ExcludeDirectories .next,node_modules

        Show file sizes sorted on file size, 5 levels deep, excluding .next and node_modules.

    .EXAMPLE
        Show-PowerTree -PruneEmptyFolders -Depth 3 -DisplaySize -SortBySize -Descending

        Prune empty folders, 3 levels deep, show sizes descending.

    .EXAMPLE
        Show-PowerTree -ExcludeDirectories extensions -IncludeExtensions ps1, psm1, psd1, pssc, psrc, psc1, ps1xml, cdxml

        Exclude specific dirs, show only PowerShell files.

    .EXAMPLE
        Show-PowerTree -ShowHiddenFiles -FileSizeMinimum 1MB -SortByModificationDate

        Show hidden files, files larger than 1MB, sorted by modification date.

    .EXAMPLE
        Show-PowerTree -DisplaySize -DisplayMode -DisplayModificationDate

        Show sizes, modes, mod dates.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$LiteralPath = '.',

        [Parameter()]
        [Alias('l', 'level')]
        [int]$Depth = -1,

        [Parameter()]
        [Alias('prune', 'p')]
        [switch]$PruneEmptyFolders,

        [Parameter()]
        [Alias('da')]
        [switch]$DisplayAll,

        [Parameter()]
        [Alias('dm', 'm')]
        [switch]$DisplayMode,

        [Parameter()]
        [Alias('s', 'size')]
        [switch]$DisplaySize,

        [Parameter()]
        [Alias('dmd')]
        [switch]$DisplayModificationDate,

        [Parameter()]
        [Alias('dcd')]
        [switch]$DisplayCreationDate,

        [Parameter()]
        [Alias('dla')]
        [switch]$DisplayLastAccessDate,

        [Parameter()]
        [Alias('d', 'dir')]
        [switch]$DirectoryOnly,

        [Parameter()]
        [Alias('e', 'exclude')]
        [string[]]$ExcludeDirectories = @(),

        [Parameter()]
        [ValidateSet('size', 'name', 'ModificationDate', 'CreationDate', 'LastAccessDate', 'md', 'cd', 'la')]
        [string]$Sort,

        [Parameter()]
        [Alias('smd')]
        [switch]$SortByModificationDate,

        [Parameter()]
        [Alias('scd')]
        [switch]$SortByCreationDate,

        [Parameter()]
        [Alias('sla', 'sld')]
        [switch]$SortByLastAccessDate,

        [Parameter()]
        [Alias('ss')]
        [switch]$SortBySize,

        [Parameter()]
        [Alias('sn')]
        [switch]$SortByName,

        [Parameter()]
        [Alias('des', 'desc')]
        [switch]$Descending,

        [Parameter()]
        [ValidateScript({
                # Validate format of lower bound size filter
                $PSItem -match '^\d+(?:\.\d+)?(b|kb|mb|gb|tb)?$'
            })]
        [Alias('fsmi')]
        [string]$FileSizeMinimum = '-1kb',

        [Parameter()]
        [ValidateScript({
                # Validate format of upper bound size filter
                $PSItem -match '^\d+(?:\.\d+)?(b|kb|mb|gb|tb)?$'
            })]
        [Alias('fsma')]
        [string]$FileSizeMaximum = '-1kb',

        [Alias('fs', 'filesize')]
        [string]$FileSizeFilter,

        [Parameter()]
        [Alias('ef')]
        [string[]]$ExcludeExtensions = @(),

        [Parameter()]
        [Alias('if')]
        [string[]]$IncludeExtensions = @(),

        [Parameter()]
        [Alias('force')]
        [switch]$ShowHiddenFiles,

        [Parameter()]
        [Alias('forceDirs', 'HiddenFolders')]
        [switch]$ShowHiddenFolders,

        [Parameter()]
        [Alias('o', 'of')]
        [string]$OutFile
    )



    if ($DisplayAll) {
        $DisplayCreationDate = $true
        $DisplayLastAccessDate = $true
        $DisplayModificationDate = $true
        $DisplaySize = $true
        $DisplayMode = $true
    }

    $treeStats = New-Object TreeStats

    # Ensure configuration file exists before loading settings
    Initialize-ConfigurationFile

    $jsonSettings = Get-SettingsFromJson -Mode 'FileSystem'

    $treeConfiguration = New-Object TreeConfig
    $treeConfiguration.Path = $LiteralPath
    $treeConfiguration.LineStyle = Build-TreeLineStyle -Style $jsonSettings.LineStyle
    $treeConfiguration.DirectoryOnly = $DirectoryOnly
    $excludedDirParameters = @{
        CommandLineExcludedDirectory = $ExcludeDirectories
        Settings                     = $jsonSettings
    }
    $treeConfiguration.ExcludeDirectories = Build-ExcludedDirectoryParameters @excludedDirParameters
    $sortingParameters = @{
        SortBySize             = $SortBySize
        SortByName             = $SortByName
        SortByCreationDate     = $SortByCreationDate
        SortByLastAccessDate   = $SortByLastAccessDate
        SortByModificationDate = $SortByModificationDate
        DefaultSort            = $jsonSettings.Sorting.By
        Sort                   = $Sort
    }
    $treeConfiguration.SortBy = Get-SortingMethod @sortingParameters
    $treeConfiguration.SortDescending = $Descending
    $treeConfiguration.SortFolders = $jsonSettings.Sorting.SortFolders
    $headerTableParameters = @{
        DisplayCreationDate     = $DisplayCreationDate
        DisplayLastAccessDate   = $DisplayLastAccessDate
        DisplayModificationDate = $DisplayModificationDate
        DisplaySize             = $DisplaySize
        DisplayMode             = $DisplayMode
        LineStyle               = $treeConfiguration.LineStyle
    }
    $treeConfiguration.HeaderTable = Get-HeaderTable @headerTableParameters

    $treeConfiguration.ShowConnectorLines = $jsonSettings.ShowConnectorLines
    $treeConfiguration.ShowHiddenFiles = $ShowHiddenFiles
    $treeConfiguration.MaximumDepth = if ($Depth -ne -1) { $Depth } else { $jsonSettings.MaximumDepth }
    $fileSizeParameters = @{
        CommandLineMaximumSize  = $FileSizeMaximum
        CommandlineMinimumSize  = $FileSizeMinimum
        SettingsLineMaximumSize = $jsonSettings.Files.FileSizeMaximum
        SettingsLineMinimumSize = $jsonSettings.Files.FileSizeMinimum
    }
    $treeConfiguration.FileSizeBounds = Build-FileSizeParameters @fileSizeParameters
    $treeConfiguration.OutFile = Add-DefaultExtension -FilePath $OutFile -IsRegistry $false

    $treeConfiguration.PruneEmptyFolders = $PruneEmptyFolders
    $treeConfiguration.HumanReadableSizes = $jsonSettings.HumanReadableSizes

    $outputBuilder = Invoke-OutputBuilder -TreeConfiguration $treeConfiguration -ShowExecutionStats $jsonSettings.ShowExecutionStats -ShowConfigurations $jsonSettings.ShowConfigurations

    # Main entry point
    $executionResultTime = Measure-Command {
        try {
            if (-not (Test-Path $LiteralPath)) {
                throw "Cannot find path '$LiteralPath'"
            }

            $ChildItemDirectoryParameters = Build-ChildItemDirectoryParameters -ShowHiddenFiles $ShowHiddenFiles -ShowHiddenFolders $ShowHiddenFolders
            $childItemFileParameters = @{
                ShowHiddenFiles             = $ShowHiddenFiles
                CommandLineIncludeExtension = $IncludeExtensions
                CommandLineExcludeExtension = $ExcludeExtensions
                FileSettings                = $jsonSettings.Files
            }
            $ChildItemFileParameters = Build-ChildItemFileParameters @childItemFileParameters

            if ($jsonSettings.ShowConfigurations) {
                Write-ConfigurationToHost -Configuration $treeConfiguration
            }

            $headerOutputParameters = @{
                HeaderTable   = $treeConfiguration.HeaderTable
                OutputBuilder = $outputBuilder
                LineStyle     = $treeConfiguration.LineStyle
            }
            Write-HeaderToOutput @headerOutputParameters

            $treeViewParameters = @{
                TreeConfiguration            = $treeConfiguration
                TreeStats                    = $treeStats
                ChildItemDirectoryParameters = $ChildItemDirectoryParameters
                ChildItemFileParameters      = $ChildItemFileParameters
                OutputBuilder                = $outputBuilder
            }
            Get-TreeView @treeViewParameters

        } catch {
            Write-Error "Details: $($PSItem.Exception.Message)"
            Write-Error "Location: $($PSItem.InvocationInfo.ScriptLineNumber), $($PSItem.InvocationInfo.PositionMessage)"
            Write-Verbose -Message "Exception details: $($PSItem | Format-List * -Force | Out-String)"
        }
    }

    if ($jsonSettings.ShowExecutionStats) {
        Show-TreeStats -TreeStats $treeStats -ExecutionTime $executionResultTime -OutputBuilder $outputBuilder -LineStyle $treeConfiguration.LineStyle -DisplaySize $DisplaySize
    }

    if ($null -ne $outputBuilder) {
        $outputBuilder.ToString() | Write-ToFile -FilePath $treeConfiguration.OutFile -OpenOutputFileOnFinish $jsonSettings.OpenOutputFileOnFinish

        $fullOutputPath = Resolve-Path $treeConfiguration.OutFile -ErrorAction SilentlyContinue
        if ($null -eq $fullOutputPath) {
            $fullOutputPath = $treeConfiguration.OutFile
        }

        Microsoft.PowerShell.Utility\Write-Information -MessageData ' ' -InformationAction Continue
        Microsoft.PowerShell.Utility\Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Output saved to: $($fullOutputPath)$($PSStyle.Reset)" -InformationAction Continue
    }

    Microsoft.PowerShell.Utility\Write-Information -MessageData ' ' -InformationAction Continue
}

# SIG # Begin signature block
# MIIcLAYJKoZIhvcNAQcCoIIcHTCCHBkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBsTHfep6VAimPI
# 7564sPqP9GOQTWokY2mbFtjGuYsH66CCFmYwggMoMIICEKADAgECAhBSDm+iYBGr
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
# IgQgbq/iZn9al1S0JZKeTZnAFrUCBw4j8Q9W2PoaEpMofyMwDQYJKoZIhvcNAQEB
# BQAEggEAtPHcqzBk1tQnao+ii9kvmcp4Ktci0Gvudg5PiedbIFq6nZqCq9XFS8AP
# OHBqxwWN9EU0cDGsjObd3nof4BaiJkx6BkLbSxCL7oyrKTC/a89GAFefMVYIteql
# lEHCyX86KrEFgj6Ba/1BQGwMBEis020QLoFOh6qtdS3khNBz/Bh4hLI6d0rWwNdi
# jtXExH/JsZjFEZGjVB7DAWnmmnn6n6BYI98uFvVbbRbgEAH6Pvnu6bqW5XJF6bRS
# +TPTSKOyw2P+MepTnzHO5lxZ9XDF91biGq6qYq0aJjUac7HelhzfmZVnFUmoebL8
# zGZ9sFtbpwUhI3seHREaDovdsEAxpaGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIID
# DwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFB
# MD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5
# NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIB
# BQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0y
# NjA0MDkwMjEyMTZaMC8GCSqGSIb3DQEJBDEiBCAgyXCX2ZySz0phYvp5PUEFcF+M
# 8mFazSPGljyj/W/UTjANBgkqhkiG9w0BAQEFAASCAgCfRdJBs1MNzZPC8eOlqgP+
# 2pULdUZXbjf320mv3D/x8C1lxWWSxBUtT4Qr7f4gy5hNsb9CirkfdDa8Ehbdj8AB
# Rl894Gwf5AdUf5v3j78kLYN1nxGuPXD7AC0rJ3G35mo5Qj8Hav+4lRyEKxln7n1Z
# 0Bi3iGAFaDM6Rv65h1yL/1EqeHAv3vN/IYeM5wsvdhxwROL8veXycgLheyOhw5G4
# XgbYcMwbPLZRwrseWZ3VhmGiNL0Igk8/allcqlEmkB+REeRgiWZaGZOpm5+tuYPt
# GPTlyx/JP6y06wfMwZlpfrKP6fEiV2Jsu9riN0GvX6sEnOG1Oz71BzLCYYmifOQs
# SWRiOj6kv1YyARPaK5KMMnw3pDy7li7O3vl9cIaQSv+mKK39iGkS910Jw2xyUSwr
# Y3n3tznLnHs6zlDUh4sJVaVj1a/nVFcbGuxP34Yy4OI4L2XrAC5wSwXru1BbM6kI
# cF2bpcXBU3zAyFc0Lp75WpYs8/hecbSOVctSNH+qrWMftb4A/CzVvs+WKLTxEeY6
# oZvvqM9/k6r/vTbHuZDX4330yJ+/4vtlKr6WqnHyY1FbuayuWQKT2O7nn/5/E5IL
# 7SUsC7iytQ2Et6EsB9vUYHk1sXNejVB7cEycAbmSMMeV9gEA93fRA2DFoIcPvlkq
# AJjFswzuHFTCiOvWa4Io2g==
# SIG # End signature block
