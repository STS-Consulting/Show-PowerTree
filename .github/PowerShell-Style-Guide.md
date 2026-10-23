This directive defines the coding standards and informal conventions required for high-quality, readable, and maintainable PowerShell scripts.

# PowerShell Style & Convention Directive

## 1. Variable Naming Conventions

- **Use Full Words:** Never use abbreviations or acronyms even if they are widely known and documented.
    - _Example:_ `Documents` not `Docs`, `Development` not `Dev`, `Information` not `Info`, `Configuration` not `Config`, `Directory` not `Dir`.
- **The Foreach Pattern:** Always use plural nouns for collections and singular nouns for the iterator.
    - _Example:_ `foreach ($Server in $Servers) { ... }`
- **Parameter Differentiation:** Prefix raw input parameters with a lowercase `p` (e.g., `$pPath`) when they need to be processed into a secondary "clean" variable (e.g., `$Path`).
- **Hungarian Lite:** Use short, type-specific prefixes only for complex .NET objects to clarify their methods:
    - `$xml...` (XmlDocument)
    - `$sb...` (StringBuilder)
    - `$dt...` (DataTable)
    - `$hash...` (Hashtable)
- **Boolean Flags:** All boolean variables must start with a state-indicative prefix such as `Is`, `Can`, `Has`, or `Should`.
    - _Example:_ `$IsConnected`, `$HasAdminRights`.
- **Object Signaling:** Use the `$obj` or `$o` prefix for `[PSCustomObject]` instances to distinguish them from primitive types.
- **Temporary/Volatile Variables:** Use the "Dunder" prefix (`$__`) for variables that are highly local, short-lived, or intended to be overwritten quickly.

## 2. Scope & State Management

- **Explicit Scoping:** Use `$script:` prefixes for variables that maintain state across a module or script file.
- **State Naming:** State variables should typically start with a lowercase `s` or an underscore (e.g., `$script:_isInitialized`) to signal that modification has side effects.

## 3. Function & Cmdlet Rules

- **Verb-Noun Integrity:** Only use Microsoft-approved verbs (Get, Set, New, Remove, etc.). Never use non-standard verbs like `Check-` or `Fix-`.
- **No Aliases:** Never use aliases (e.g., `ls`, `ps`, `dir`, `foreach-object` as `%`). Use the full cmdlet name for script portability and readability.
- **Named Parameters:** Avoid positional parameters. Always explicitly name the parameter (e.g., `Get-Service -Name 'App'`).

## 4. Structural Conventions

- **Anti-Backtick Rule:** Do not use the backtick (`` ` ``) for line continuation. Instead, break lines naturally after pipes (`|`), commas (`,`), or opening braces (`{`).
- **Splatting:** If a command requires three or more parameters, use **Splatting**.
    - The hashtable should be prefixed `$NounParameters` or `$NounSplat`.
    - Pass it using the `@` symbol (e.g., `Get-ChildItem @ChildItemsParameters`).
- **Discarding Output:** Do not use `Out-Null`, `$null = ...` and do not cast to `[void]`. Do not Discard output.

## 5. Commentary & Documentation

- **Self-Documenting Code:** Prioritize descriptive variable names over inline comments.
- **Comment-Based Help:** Functions should include comprehensive `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, and `.EXAMPLE` blocks at the top of the definition.
- **Continuous Comments:** Comments and comment-based help blocks should not be artificially broken across lines other than at punctuation. Modern screens and editors support word wrap.

---

**End of Directive**
