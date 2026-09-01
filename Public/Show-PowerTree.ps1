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
# MIIcRAYJKoZIhvcNAQcCoIIcNTCCHDECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCwL92t1QRURA9p
# j3LR693XoaAiiMIzuX4Ealk2snN58aCCFnYwggM4MIICIKADAgECAhBq68etXxgs
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
# dGljb2RlIENvZGVTaWduaW5nQ2VydCAyNjA4LjMwLjIxMzkCEGrrx61fGCyXQjNS
# caeuJdgwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKA
# ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgiSBVgG2rPisxiPiKZ5h6vFmSIGPQ
# ymxyEip2UvD1yl0wDQYJKoZIhvcNAQEBBQAEggEAWHUdtWr/c3y4DXr2edZB32ay
# OEgz+zYdvZ4EuLGx7xwgzD66BN/U0YaqWLAVF0pY4qTkemJjnQcQCyF4bqwh4i0b
# swvb4ZNmM7Y0gVhzeESUI+hyySzWTfJfGCYDsr0rnirM2eIgv/ek8oY0T2nLinRn
# kaQo8aiR8RnahjfxK4qGQTZILnlPKgRtgepiw7r1sF4fo3iojvGwNRjfizncMJXt
# v3oNkmlZU7TytqXTn9Qf6p8Z6CyYABWjXBcTdaVPgwl07VpY7MPDgMpHqMZXT9qy
# 2UEf9J0/vkvE7mZAovlwfSU1TA0sbfs913A5GvkVoD5WnvIYOxNWwhqLMvzyRKGC
# AyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhL
# jfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjA5MDEyMTE3MTJaMC8GCSqGSIb3DQEJ
# BDEiBCANS+Fa4yI+rmUJn6XxIC00wSc0xCY9ngWP3RTx7dv5VDANBgkqhkiG9w0B
# AQEFAASCAgDMKuuLQu9rsHPPj3DX5zUo3AbpooX4nsJPhe1Vk0U9Xw60V1OQdeDU
# ouSrtYv7BHvTYVCZgCrhqTk1P5dBu6WNPAr6AWEyChRFjhkIutZkqUHKqFzZt41/
# aA7RS9Pa51Tkg01oLkKolewo1RjQ9zULn8OxxXKPH8117iuZfNCP1JU7E+hmZOs9
# KGAWKOJ2MdQW3lMs6/oQ/t1mJ42z6Y+PNh6qJR2WmkXfweegKAnWSEQbf0iEi+ni
# S96wtBRKCAesRBKtVXnHvyIFnLp96z2hARjFUGhftV8QY7JKAnXtsNGQxdwdtleL
# +W81me1CtWdLcVNbteuCGLNl8LZRztMUj3btIVnISyg/TmorYK3EKhSGSn2LLVi3
# bNO1XqaOXS2ahDgSMLV4wsjkM+neV7Hjzazv/72SZODfw+SlI4gjCVOIav5aZuo8
# EB1lZVJH7C+03IC0D/YYxHRTrdZFQKHY+/R0+0G9pn05RF1lGldNvdXe+dMIQHCY
# eEufYgnPilrF39JkyaQfrKiqeP+A+S3XlzmL/uzLFDeA3i7ZDYJOuH4MhCHXqrch
# F/75mu9vhksBdD4zaucgoSYyFMipvgz6XRikUKNW8NZhr2rxaU5AH3qbueUaPFXg
# zwxYf/ahL3Nu+3oNgitlxSespIktAexPWwQIcJ764CvgLIfP+1OvDQ==
# SIG # End signature block
