# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Calendar Versioning](https://calver.org/) (YYYY.0M.0D).

## [Unreleased]

## [2026.10.20] - 2026-10-20

### Added

- Governance & Consistency: Added repository consistency directives in `.cursor/rules/repository-consistency.mdc` and automated consistency validation script in `tools/Test-RepositoryConsistency.ps1`.
- Tooling: Configured `.vscode/PSScriptAnalyzerSettings.psd1` enforcing OTBS formatting, explicit parameter typing, `$PSItem`, and PowerShell 7.6+ standards.

### Changed

- Module Codebase: Refactored module functions across `Private/` and `Public/` (`Show-PowerTree.ps1`, `Show-PowerTreeRegistry.ps1`, `Edit-PowerTreeConfiguration.ps1`, tree rendering, formatting, and sizing helpers) to adhere to PowerShell 7+ standards, parameter splatting, explicit typing, and `$PSItem` pipeline variable usage.
- Documentation: Realigned `README.md` and AI policy directives in `.github/AI_POLICY.md` and `.github/Copilot-Instructions.md`.
- Packaging: Standardized module manifests `Show-PowerTree.psd1`, `Show-PowerTree.psm1`, and `package.psd1` to Calendar Versioning (YYYY.0M.0D).

[unreleased]: https://github.com/STS-Consulting/Show-PowerTree/compare/2026.10.20...HEAD
[2026.10.20]: https://github.com/STS-Consulting/Show-PowerTree/releases/tag/2026.10.20
