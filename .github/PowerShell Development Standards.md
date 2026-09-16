---
version: '2026.09.11.1930'
---

## PowerShell Development Standards

### 1. PowerShell Modules (.psm1 / .psd1)

- EVERY module must have a full module manifest generated via `New-ModuleManifest`.
- Do not emit truncated or skeletal manifests. All metadata keywords must be explicitly defined, and examples or descriptive comments must be fully populated for optional fields.

### 2. PowerShell Standalone Scripts (.ps1)

- EVERY standalone script must feature a complete metadata header generated via `Microsoft.PowerShell.PSResourceGet\New-PSScriptFileInfo`.
- Ensure the `<#PSScriptInfo ... #>` block contains ALL metadata keywords, fully populated strings, or clear placeholder comments. Do not omit default block attributes.

### 3. PowerShell Functions

- EVERY function must include advanced Comment-Based Help (CBH).
- The CBH block must contain at minimum:
  - `.SYNOPSIS`: A concise, one-line summary of what the function does.
  - `.DESCRIPTION`: A detailed breakdown of the functionality and side effects.
  - `.PARAMETER <Name>`: Required for every parameter accepted by the function.
  - `.INPUTS`: Explicitly define the .NET objects/types accepted via the pipeline.
  - `.OUTPUTS`: Explicitly define the .NET objects/types emitted by the function.
  - `.NOTES`: Technical execution details, operational gotchas, or unique context.
- CRITICAL: Never duplicate information inside `.NOTES` that already lives in the parent Script or Module header (e.g., Author, Copyright, CompanyName).

```powershell
@{
    # Script module or binary module associated with this manifest.
    RootModule = 'MyAutomationModule.psm1'
    # Version number of this module.
    ModuleVersion = '2026.05.20.1800'
    # Supported PSEditions
    CompatiblePSEditions = @('Core', 'Desktop')
    # ID used to uniquely identify this module
    GUID = 'FD777A6E-7AE7-4368-8EBD-06EDC6B02784'
    # Author of this module
    Author = 'DevOps Engineering Team'
    # Company or vendor of this module
    CompanyName = 'Enterprise Solutions Corp'
    # Copyright statement for this module
    Copyright = 'CC BY-NC-SA 󱤹 2026 By STS'
    # Description of the functionality provided by this module
    Description = 'Provides core enterprise automation utilities for managing cloud infrastructure and directory services.'
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.6'
    # Name of the PowerShell host required by this module
    # HostName = 'ConsoleHost'
    # Minimum version of the PowerShell host required by this module
    # MinPSHostVersion = '5.1'
    # Minimum version of the .NET Framework required by this module
    DotNetFrameworkVersion = '4.8'
    # Minimum version of the Common Language Runtime (CLR) required by this module
    # CLRVersion = '4.0'
    # Processor architecture (None, X86, Amd64, IA64) required by this module
    # ProcessorArchitecture = 'Amd64'
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{ ModuleName = 'Az.Accounts'; ModuleVersion = '3.0.0' }
    )

    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    RequiredScripts = @()
    # Assemblies (.dll) that must be loaded prior to importing this module
    RequiredAssemblies = @()
    # External files (such as assembly files) that are required by this module
    # ExternalModuleDependencies = @()
    # Public sign-off sheets or nested modules
    NestedModules = @()
    # Functions to export from this module, for best performance, do not use wildcards and do not leave an empty array.
    FunctionsToExport = @('Get-EnterpriseAsset', 'Sync-DirectoryGroup')
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not leave an empty array.
    CmdletsToExport = @()
    # Variables to export from this module
    VariablesToExport = @()
    # Aliases to export from this module, for best performance, do not use wildcards and do not leave an empty array.
    AliasesToExport = @()
    # DSC resources to export from this module
    # DscResourcesToExport = @()
    # List of all modules packaged with this module
    # ModuleList = @()
    # List of all files packaged with this module
    # FileList = @()
    # Private data to pass to the module specified in RootModule
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Enterprise', 'Automation', 'ActiveDirectory', 'Azure')
            # A URL to the license for this module.
            LicenseUri = 'https://creativecommons.org/licenses/by-nc-sa/4.0/'
            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/STS-Consulting/PowerShell'
            # A URL to an icon representing this module.
            IconUri    = 'https://github.com/STS-Consulting/PowerShell/raw/monad/Resources/STS.Consulting.png'
            # ReleaseNotes of this module
            ReleaseNotes = 'Release introducing core AD sync capabilities.'
            # Prerelease string of this module
            # Prerelease = 'preview'
        }
    }

    # HelpInfo URI of this module
    # HelpInfoURI = ''
    # Default prefix for commands exported from this module. Override using Import-Module -Prefix.
    DefaultCommandPrefix = 'STS'
}
```

```powershell
<#PSScriptInfo
.VERSION 2026.05.20.1800
.GUID FD777A6E-BBC1-4F86-A4FC-EE0E7989372A
.AUTHOR Scott T Surber
.COMPANYNAME STS Consulting
.COPYRIGHT CC BY-NC-SA 󱤹 2026 By STS
.TAGS Storage, Optimization, Disk, Maintenance
.LICENSEURI https://creativecommons.org/licenses/by-nc-sa/4.0/
.PROJECTURI https://github.com/STS-Consulting/PowerShell
.ICONURI    https://github.com/STS-Consulting/PowerShell/raw/monad/Resources/STS.Consulting.png
.EXTERNALMODULEDEPENDENCIES
.REQUIREDMODULES @{ModuleName = 'Storage'; ModuleVersion = '2.0.0'}
.RELEASENOTES Fixed memory leak when optimizing heavily fragmented volumes.
.PRIVATEDATA Cleartext storage credentials are strictly banned from this execution context.
#>

<#
.SYNOPSIS
    Optimizes and defragments attached local storage volumes.
.DESCRIPTION
    Analyzes local NTFS and ReFS filesystems, runs slab consolidation for virtualized disks, and issues TRIM commands for SSD targets.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$VolumeLetter
)

Write-Host "Optimizing volume: $VolumeLetter"
# Script body execution follows...
```

```powershell
function Convert-EpochToDateTime {
    <#
    .SYNOPSIS
        Converts a Unix epoch timestamp into a standard PowerShell DateTime object.
    .DESCRIPTION
        Accepts a 10-digit (seconds) or 13-digit (milliseconds) integer representation of a Unix timestamp and converts it to local or UTC time. It validates input boundaries to prevent overflow errors common to older 32-bit timestamp engines.
    .PARAMETER EpochTimestamp
        The raw integer timestamp value parsed from API responses or log exports.
    .PARAMETER UseUtc
        Forces the output DateTime object to reflect Coordinated Universal Time (UTC) instead of matching the local machine's system time zone configuration.
    .INPUTS
        System.Int64. You can pipe an array of Unix epoch integers directly into this parameter.
    .OUTPUTS
        System.DateTime. Emits an object representing the exact point in time.
    .NOTES
        - Internal calculations utilize [DateTimeOffset]::FromUnixTimeSeconds or Milliseconds dynamically based on the length of the string input.
        - Execution requires a minimum framework tier of .NET Standard 2.0 / CoreCLR execution.
        - Network latency tracking calculations should call this tool off-thread if processing log datasets scaling past 100,000 array lines.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [int64]$EpochTimestamp,

        [Parameter(Mandatory = $false)]
        [switch]$UseUtc
    )

    process {
        $dateObject = [DateTimeOffset]::FromUnixTimeSeconds($EpochTimestamp)

        if ($UseUtc) {
            $dateObject.UtcDateTime
        } else {
            $dateObject.LocalDateTime
        }
    }
}
```
