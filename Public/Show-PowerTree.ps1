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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBsTHfep6VAimPI
# 7564sPqP9GOQTWokY2mbFtjGuYsH66CCFnYwggM4MIICIKADAgECAhA1A5UPpKQt
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
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgbq/iZn9al1S0JZKeTZnAFrUCBw4j
# 8Q9W2PoaEpMofyMwDQYJKoZIhvcNAQEBBQAEggEAId+8oN2vqzA2fpUQidJSAPDf
# y5UBZ165D3peKYJFcuBQyNq4GdG3+dumv2sX+887RwSQtrx6v6oyMebPE5lN2zh1
# OLuC4azQtloqwDUO1Tu/npAyEFkzUUIUuXqqlO0aanC0JU8elXxMGcl6xK3Sw+Pp
# Kph7G3N7EEu2j9zEBgop0ofj2JyxX+FLyuXpdxCkIHqRiFbnL89lua9Mr11vF66v
# KaLR+h8O6LObHPwRT81I+5Ht3QSEMZo0KbLLUTGwhq/N7hFkecSOv8is0JV6po4u
# 6Q3HDL+LsD+lBygkYeGm9BMQFdoX1RK/4BOfT911VXK87Uquzij+S07DYCHou6GC
# AyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhL
# jfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjA0MjkxOTU4MjVaMC8GCSqGSIb3DQEJ
# BDEiBCDtX2Xf1UpAKdh5j55dpwjOC4JUlDy23tGPUo0Ox/8M/jANBgkqhkiG9w0B
# AQEFAASCAgBKyk5mHfLbe63ujT5Zpd7g3hXIfwmg/csF6g2BdfKiV9dOZA8GBxm4
# JyD2cd+zZFNgVKvCRBHwGhaWqkl1kjAdilbS/CDfOBmqr1Oc+RfGB7MSA2FSKUq3
# YPyUssH1zL/gEOAC2AF0uBnspAdx1CebG27ajEkIBRl6H74TkZ0vEdXmw4m5u50c
# zLf14+pfIsX+b8Jqhmkorf+9F3wQcdB323TOIv9+CRRIQDneBuH3LOfrERJmcZSC
# gH7vXqH7Hz+HPV0hBk0KXmbcIQeNvYsMGepQr2zqZNRQa274a16wmFvJMLETL2w6
# myuU0Y5IlbVExk/mP54NbRM/2n9f0oRUJZlQ4hAdiGAezfYZcTMFvrTfR0FhS/m1
# 3ljsBcS/2N4dSp/iuPdvUh2F9L4c4PCzsyupBbtkWp9J42OwPUg9AR/FdbZqYmdQ
# j2ilh70xuId2NsW9/FxY/BE3AmHvQBRZwWEAswYPRvWisfEEyEsr8YoYh1RmDY6Q
# twPurpD1My69wMfwuX3sVCYnWxueM3Xxry9Oe1I8YAgv93veELXgsHFNG+cb69SM
# 91gzWhPXG1SYc7tAytHRzO4sboQR/3rpo7kmnok5a1Q2+4dSXfJgtj8T97ELJEb8
# 4QMlg8ZTW0H6HdJM5bLDgRCHnmArm+zIV1yi3i9CqekYYgX7af6HlQ==
# SIG # End signature block
