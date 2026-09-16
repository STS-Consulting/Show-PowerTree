---
applyTo: '**/*.Tests.ps1, **/tests/**/*.ps1'
description: 'PowerShell Pester v5 testing best practices, mocking patterns, assertions, and Behavior-Driven Development (BDD) with Gherkin.'
version: '2026.09.11.1930'
---

# PowerShell Pester v5 Testing Guidelines

Authoritative guidance for creating robust, isolated, and maintainable automated tests using **Pester v5** in **STS-Consulting/PowerShell**.

---

## 1. Test File Conventions & Placement

- **Naming Convention:** All test files must follow `*.Tests.ps1` (e.g. `Convert-EpochToDateTime.Tests.ps1`).
- **Placement:** Place test files under `tests/Unit/` for unit tests and `tests/Integration/` for integration workflows.
- **Import Pattern:** Load target modules or functions inside the top-level `BeforeAll` block using relative script root paths:
```powershell
BeforeAll {
    . $PSScriptRoot/../../Scripts/Public/Convert-EpochToDateTime.ps1
}
```
- **Zero Code Outside Blocks:** Put **ALL** execution code inside Pester lifecycle blocks (`BeforeAll`, `Describe`, `Context`, `It`, `AfterAll`). Loose statements outside blocks execute during discovery and cause unpredictable side effects.

---

## 2. Test Hierarchy and Lifecycle

```powershell
BeforeAll {
    # Import tested functions, load modules, or define test fixtures
}

Describe 'Convert-EpochToDateTime' {
    Context 'When converting UTC timestamps' {
        BeforeAll {
            # Context-specific setup
        }

        It 'Converts 0 to the Unix epoch in UTC' {
            $result = Convert-EpochToDateTime -EpochTimestamp 0 -UseUtc
            $result | Should -Be ([DateTime]'1970-01-01T00:00:00Z')
        }

        AfterAll {
            # Context-specific teardown
        }
    }
}
```

### Lifecycle Blocks
- **`Describe`**: Top-level grouping, named after the function or cmdlet being tested.
- **`Context`**: Logical scenario grouping (e.g. valid input, edge cases, error handling).
- **`It`**: Single test assertion. Keep test names descriptive and behavior-focused.
- **`BeforeAll` / `AfterAll`**: Run once per block. Use for expensive setup/teardown.
- **`BeforeEach` / `AfterEach`**: Run before/after each individual `It` block.

---

## 3. Assertions (`Should`)

Use explicit Pester assertion operators:
- **Equivalence:** `$val | Should -Be $expected`, `$val | Should -BeExactly $expected`
- **Collections:** `$array | Should -Contain $item`, `$array | Should -HaveCount 3`
- **Strings:** `$str | Should -Match 'pattern'`, `$str | Should -BeNullOrEmpty`
- **Filesystem:** `Test-Path $file | Should -BeTrue`, `$path | Should -Exist`
- **Exceptions:** `{ Invoke-FailingCmdlet } | Should -Throw -ExpectedMessage '*access denied*'`
- **Types:** `$obj | Should -BeOfType [PSCustomObject]`

---

## 4. Mocking Strategy

Isolate functions by mocking external dependencies, filesystem operations, and network calls:

```powershell
Context 'When interacting with remote services' {
    BeforeAll {
        Mock Invoke-RestMethod {
            return @{ status = 'success'; id = 42 }
        } -ParameterFilter { $Uri -match 'api\.enterprise\.com' }
    }

    It 'Calls the API endpoint exactly once' {
        Get-RemoteAsset -AssetId 42
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $Uri -match 'api\.enterprise\.com'
        }
    }
}
```

### Mocking Rules
- Use `-ParameterFilter` to ensure mocks only intercept calls with specific arguments.
- Use `Should -Invoke` to verify that calls were made the expected number of times.
- Limit mocks to the containing `Context` or `Describe` block to prevent mock leakage across test files.

---

## 5. Data-Driven Testing (`-ForEach` / `-TestCases`)

Avoid repeating test logic for boundary conditions by parameterizing tests:

```powershell
Describe 'Epoch Timestamp Validation' {
    It 'Converts timestamp <Epoch> correctly' -ForEach @(
        @{ Epoch = 0; ExpectedYear = 1970 }
        @{ Epoch = 1700000000; ExpectedYear = 2023 }
    ) {
        $date = Convert-EpochToDateTime -EpochTimestamp $Epoch -UseUtc
        $date.Year | Should -Be $ExpectedYear
    }
}
```

---

## 6. Behavior-Driven Development (BDD) with Gherkin

For feature-level tests, define behaviors using Gherkin syntax mapped directly to Pester blocks:

```gherkin
Feature: Epoch timestamp conversion
    Scenario: Converting standard epoch to local time
        Given a valid 10-digit epoch timestamp
        When Convert-EpochToDateTime is invoked without -UseUtc
        Then it returns a DateTime object matching the local timezone
```

Map directly into Pester:
```powershell
Describe 'Feature: Epoch timestamp conversion' {
    Context 'Scenario: Converting standard epoch to local time' {
        It 'Given a valid epoch, When invoked, Then returns local DateTime' {
            $epoch = 1700000000
            $result = Convert-EpochToDateTime -EpochTimestamp $epoch
            $result.Kind | Should -Be ([DateTimeKind]::Local)
        }
    }
}
```
