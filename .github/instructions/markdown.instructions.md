---
description: 'Documentation and markdown authoring standards for technical documentation, Vale linting, and help generation.'
applyTo: '**/*.md'
version: '2026.09.11.1930'
---

# Markdown Documentation Standards

Authoritative guidance for authoring, editing, and formatting markdown documentation within **STS-Consulting/PowerShell**.

---

## 1. Markdown Content & Structure Rules

1. **Heading Hierarchy:**
   - Use a single `#` (H1) for the document title.
   - Use `##` (H2) for major sections and `###` (H3) for sub-sections.
   - Avoid jumping levels (e.g. do not follow `##` directly with `####`).
2. **Lists:**
   - Use standard hyphens `-` for unordered bullet points.
   - Use `1.` for ordered lists.
   - Indent nested sub-lists by 2 or 4 spaces consistently.
3. **Code Blocks:**
   - Always use fenced code blocks with language identifiers (e.g. ```` ```powershell ````, ```` ```markdown ````, ```` ```yaml ````).
   - Specify language syntax for every code snippet to ensure syntax highlighting and linting.
4. **Tables:**
   - Use GitHub Flavored Markdown (GFM) pipe syntax.
   - Ensure header separators and columns are neatly aligned.
5. **Links and References:**
   - Use descriptive anchor text `[Description](URL)`. Never use vague text like `[click here](URL)`.
   - Relative links should point to files within the repository.
6. **Line Length & Spacing:**
   - Avoid artificial line breaks inside sentences; let editor word-wrapping manage display.
   - Separate paragraphs and headings with a single blank line.

---

## 2. Prose Quality and Vale Linting

All documentation in this repository is subject to Vale prose linting configured in `.vale.ini`:
- Install Vale locally via `winget install errata-ai.Vale`.
- Check files with `vale <file.md>`.
- Use clear, professional, active voice.
- Avoid buzzwords, excessive jargon, and unexpanded acronyms.

---

## 3. Help Documentation (PlatyPS & PSDocs)

- For cmdlet and module reference documentation generated via PlatyPS or PSDocs, maintain exact schema consistency with the cmdlet's Comment-Based Help.
- Parameter descriptions, types, and defaults in markdown must reflect the real cmdlet definition.
