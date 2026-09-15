---
description: 'Scaffold a production-grade PowerShell 7.6+ advanced function following STS-Consulting standards'
mode: 'agent'
tools: ['fetch', 'edit_file']
version: '2609.11.1930'
---

# Scaffold New PowerShell Cmdlet

Generate a fully compliant, production-grade PowerShell advanced function adhering strictly to STS-Consulting standards.

## Mission
Generate a complete PowerShell advanced function for `${input:CmdletName:Get-SampleAsset}` following:
1. **Approved Verb-Noun:** Uses an approved verb from `Get-Verb` and a singular noun.
2. **Comment-Based Help (CBH):** Complete `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER` (for every parameter), `.INPUTS`, `.OUTPUTS`, and `.NOTES`.
3. **Binding & Attributes:** `[CmdletBinding()]` (and `SupportsShouldProcess` if state-modifying).
4. **OTBS Formatting:** One True Brace Style with 4-space indent.
5. **No Write-Host:** Operational streams only (`Write-Information`, `Write-Verbose`, `Write-Warning`, `Write-Error`).
6. **Pipeline Lifecycle:** `process { }` block utilizing `$PSItem` and `try/catch` error handling.
7. **Strong Typing:** Parameter type constraints and validation attributes (`[ValidateNotNullOrEmpty()]`, etc.).

## Output Expectations
Save the function into `Scripts/Public/${input:CmdletName}.ps1` or display the code ready for insertion.
