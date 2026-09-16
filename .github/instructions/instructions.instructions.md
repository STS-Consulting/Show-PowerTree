---
description: 'Guidelines for creating high-quality custom instruction files for GitHub Copilot'
applyTo: '**/*.instructions.md'
version: '2026.09.11.1930'
---

# Custom Instructions File Guidelines

Instructions for creating effective and maintainable custom instruction files that guide GitHub Copilot in generating domain-specific code and following project conventions.

## Project Context

- Target audience: Developers and GitHub Copilot working with domain-specific code
- File format: Markdown with YAML frontmatter
- File naming convention: lowercase with hyphens (e.g., `powershell.instructions.md`)
- Location: `.github/instructions/` directory
- Purpose: Provide context-aware guidance for code generation, review, and documentation

## Required Frontmatter

Every instruction file must include YAML frontmatter with the following fields:

```yaml
---
description: 'Brief description of the instruction purpose and scope'
applyTo: 'glob pattern for target files (e.g., **/*.ps1, **/*.Tests.ps1)'
version: '2026.09.11.1930'
---
```

### Frontmatter Guidelines

- **description**: Single-quoted string, 1-500 characters, clearly stating the purpose
- **applyTo**: Glob pattern(s) specifying which files these instructions apply to
  - Single pattern: `'**/*.ps1'`
  - Multiple patterns: `'**/*.ps1, **/*.psm1, **/*.psd1'`
  - Specific directories: `'.github/workflows/*.yml'`
  - All files: `'**'`
- **version**: Single-quoted string following the STS timestamp format `'YYYY.MM.DD.HHmm'` (e.g. `'2026.09.11.1930'`). Required on all instruction and prompt documents to track revisions and enable deterministic CI auditing.

## File Structure

A well-structured instruction file should include the following sections:

### 1. Title and Overview

- Clear, descriptive title using `#` heading
- Brief introduction explaining the purpose and scope
- Project context section with key technologies, versions, and environment constraints

### 2. Core Sections

Organize content into logical sections based on the domain:

- **General Instructions**: High-level guidelines and non-negotiables
- **Best Practices**: Recommended patterns and idioms
- **Code Standards**: Naming conventions, formatting, style rules
- **Architecture & Structure**: Project organization and design patterns
- **Common Patterns**: Frequently used implementations
- **Security**: Security considerations, input validation, secret handling
- **Performance**: Optimization guidelines
- **Testing & Verification**: Testing standards and deterministic validation checks

### 3. Examples and Code Snippets

Provide concrete examples with clear labels:

```markdown
### Good Example
\`\`\`powershell
# Recommended approach
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path
)
\`\`\`

### Bad Example (Anti-Pattern)
\`\`\`powershell
# Avoid this pattern - do not use Write-Host
Write-Host "Processing $Path"
\`\`\`
```

### 4. Validation and Verification

- Commands to verify syntax and parsing
- Static analysis and linting (e.g. PSScriptAnalyzer)
- Automated testing commands (e.g. Pester v5)

## Content Guidelines

### Writing Style

- Use clear, concise language
- Write in imperative mood ("Use", "Implement", "Avoid")
- Be specific and actionable
- Avoid ambiguous terms like "should", "might", "possibly"
- Use bullet points and lists for scannability

### Best Practices

- **Be Specific**: Provide concrete code patterns rather than vague concepts
- **Explain Rationale**: Briefly explain why a pattern is required when it adds clarity
- **Use Tables**: Compare options, list rules, or display parameters
- **Include Examples**: Real code snippets are far more effective than descriptions
- **Stay Current**: Reference PowerShell 7.6+, .NET 8+, and modern tooling
- **Maintain Consistency**: Never publish examples that violate rules defined in the same document
