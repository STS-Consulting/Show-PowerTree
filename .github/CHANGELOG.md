# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to **Calendar Versioning (yyMM.dd.HH00 or yyMM.dd.HHmm - e.g., $exampleVer)**.

## Unreleased

### Changed

- New-STSVM: `-Force` now bypasses confirmation prompts for both VM creation and automatic VMSwitch creation while still honoring `-WhatIf`. This enables fully non-interactive deployments and CI/CD scenarios.

### Added

- Documentation: Dedicated usage guide `Documentation/PowerShell/New-STSVM.Usage.md` detailing parameters, deployment paths, Force/WhatIf semantics, guest readiness, and examples.

### Improved

- New-STSVM: Guest readiness now determined via Hyper-V integration services heartbeat (Heartbeat = OK + Guest Service Interface enabled) instead of IP probing, improving reliability before network configuration is applied.


