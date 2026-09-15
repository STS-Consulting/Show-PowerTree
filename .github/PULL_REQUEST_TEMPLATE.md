# Pull Request

## Type of Change

- [ ] ✨ New feature / cmdlet / function
- [ ] 🐛 Bug fix
- [ ] 📚 Documentation / Comment-Based Help update
- [ ] 🎨 Code style / OTBS formatting / refactoring
- [ ] ✅ Pester tests / test coverage
- [ ] 🤖 CI/CD workflow update
- [ ] 🔒 Security hardening
- [ ] 💥 Breaking change

## Related Issue

<!-- If this PR resolves an issue, enter the issue number here (e.g. Fixes #123) -->

## Description

<!-- Provide a concise description of the changes introduced and rationale. -->

## Quality & Verification Checklist

- [ ] **PowerShell Standards:** Follows OTBS, PascalCase for cmdlets/parameters, and camelCase for private variables.
- [ ] **No `Write-Host` / `Read-Host`:** Uses `Write-Information`, `Write-Verbose`, `Write-Warning`, or `Write-Error`.
- [ ] **Comment-Based Help:** Includes `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.INPUTS`, and `.OUTPUTS`.
- [ ] **PSScriptInfo / Manifest:** Standalone scripts have `<#PSScriptInfo ... #>` blocks and module manifests are updated.
- [ ] **Syntax & Linting:** Code parses cleanly with `[System.Management.Automation.Language.Parser]::ParseFile` (0 errors) and passes PSScriptAnalyzer rules.
- [ ] **Automated Tests:** Pester v5 tests are included or updated, and all tests pass locally.
- [ ] **Code Signing:** Authenticode signatures have not been fabricated; files ready for authentic code signing in CI.
- [ ] **License & Terms:** By submitting this pull request, I confirm that my contribution complies with the repository license (CC BY-NC-SA 4.0).
