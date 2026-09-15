# Artificial Intelligence (AI) Usage Policy & Disclosure

## 1. Overview & Purpose
This repository recognizes and supports the responsible and ethical use of Artificial Intelligence (AI) assistance tools—such as GitHub Copilot, Google Gemini, Anthropic Claude, OpenAI ChatGPT, and Amazon Q—to aid in code generation, refactoring, documentation, and quality assurance.

Following transparency frameworks and disclosure practices established across the software industry (including guidelines from Microsoft, Google, Amazon, and the open-source community), this document outlines our policy on AI usage, governance, provenance, and human accountability across all contributions.

This policy applies to all code, scripts, configurations, tests, and documentation contributed to this repository.

---

## 2. Permitted & Recommended Use Cases
AI assistance tools are encouraged as authoring aids and pair-programming assistants for tasks such as:

- **Code Scaffolding & Boilerplate:** Generating initial function skeletons, class structures, module definitions, and configuration files.
- **Refactoring & Optimization:** Identifying opportunities to improve performance, readability, idiomatic style, and maintainability.
- **Documentation & Technical Writing:** Drafting function annotations, docstrings, comment-based help, README files, and change summaries.
- **Test Generation & Quality Assurance:** Synthesizing unit tests, integration test fixtures, mock data, and boundary condition cases.
- **Troubleshooting & Analysis:** Explaining complex logic, analyzing stack traces, diagnosing bugs, and identifying potential edge cases.

---

## 3. Core Principles & Governance

### 3.1 100% Human Oversight & Accountability
AI tools are authoring assistants, not autonomous decision-makers or independent authors.
- **Full Human Accountability:** Human authors and contributors retain 100% accountability for the correctness, safety, performance, and security of all committed content.
- **Comprehension Requirement:** Contributors must thoroughly understand every line of AI-generated or AI-assisted code they submit. Do not commit code you cannot explain or support.
- **No Autonomous Deployments:** AI systems must never autonomously commit code, merge pull requests, execute production deployments, or mutate infrastructure without explicit human review and authorization.

### 3.2 Code Quality & Verification Standards
All contributions involving AI-assisted logic must undergo standard validation prior to committing or merging:
- **Human Code Review:** Every AI suggestion must be read, evaluated, and edited for correctness and style.
- **Static Analysis & Linting:** Code must satisfy all repository linting, formatting, and static analysis requirements without suppression of valid warnings.
- **Automated & Manual Testing:** All new or modified functionality must pass existing automated test suites, accompanied by adequate test coverage for new edge cases.
- **Security Auditing:** Code must be reviewed for common vulnerabilities, insecure defaults, improper privilege escalation, and unvalidated inputs.

### 3.3 Security, Privacy & Data Protection
- **No Sensitive Data in Prompts:** Contributors must never submit proprietary secrets, credentials, API keys, private certificates, internal infrastructure identifiers, or Personally Identifiable Information (PII) to public, unvetted, or third-party AI models.
- **Package & Dependency Hallucination Defense:** Always verify that any libraries, packages, modules, or dependencies suggested by AI tools actually exist in official registries before adding them to project manifests.

### 3.4 Licensing & Intellectual Property Compliance
- **License Alignment:** Generated snippets must comply with this repository's licensing terms (e.g., MIT, Apache 2.0, or proprietary) and must not infringe upon third-party copyrights or patents.
- **Avoid Verbatim Ingestion:** Contributors must avoid prompting AI tools to reproduce copyrighted proprietary or restrictive-licensed third-party code verbatim.
- **Duplication Filters:** Where available (e.g., GitHub Copilot), configure tools to block suggestions matching public code.

---

## 4. Limitations & Risk Awareness
Consumers and contributors must remain mindful of the inherent limitations of generative AI models:

| Characteristic | Risk Factor | Mitigation Strategy |
| :--- | :--- | :--- |
| **Hallucination & Plausibility** | Models can produce code that looks syntactically clean and plausible, yet is functionally flawed or insecure. | Perform rigorous line-by-line human review and automated unit/integration testing. |
| **Stale Knowledge & Deprecation** | Models may recommend obsolete functions, deprecated APIs, or outdated security practices. | Cross-reference suggestions against current official platform and language documentation. |
| **Edge-Case Blindness** | AI generation tends to focus on typical "happy path" scenarios, missing subtle failure modes. | Deliberately author test cases covering boundary conditions, null/empty values, error handling, and timeout scenarios. |
| **Third-Party Trust Model** | AI-generated code should be treated like code from an unvetted third party. | Exercise the same diligence, skepticism, and review rigor as with external, untrusted pull requests. |

---

## 5. Transparency, Provenance & Attribution

Transparency allows maintainers and reviewers to allocate appropriate focus during code reviews and security audits.

### 5.1 When Disclosure is Required
Explicit disclosure is required when AI tools have:
- Generated a significant or non-trivial portion of a pull request or commit.
- Authored core architectural logic or complex algorithmic workflows.
- Converted or refactored large segments of an existing codebase.

*Note: Routine inline auto-completions for trivial syntax, variable names, or common language keywords do not require explicit disclosure.*

### 5.2 Pull Request Disclosure Format
When submitting a Pull Request that includes AI-assisted work, include a brief disclosure in the PR description:

```markdown
### AI Assistance Disclosure
- **Tool(s) & Model(s):** [e.g., GitHub Copilot, Anthropic Claude 3.7 Sonnet, Google Gemini 2.5 Pro, OpenAI ChatGPT]
- **Scope:** [e.g., Scaffolding initial function structure, generating unit test fixtures in Tests/]
- **Human Verification:** [e.g., Logic manually reviewed, tested with Pester/unit tests, validated against linter]
```

### 5.3 Commit Messages & Metadata (Recommended)
Where practical, commit messages or changelogs may include an attribution tag or note:

```text
feat(module): add pipeline validation logic

AI-Assisted: GitHub Copilot (Claude 3.7 Sonnet)
Reviewed-by: Contributor Name <contributor@example.com>
```

---

## 6. Contributor Pre-Submission Checklist

Before submitting a Pull Request containing AI-assisted or AI-generated contributions, confirm that you have:

- [ ] **Understood:** Reviewed every line of code and fully understand its behavior and logic.
- [ ] **Cleaned Prompts:** Confirmed that no private keys, passwords, credentials, or proprietary secrets were transmitted to AI tools.
- [ ] **Verified Dependencies:** Confirmed that all suggested libraries, modules, and API calls are genuine and actively maintained.
- [ ] **Tested:** Executed test suites and verified that all new and existing tests pass without regressions.
- [ ] **Linted:** Ran local linters and code formatters, resolving all warnings or errors.
- [ ] **Disclosed:** Included the AI tool, model, and scope of assistance in the Pull Request description.

---

## 7. Inquiries & Feedback
If you have questions, suggestions, or concerns regarding AI usage or governance within this repository, please open an issue or contact the repository maintainers.
