---
description: 'Audit PowerShell scripts against STS Universal Refactoring Contract and completion gate'
mode: 'agent'
tools: ['fetch', 'edit_file']
version: '2026.09.11.1930'
---

# Audit PowerShell Script Compliance

Audit `${input:FilePath:Scripts/Continuous-Integration/Manage-STSGUID.ps1}` against the STS Universal Contract and coding standards.

## Mission
Perform a rigorous, line-by-line audit of the target file:
1. **AST Parse Validation:** Ensure `[System.Management.Automation.Language.Parser]::ParseFile` yields zero errors.
2. **Write-Host / Read-Host Prohibition:** Verify no occurrences exist; confirm all messaging uses operational streams (`Write-Information`, `Write-Verbose`, etc.).
3. **No Colon After Variable:** Confirm no strings have `"$var:"` patterns.
4. **Pipeline Hygiene:** Ensure `$PSItem` is used instead of `$_` and pipeline breaks contain no backtick line continuations.
5. **CBH & Metadata:** Ensure all parameters have `.PARAMETER` blocks, and `.INPUTS`, `.OUTPUTS`, `.SYNOPSIS`, and `.DESCRIPTION` are populated.
6. **Code Signing:** Ensure no fabricated Authenticode signatures exist.

## Output Expectations
Provide a markdown report summarizing:
- Total lines audited
- Violations detected by rule category
- Proposed remediations or automated fixes applied
