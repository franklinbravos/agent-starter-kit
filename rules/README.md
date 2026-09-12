# Rules

Rules are constraints — short, direct, and non-procedural. A rule that needs multiple pages to explain is likely a skill in disguise.

## Available Rules

- **`code/general`** — Universal naming, style, comments, and testing conventions (coding)
- **`code/shell`** — Shell script readability, safety, and determinism (coding)
- **`code/debugging`** — Root cause before fix, three-strike rule, anti-rationalization (coding)
- **`git`** — Conventional commits, branch naming, commit style (coding)
- **`context-maintenance`** — .context.md and FEATURE-MAP.md updates on structural changes (coding)
- **`reviewing`** — Review dispatch sizing, file creation prohibition, tooling trust boundaries (reviewing)

## File Naming

Lowercase, hyphenated. Coding-scoped rules live in the `code/` subdirectory: `code/general.md`. Universal rules sit at the root: `git.md`, `reviewing.md`.

## Schema (v0.2.0 // 2026-09-12)

### Frontmatter

- **`shortDescription`** (Required) — What the rule enforces in one sentence. Example: `Mandates .context.md updates on structural changes`
- **`scope`** (Required) — Task category this rule applies to. Example: `coding`
- **`version`** (Required) — Semantic version. Example: `0.1.0`
- **`lastUpdated`** (Required) — Last modification date. Example: `2026-02-05`

### Body

- **Statement** (Required) — The rule itself. Use RFC-style language: MUST, MUST NOT, SHOULD, SHALL, SHALL NOT. As short as the constraint allows.
- **Rationale** (Required) — Why this rule exists. One paragraph. Without rationale, rules feel arbitrary and get ignored.
