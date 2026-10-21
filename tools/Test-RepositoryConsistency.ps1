<#PSScriptInfo
.VERSION 2026.10.20.2300
.GUID 8E92F731-C034-4C3D-882E-B71589CEE72B
.AUTHOR Scott T Surber
.COMPANYNAME STS Consulting
.COPYRIGHT CC BY-NC-SA 󱤹 2026 By STS
.REQUIREDMODULES
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.PROJECTURI https://github.com/STS-Consulting/PowerShell
.LICENSEURI https://creativecommons.org/licenses/by-nc-sa/4.0/
.ICONURI    https://github.com/STS-Consulting/PowerShell/raw/monad/Resources/STS.Consulting.png
.TAGS STS PowerShell QualityAssurance Consistency Changelog CI
.RELEASENOTES Validates repository consistency, Keep a Changelog 1.1.0 compliance, and CalVer alignment.
.PRIVATEDATA
.DESCRIPTION Validates repository consistency, licensing, metadata, code snippet syntax, and changelog updates.
#>

#Requires -Version 7.6
#Requires -PSEdition Core

<#
.SYNOPSIS
    Validates repository consistency across changelog, metadata, licensing, and documentation.

.DESCRIPTION
    Performs comprehensive repository consistency checks:
    1. Changelog format: Strict Keep a Changelog 1.1.0 compliance, Calendar Versioning (YYYY.0M.0D),
       ISO 8601 release dates, permitted change type categories, and anchor link definitions.
    2. Git checkin synchronization: Verifies that staged code changes include an update to .github/CHANGELOG.md.
    3. Metadata and licensing: Verifies standard URIs (.LICENSEURI, .PROJECTURI, .ICONURI) and
       synchronization between #Requires -Modules and .EXTERNALMODULEDEPENDENCIES.
    4. Code snippet validity: Verifies all PowerShell markdown code blocks parse without syntax errors.

.PARAMETER RootPath
    Path to the repository root directory. Defaults to the parent folder of this script.

.PARAMETER VerifyGitStaged
    When specified, inspects git staged files to verify that staged code changes are accompanied by
    a staged update to .github/CHANGELOG.md.

.PARAMETER RequireUnreleasedContent
    When specified, asserts that the ## [Unreleased] section in .github/CHANGELOG.md contains at least
    one bulleted change entry.

.PARAMETER FailOnError
    When specified, throws a terminating error if any consistency failure is detected.

.PARAMETER PassThru
    Outputs custom objects detailing each individual consistency check.

.EXAMPLE
    .\Test-RepositoryConsistency.ps1
    Executes standard repository consistency validation.

.EXAMPLE
    .\Test-RepositoryConsistency.ps1 -VerifyGitStaged -FailOnError
    Used in git pre-commit hooks or CI pipelines to block checkins that omit changelog updates.

.OUTPUTS
    PSCustomObject containing validation results when -PassThru is passed, or human-readable operational output.

.NOTES
    Adheres to STS-Consulting repository consistency policies and AI governance standards.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Position = 0)]
    [string]$RootPath = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path,

    [Parameter()]
    [switch]$VerifyGitStaged,

    [Parameter()]
    [switch]$RequireUnreleasedContent,

    [Parameter()]
    [switch]$FailOnError,

    [Parameter()]
    [switch]$ExitWithCode,

    [Parameter()]
    [switch]$PassThru
)

begin {
    $allowedCategories = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]@('Added', 'Changed', 'Deprecated', 'Removed', 'Fixed', 'Security'),
        [System.StringComparer]::OrdinalIgnoreCase
    )

    $repoLeaf = Split-Path -Path $RootPath -Leaf
    $canonicalLicense = 'https://creativecommons.org/licenses/by-nc-sa/4.0/'
    $canonicalProject = "https://github.com/STS-Consulting/$repoLeaf"
    $canonicalIcon    = "https://github.com/STS-Consulting/$repoLeaf/raw/monad/Resources/STS.Consulting.png"

    $results = [System.Collections.Generic.List[pscustomobject]]::new()

    function Add-CheckResult {
        param(
            [Parameter(Mandatory = $true)][string]$Category,
            [Parameter(Mandatory = $true)][string]$Target,
            [Parameter(Mandatory = $true)][string]$Check,
            [Parameter(Mandatory = $true)][bool]$Passed,
            [Parameter()][string]$Message = ''
        )

        $obj = [pscustomobject]@{
            Category = $Category
            Target   = $Target
            Check    = $Check
            Status   = if ($Passed) { 'Pass' } else { 'Fail' }
            Message  = $Message
        }

        $results.Add($obj)

        if (-not $Passed) {
            Write-Warning "[$Category] Failed: $Target - $Check ($Message)"
        }
        else {
            Write-Verbose "[$Category] Passed: $Target - $Check"
        }
    }
}

process {
    Write-Information -MessageData "Testing Repository Consistency at '$RootPath'..." -InformationAction Continue

    # # ## ### ##### ######### ############# ##################### ##################################
    # 1. Changelog Format & Keep a Changelog 1.1.0 Validation
    $changelogPath = Join-Path -Path $RootPath -ChildPath '.github\CHANGELOG.md'
    $changelogExists = Test-Path -LiteralPath $changelogPath
    Add-CheckResult -Category 'Changelog' -Target '.github/CHANGELOG.md' -Check 'FileExists' -Passed $changelogExists -Message 'CHANGELOG.md must exist in .github/'

    if ($changelogExists) {
        $changelogContent = Get-Content -LiteralPath $changelogPath -Raw
        $changelogLines = Get-Content -LiteralPath $changelogPath

        # Title check: must be "# Changelog"
        $hasStandardTitle = $changelogContent -match '(?m)^# Changelog\s*$'
        Add-CheckResult -Category 'Changelog' -Target '.github/CHANGELOG.md' -Check 'TitleFormat' -Passed $hasStandardTitle -Message 'Title must be exactly "# Changelog"'

        # Keep a Changelog 1.1.0 reference check
        $hasKacRef = $changelogContent -match '\[Keep a Changelog\]\(https://keepachangelog\.com/en/1\.1\.0/\)'
        Add-CheckResult -Category 'Changelog' -Target '.github/CHANGELOG.md' -Check 'KeepAChangelogReference' -Passed $hasKacRef -Message 'Must reference Keep a Changelog 1.1.0 URL'

        # CalVer reference check
        $hasCalVerRef = $changelogContent -match 'Calendar Versioning.*\(YYYY\.0M\.0D\)'
        Add-CheckResult -Category 'Changelog' -Target '.github/CHANGELOG.md' -Check 'CalendarVersioningReference' -Passed $hasCalVerRef -Message 'Must specify Calendar Versioning (YYYY.0M.0D)'

        # Unreleased section check: must have "## [Unreleased]"
        $hasUnreleased = $changelogContent -match '(?m)^## \[Unreleased\]\s*$'
        Add-CheckResult -Category 'Changelog' -Target '.github/CHANGELOG.md' -Check 'UnreleasedSectionExists' -Passed $hasUnreleased -Message 'Must have "## [Unreleased]" header'

        # Validate section types (### Category)
        $categoryMatches = [regex]::Matches($changelogContent, '(?m)^###\s+([A-Za-z]+)\s*$')
        $invalidCategories = [System.Collections.Generic.List[string]]::new()
        foreach ($m in $categoryMatches) {
            $catName = $m.Groups[1].Value
            if (-not $allowedCategories.Contains($catName)) {
                $invalidCategories.Add($catName)
            }
        }
        $validCategoriesOnly = ($invalidCategories.Count -eq 0)
        $invalidCatMsg = if (-not $validCategoriesOnly) { "Disallowed categories found: $($invalidCategories -join ', ')" } else { '' }
        Add-CheckResult -Category 'Changelog' -Target '.github/CHANGELOG.md' -Check 'ValidChangeTypeCategories' -Passed $validCategoriesOnly -Message $invalidCatMsg

        # Validate version release headers: ## [YYYY.0M.0D] - YYYY-MM-DD
        $versionMatches = [regex]::Matches($changelogContent, '(?m)^## \[([^\]]+)\](?:\s*-\s*(\S+))?\s*$')
        $invalidVersionHeaders = [System.Collections.Generic.List[string]]::new()
        $versionTags = [System.Collections.Generic.List[string]]::new()

        foreach ($vm in $versionMatches) {
            $verTag = $vm.Groups[1].Value
            $datePart = $vm.Groups[2].Value
            $versionTags.Add($verTag)

            if ($verTag -ieq 'Unreleased') {
                continue
            }

            # Must match YYYY.0M.0D
            $isCalVer = $verTag -match '^\d{4}\.\d{2}\.\d{2}$'
            # Must match YYYY-MM-DD ISO date
            $isIsoDate = $datePart -match '^\d{4}-\d{2}-\d{2}$'

            if (-not $isCalVer -or -not $isIsoDate) {
                $invalidVersionHeaders.Add("$verTag (Date: '$datePart')")
            }
        }
        $validVersionsOnly = ($invalidVersionHeaders.Count -eq 0)
        $invalidVerMsg = if (-not $validVersionsOnly) { "Invalid version headers: $($invalidVersionHeaders -join '; ')" } else { '' }
        Add-CheckResult -Category 'Changelog' -Target '.github/CHANGELOG.md' -Check 'ReleaseHeaderFormat' -Passed $validVersionsOnly -Message $invalidVerMsg

        # Validate anchor links at bottom
        $missingAnchors = [System.Collections.Generic.List[string]]::new()
        foreach ($tag in $versionTags) {
            $anchorRegex = "(?mi)^\[$([regex]::Escape($tag))\]:\s*https?://"
            if ($changelogContent -notmatch $anchorRegex) {
                $missingAnchors.Add($tag)
            }
        }
        $hasAllAnchors = ($missingAnchors.Count -eq 0)
        $missingAnchorMsg = if (-not $hasAllAnchors) { "Missing bottom link definitions for: $($missingAnchors -join ', ')" } else { '' }
        Add-CheckResult -Category 'Changelog' -Target '.github/CHANGELOG.md' -Check 'VersionLinkDefinitions' -Passed $hasAllAnchors -Message $missingAnchorMsg

        # Optional or conditional check: Unreleased content check
        if ($RequireUnreleasedContent) {
            $unreleasedBlock = if ($changelogContent -match '(?s)## \[Unreleased\](.*?)(?:## \[\d|\Z)') { $matches[1] } else { '' }
            $hasItems = $unreleasedBlock -match '(?m)^\s*-\s+\S+'
            Add-CheckResult -Category 'Changelog' -Target '.github/CHANGELOG.md' -Check 'UnreleasedHasContent' -Passed $hasItems -Message 'Unreleased section must contain bulleted change entries'
        }
    }

    # # ## ### ##### ######### ############# ##################### ##################################
    # 2. Git Staged / Pre-Commit Validation (when -VerifyGitStaged is specified)
    if ($VerifyGitStaged) {
        $isGitRepo = (git -C $RootPath rev-parse --is-inside-work-tree 2>$null) -eq 'true'
        if ($isGitRepo) {
            $stagedFiles = @(git -C $RootPath diff --cached --name-only)
            if ($stagedFiles.Count -gt 0) {
                $stagedCodeFiles = $stagedFiles | Where-Object {
                    $PSItem -match '\.(ps1|psm1|psd1|cs)$' -and $PSItem -notmatch '(^Documentation[/\\]|Test-RepositoryConsistency|^\.vscode[/\\])'
                } | Where-Object {
                    $fileDiff = git -C $RootPath diff --cached -I '^\s*#' -I '^\s*(\.VERSION|ModuleVersion)\b' -- $PSItem 2>$null
                    [bool]$fileDiff
                }

                if ($stagedCodeFiles.Count -gt 0) {
                    $changelogStaged = $stagedFiles | Where-Object { $PSItem -match 'CHANGELOG\.md$' }
                    $hasChangelogStaged = [bool]$changelogStaged
                    $stagedMsg = if ($hasChangelogStaged) {
                        "Changelog is staged alongside code changes ($($stagedCodeFiles.Count) files)"
                    }
                    else {
                        "Code files staged ($($stagedCodeFiles.Count) files: $($stagedCodeFiles -join ', ')), but .github/CHANGELOG.md was not staged for commit"
                    }
                    Add-CheckResult -Category 'GitCheckin' -Target '.github/CHANGELOG.md' -Check 'ChangelogStagedWithCodeChanges' -Passed $hasChangelogStaged -Message $stagedMsg
                }
                else {
                    Add-CheckResult -Category 'GitCheckin' -Target 'GitStaged' -Check 'ChangelogStagedWithCodeChanges' -Passed $true -Message 'No code modifications staged'
                }
            }
            else {
                Add-CheckResult -Category 'GitCheckin' -Target 'GitStaged' -Check 'ChangelogStagedWithCodeChanges' -Passed $true -Message 'No files staged for commit'
            }
        }
    }

    # # ## ### ##### ######### ############# ##################### ##################################
    # 3. Metadata & Licensing Consistency Validation
    $scriptsDir = Join-Path -Path $RootPath -ChildPath 'Scripts'
    if (Test-Path -LiteralPath $scriptsDir) {
        $scriptFiles = Get-ChildItem -Path $scriptsDir -Filter '*.ps1' -Recurse -File | Where-Object {
            $PSItem.FullName -notmatch '[/\\](Scripts\.Public|Archive|Check-UEFI)[/\\]'
        }

        $metadataFailures = [System.Collections.Generic.List[string]]::new()
        foreach ($sf in $scriptFiles) {
            $content = Get-Content -LiteralPath $sf.FullName -Raw
            if ($content -match '(?s)<#PSScriptInfo(.*?)#>') {
                $infoBlock = $matches[1]
                $hasLicense = $infoBlock -match "\.LICENSEURI\s+$([regex]::Escape($canonicalLicense))"
                $hasProject = $infoBlock -match "\.PROJECTURI\s+$([regex]::Escape($canonicalProject))"
                $hasIcon    = $infoBlock -match "\.ICONURI\s+$([regex]::Escape($canonicalIcon))"

                if (-not $hasLicense -or -not $hasProject -or -not $hasIcon) {
                    $metadataFailures.Add($sf.Name)
                }
            }
        }

        $metadataPassed = ($metadataFailures.Count -eq 0)
        $metaMsg = if (-not $metadataPassed) { "Inconsistent metadata URIs in: $(($metadataFailures | Select-Object -First 5) -join ', ')" } else { '' }
        Add-CheckResult -Category 'Metadata' -Target 'Scripts/' -Check 'CanonicalMetadataUris' -Passed $metadataPassed -Message $metaMsg
    }

    # # ## ### ##### ######### ############# ##################### ##################################
    # 4. Documentation PowerShell Code Snippet Validation
    $instructionsDir = Join-Path -Path $RootPath -ChildPath '.github\instructions'
    if (Test-Path -LiteralPath $instructionsDir) {
        $docFiles = Get-ChildItem -Path $instructionsDir -Filter '*.md' -File
        $snippetFailures = [System.Collections.Generic.List[string]]::new()

        foreach ($df in $docFiles) {
            $content = Get-Content -LiteralPath $df.FullName -Raw
            $codeMatches = [regex]::Matches($content, '```powershell\r?\n(.*?)\r?\n```', 'Singleline')
            foreach ($m in $codeMatches) {
                $code = $m.Groups[1].Value
                $tokens = $null; $errors = $null
                [void][System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$tokens, [ref]$errors)
                if ($errors.Count -gt 0) {
                    $snippetFailures.Add("$($df.Name) ($($errors.Count) parse errors)")
                }
            }
        }

        $snippetsPassed = ($snippetFailures.Count -eq 0)
        $snipMsg = if (-not $snippetsPassed) { "Syntax errors in code snippets: $($snippetFailures -join '; ')" } else { '' }
        Add-CheckResult -Category 'Documentation' -Target '.github/instructions/' -Check 'PowerShellSnippetSyntax' -Passed $snippetsPassed -Message $snipMsg
    }
}

end {
    $total = $results.Count
    $passed = ($results | Where-Object Status -EQ 'Pass').Count
    $failed = ($results | Where-Object Status -EQ 'Fail').Count

    Write-Information -MessageData "Repository Consistency Summary: Total=$total, Passed=$passed, Failed=$failed" -InformationAction Continue

    if ($PassThru) {
        $results
    }

    if ($failed -gt 0 -and $FailOnError) {
        throw "Repository consistency validation failed with $failed error(s)."
    }

    # Set process exit code for CLI / Git hook pipelines when requested
    if ($failed -gt 0 -and $ExitWithCode) {
        $host.SetShouldExit(1)
    }
}

# SIG # Begin signature block
# MIIcRAYJKoZIhvcNAQcCoIIcNTCCHDECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDm7h6KVUz8lPJN
# eq/XDo+2v8ajw5aHxfVFc+7gQom476CCFnYwggM4MIICIKADAgECAhBq68etXxgs
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
# q8WhbaM2tszWkPZPubdcMIIG7TCCBNWgAwIBAgIQCE/cM09+RU7bww+P+ZIYNTAN
# BgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQs
# IEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5n
# IFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMB4XDTI2MDgwNTAwMDAwMFoXDTM3MTEw
# NDIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MTswOQYDVQQDEzJEaWdpQ2VydCBTSEEyNTYgUlNBNDA5NiBUaW1lc3RhbXAgUmVz
# cG9uZGVyIDIwMjYgMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALZ7
# pvLJ/s1K+NSbTGWz/TjGMPh8CQ6RucZCLv5anHzWJjF/NWJrFIhy24fcpKXlgRik
# y4WAawDfU3YP0BMxt9l3Dm5oCG5Z69AqEN1kgHg2epx+l+lZBcmJCcN0ASURML5u
# FIS80sZsDwO3BSkUxDjLJhBI+qiZP3aixAC/qEGLjsBNlLol9VZ7pfGEXiMlneJI
# C5/YKuizVzNFKZZEeoy/0B8Zm+nzKBgSWG52lCO1w+nCg6XpCtklTJXeIg283hw7
# TmmsZXR+SMbjbrEOvZ3fP2VxIgeR28Y90ZStd3F9VuA5RVynb/whITPAo9b75Zr4
# Ta6Mj3URm26QZYMn/FnbuTegcoRcFEZ9FOqM5T6MTdtr/n74lIT/ug0eeOzmZ6QT
# Fg33otX+bFRsIolvykE1jive4PuESaT8zzVeFWDAMDtozNgLctkGD1ZjkEyZtJrL
# l5ya0m5doH/ScpaZCZVl6pNUOCybMc/kxC6EAmSJY24L0yYKD1Nkddsnb/ItVKi/
# 2nXpQNMu1PT5prW83vV8d67WowuUs0HdY4H8AMLGvdL/WHEj3ZnqMqAQQP9u3Ai9
# t+5eQ02GDwy0ODjdzi0xlp70W+ow63/0++YDEX1M0iwgUHwbrJvfpklkZQvw3+kv
# 3vUPItdwroczk9icflf55W1zOEKAcJVAIXpcMCU9AgMBAAGjggGVMIIBkTAMBgNV
# HRMBAf8EAjAAMB0GA1UdDgQWBBQUyWOKMC7USvtulPPm40B+9ezN4jAfBgNVHSME
# GDAWgBTvb1NK6eQGfHrK4pBW9i/USezLTjAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0l
# AQH/BAwwCgYIKwYBBQUHAwgwgZUGCCsGAQUFBwEBBIGIMIGFMCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXQYIKwYBBQUHMAKGUWh0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGlu
# Z1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNydDBfBgNVHR8EWDBWMFSgUqBQhk5odHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3RhbXBp
# bmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIw
# CwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQCNxTphHp1SCt+ZrAmAfn0o
# QLFr0mLywSLaDXQIENoyKqxrFbJblzCVP/pkXmwXOdrOpWygLzlT12os5ipDCy35
# RBCg2UMeApEtrfGhz45F4Wt4WGdNdIbRWt3YTYJmpR+b7lr4d7Uwn+H600u4D7Rn
# OGf8Wj4UNgAdZkfHhHv1mx9EVh71SJelcEN/oORSjXzdjfw1iZH9d8Nh/thn6hH2
# 3d+VsPAr6GAYyzSA02nXD1nYLI7Ijmiv+xLCiYC41DSFYL3GhTiy0PxpawPtGRya
# BVGzq+UiTfM8pD7KVyF5aQyWP4KhVGUUTnmm/RlYJoW3TiXA/+t0YcT2oRVBm3JE
# TjajHug2AL+v5jhtKVnd3D0rbHXEu27o+Q8p4sEWPMqKDB+qbceb6T/6WcwTwXmQ
# 9lOCLLYcsQeSWmvKqzpAec9etE14jOQAzLKWdE3w/TCaKtLRaRT7LCkRYVnhA2D7
# 3FLje1O5b3HR5eHs0NzU/+xX7NbEdcofy0W3Wdwd1XOqtlpg/JgwtKfZM5dqO94l
# bUveOiJBI+xZEbGRsMNbXmMREUTgu+Oca7Y73MPWcslIx2VhkSKSXjDbD6rgg39H
# 5Mh7QfieAIjWagkJNt68Yfim6cjEzVSiLSeZfdkr5dtFPTW6jATlWJdYeeDRGCya
# tf8R1hSjzSvdN8yWQPT9gzGCBSQwggUgAgEBMEgwNDEyMDAGA1UEAwwpQXV0aGVu
# dGljb2RlIENvZGVTaWduaW5nQ2VydCAyNjA4LjMwLjIxMzkCEGrrx61fGCyXQjNS
# caeuJdgwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKA
# ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg/RbstO5pRoE70jQ1qONMiJnG+4ig
# lZN6K2JqNEQATwEwDQYJKoZIhvcNAQEBBQAEggEAZS2UGo6uVmxv7HqJlGCNaC9+
# OVu8gIM+LZhjY5O4s4f6m+nt7vzNQTbDua2mcUynV2H9Rh+x7KEK8MpNch6WQVSJ
# Dn44Py9/YY7QhUqc9jVQEHPp0MPutxB5vrQHJas0u1YLTAwJ6U6A7sVXq8JHpVVG
# 2X99rLgeceqov+nA4Ax5bEjNeZtq/IAL4+dqVjK6zw2v25CI7Vgi1vB3YkcJuv7J
# l48KdYJ/oskeFY9icF0QYB4EB5xn5bjI4vbcb4KbAFIjzfpBcAEDCZ/FTgwHLrke
# AZ7rD3H98ZEjVdGL1bzqX3Cozf1K6oR5dA2aOPeNAXk04IT3L8PLX6o5E87lBqGC
# AyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAhP3DNP
# fkVO28MPj/mSGDUwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjEwMjEwNjEwMjFaMC8GCSqGSIb3DQEJ
# BDEiBCD0edZzHPh9nBGRn88bSfrrwQEDeVaSQ+poh4CjF286ETANBgkqhkiG9w0B
# AQEFAASCAgAopAqmaThZoDlnReD23n4IW/flKVUAqL+AE8OBOrDqQVTjUb+Nhlet
# 4Dn29lJLdS7JQyh27zU+CaNOKIKRR9PcRq3Y3WzY6Kfb+YcQKZkQeGXCb2Eoi0bY
# jToZlNIFQWZidpObmBXxaYhtCX2mtj0LMKraGLhfGYd0GS74i+OkT4et2sm0Qhp3
# Jqw4Z1Co4aju2/7ExTd4uirsBWAUb4tFlo78jdRqofCJZxsZ1JhgSTVFXqcvJAZs
# vO+FXP06n0JZHZuN9mBa4Vi+021/V82W6c3hpu1XuPoBairTR+eDgDwcJCrwP2yV
# J7MyhHsx36S0aLp5hwc4C3i6Y1VovRj/NmQSs7LBhi6E+AXtpU9dCBr0soXwnZ8E
# g8CmWs4AsgtsycYbYjRF7LUmnJBmMof3GdvdO1b6l970wGEbBKX/gio9gJplgwho
# 3RSlMHrtL88PRJLGJMFAs1+cWM92yE1h6kZjaY2dE9h8CO0NW6lh8tR8AzR6Lfey
# aNFBivM/bep3M7PFc369vmadybVh4AMm3uEMWaGA8TE7aQYfywzPz0bo8TJ77xqG
# J/ZjCIbLGccWdwEPF4vUFu1HjkWjOkunx9OoSmW5J8CGdEMTdTZB4tQzTzYPmnLA
# 6tQCVOzSi306ySOCqsTFa5pdVtJrCXVFOCGWJiENYIejZFCn7hnbbw==
# SIG # End signature block
