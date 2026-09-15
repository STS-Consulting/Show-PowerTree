---
version: '2609.11.0846'
---

# GitHub Copilot Repository Instructions

Universal development guidance for **STS-Consulting/PowerShell**. This document sets the repository-wide behavioral, safety, and coding standards for all AI-assisted workflows.

---

## 1. Autonomous Agent Directives

- **Autonomous Execution:** Work methodically through plans step-by-step. Validate each increment thoroughly before reporting completion.
- **Concise Communication:** Keep commentary direct and scannable. State what is being done or investigated in clear sentences.
- **Fail-Closed Validation:** Never declare a task complete if static analysis errors, syntax failures, or parse violations remain.

---

## 2. Non-Negotiable PowerShell Standards

All PowerShell code in this repository targets modern **PowerShell 7.6+** in a Unicode-first environment (Windows 11, NerdFonts, UTF-8 with BOM).

### Stream and Output Hygiene
- **Strict Prohibition:** Never use `Write-Host` or `Read-Host`. Period.
- **Operational Streams Only:** Use `Write-Information`, `Write-Verbose`, `Write-Debug`, `Write-Warning`, and `Write-Error`.
- **Clean Formatting:** Do not use string separator lines (`----`), and do not format messages with a colon immediately after a variable (e.g. use `"$PSItem - ($version)"`, not `"$var:"`).
- **Interactive Prompts:** Use `ShouldProcess` and `ShouldContinue` for user confirmation; never build custom text menus.

### Syntax and Styling
- **Formatting:** Follow **OTBS (One True Brace Style)** with 4-space indentation.
- **Casing:** PascalCase for cmdlets, functions, public variables, and parameter names. camelCase for private/local script variables.
- **Pipelines:** Use `$PSItem` instead of `$_`. Break pipelines naturally across lines without backtick (`` ` ``) line continuation.
- **No Cmdlet Aliases:** Always use full cmdlet names (`Get-ChildItem`, `Select-Object`) and explicit named parameters.
- **No Wrappers:** Do not create wrapper functions that disguise built-in PowerShell cmdlets or language features.

### Security and Authenticode Signing
- **No Hardcoded Secrets:** Never embed secrets or credentials in code; use `Microsoft.PowerShell.SecretManagement` or `[PSCredential]`.
- **Authenticode Integrity:** Never fabricate, mock, or hallucinate Authenticode digital signature blocks. When modifying a signed file, invalidate/remove the existing block and re-sign via proper code signing tooling (`Set-AuthenticodeSignature`).
- **Input Sanitization:** Strictly validate all parameter boundaries with validation attributes (`[ValidateNotNullOrEmpty()]`, `[ValidateSet()]`, `[ValidatePattern()]`).

---

## 3. Mandatory Completion Gate

Before completing any script creation, edit, or refactor:
1. **Parse Validation:** Verify every modified `.ps1`, `.psm1`, or `.psd1` file with `[System.Management.Automation.Language.Parser]::ParseFile` to guarantee `ParseErrors = 0`.
2. **Rule Consistency:** Verify that all code examples and comments match the rules defined in the repository.
3. **No Dangling Changes:** Ensure no unfinished refactoring or commented-out debris is left behind.

---

## 4. Conventional Commit & GitMoji Specification

Generate commit messages using the GitMoji specification tailored for PowerShell:

```text
<emoji><type>[optional scope]: <description>
```

### Types & Emojis
- ✨ `feat`: New cmdlet, function, or module capability
- 🐛 `fix`: Bug fix in PowerShell code or module logic
- 📚 `docs`: Help documentation, Comment-Based Help, or markdown docs
- 🎨 `style`: Formatting, OTBS compliance, casing adjustments
- ♻️ `refactor`: Code restructuring, approved verb alignment, pipeline enhancements
- ✅ `test`: Pester tests, unit tests, mock fixtures
- 🛠️ `build`: Module manifests, build scripts, PSDocs generation
- 🤖 `ci`: GitHub Actions workflows, CI/CD pipeline automation
- 🧹 `chore`: Maintenance, file reorganization, cleanup
- ⚡ `perf`: Performance optimization in cmdlets or pipelines
- ⏪ `revert`: Reverting prior commits
- 📦 `packaging`: Version bumps, gallery publishing, module packaging
- 🔒 `security`: Secret management, parameter sanitization, permission hardening

### Scopes
`module`, `cmdlet`, `function`, `help`, `manifest`, `tests`, `workflow`, `script`

### Examples
- ✨ `feat(cmdlet): add Convert-EpochToDateTime with pipeline support`
- 🐛 `fix(function): resolve parameter validation in Sync-DirectoryGroup`
- 📚 `docs(help): complete CBH documentation for Get-EnterpriseAsset`
- 🎨 `style(module): align brace formatting to OTBS standards`
- ✅ `test(cmdlet): add Pester v5 tests for Set-ResourceConfiguration`

---

## 5. Domain-Specific Custom Instructions

Contextual instructions are automatically loaded by GitHub Copilot based on active file types:

- **PowerShell Development:** [.github/instructions/powershell.instructions.md](file:///c:/Users/Scott.Surber/Source%20Code/GitHub/STS-Consulting/PowerShell/.github/instructions/powershell.instructions.md) (`**/*.ps1, **/*.psm1, **/*.psd1`)
- **Pester 5 & BDD Testing:** [.github/instructions/powershell-pester-5.instructions.md](file:///c:/Users/Scott.Surber/Source%20Code/GitHub/STS-Consulting/PowerShell/.github/instructions/powershell-pester-5.instructions.md) (`**/*.Tests.ps1, **/tests/**/*.ps1`)
- **CI/CD Best Practices:** [.github/instructions/github-actions-ci-cd-best-practices.instructions.md](file:///c:/Users/Scott.Surber/Source%20Code/GitHub/STS-Consulting/PowerShell/.github/instructions/github-actions-ci-cd-best-practices.instructions.md) (`.github/workflows/*.yml`)
- **Markdown & Technical Docs:** [.github/instructions/markdown.instructions.md](file:///c:/Users/Scott.Surber/Source%20Code/GitHub/STS-Consulting/PowerShell/.github/instructions/markdown.instructions.md) (`**/*.md`)
- **Copilot Prompt Files:** [.github/instructions/prompt.instructions.md](file:///c:/Users/Scott.Surber/Source%20Code/GitHub/STS-Consulting/PowerShell/.github/instructions/prompt.instructions.md) (`**/*.prompt.md`)
- **Accessibility & Inclusive UX:** [.github/instructions/a11y.instructions.md](file:///c:/Users/Scott.Surber/Source%20Code/GitHub/STS-Consulting/PowerShell/.github/instructions/a11y.instructions.md) (`**`)
- **Instruction Authoring Meta-Guide:** [.github/instructions/instructions.instructions.md](file:///c:/Users/Scott.Surber/Source%20Code/GitHub/STS-Consulting/PowerShell/.github/instructions/instructions.instructions.md) (`**/*.instructions.md`)


### Versioning Specification (Calendar Versioning - CalVer)
- **Strict Requirement:** All releases, module manifests, git tags, changelog entries, and instruction headers strictly adhere to **Calendar Versioning (CalVer)** using yyMM.dd.HH00 or yyMM.dd.HHmm (e.g., $exampleVer).
- **Prohibition:** Semantic Versioning (SemVer / MAJOR.MINOR.PATCH) is **strictly prohibited**.

