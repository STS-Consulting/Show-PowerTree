---
description: 'Generate comprehensive Pester v5 test fixtures and mocks for a PowerShell cmdlet'
mode: 'agent'
tools: ['fetch', 'edit_file']
version: '2609.11.1930'
---

# Generate Pester v5 Test Suite

Generate isolated, robust Pester v5 unit tests for `${input:CmdletName:Get-SampleAsset}` adhering to STS-Consulting testing standards.

## Mission
1. Inspect the target cmdlet `${input:CmdletName}` and identify all parameters, pipeline behaviors, edge cases, and external dependencies.
2. Structure the test suite using Pester v5 blocks:
   - `BeforeAll` block dot-sourcing the script relative to `$PSScriptRoot`.
   - `Describe '${input:CmdletName}'` top-level group.
   - `Context` blocks for standard execution, boundary conditions, and error cases.
   - `It` blocks with descriptive assertions using `Should` operators.
3. Add mocks with `-ParameterFilter` for any external commands or filesystem mutations.
4. Add parameterized `-ForEach` or `-TestCases` blocks for multi-input scenarios.

## Output Expectations
Save the generated test file to `tests/Unit/${input:CmdletName}.Tests.ps1`.
