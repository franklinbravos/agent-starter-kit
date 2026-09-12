# Skills

Skills are collected intelligence on how to operate a specific tool — whether that is a CLI, an API, or an MCP/ACP server. They codify procedures, protocols, and output formats that personas reference during execution.

### Available Skills

- `agent-decision/SKILL.md` — structured ambiguity escalation with 1-3-1 analysis and FRAME self-review rubric
- `agent-memory/SKILL.md` — long-term and session memory across sessions
- `architect-design-tree/SKILL.md` — builds the grill's design tree: decisions, dependencies, recommendations, impact, facts
- `architect-impl-grounding/SKILL.md` — grounds the grill's artifacts: annotates impl.md per epic, re-grounds after each landing, classifies discoveries
- `boot/SKILL.md` — session startup — gitignore, auto-update, memory, rules, orient
- `browser-inspect/SKILL.md` — browser inspection for UI verification (coder)
- `code-coherence-review/SKILL.md` — logic coherence, correctness, and structural integrity checks
- `code-quality-review/SKILL.md` — rules-walk procedure for coding standards compliance
- `code-sec-review/SKILL.md` — static security review — attack surface, CWE/OWASP 2025, MITRE ATT&CK
- `coder-self-review/SKILL.md` — GRASP self-review rubric — implementation quality gate
- `context-maintenance/SKILL.md` — how to maintain .context.md files and docs/FEATURE-MAP.md as the project evolves
- `contextualizer-self-review/SKILL.md` — TRACE self-review rubric — context generation quality gate
- `dispatch/SKILL.md` — assembles sub-agent prompts with task brief and routes to the correct provider
- `grill/SKILL.md` — protocol that interviews the user in rounds over the Architect's design tree; three paths control depth
- `plan-management/SKILL.md` — plan lifecycle: grill entry, grounding, artifact review, per-epic execution, revision
- `loop-recovery/SKILL.md` — structured recovery and escalation for retry loops
- `reviewer-architect-adversarial/SKILL.md` — adversarial plan validation on grill artifacts — structural checks and assumption attack before implementation
- `reviewer-handoff/SKILL.md` — structured review summary format with verdict logic
- `review-loop/SKILL.md` — two-mode review loop — single reviewer per epic, three reviewers for full branch
- `reviewer-self-review/SKILL.md` — SHIELD self-review rubric — unified reviewer quality gate
- `task-tracking/SKILL.md` — file-based to-do tracking for multi-step and multi-session work
- `web-search/SKILL.md` — web search and page fetch through the TinyFish CLI (all)

## When to Extract a Skill

Extract a skill when:

- A tool proves difficult enough that a human must step in and write an explicit how-to for the agent to follow.
- A procedure must be standardized across multiple personas, such as a shared protocol or output format.

Do not extract when the procedure is short and intuitive. If a competent agent can work it out without written guidance, a skill file adds overhead without value.

## File Naming

One directory per skill. The directory holds a single `SKILL.md`. The directory name is lowercase, hyphenated, and must match the `name` frontmatter field: `agent-memory/SKILL.md`, `dispatch/SKILL.md`.

This layout matches the host runtime's skill discovery contract: the runtime loads each skill from its own directory — one SKILL.md per skill — and indexes it by its `name`.

Shared scripts that support skills live in `assets/`. They are not skills.

## Schema (v0.2.0 // 2026-09-12)

### Frontmatter

- **`name`** (Required) — Skill identifier; lowercase alphanumeric with single hyphens; must match the directory name. Example: `agent-memory`
- **`description`** (Required) — What the skill does in one sentence; the host runtime lists this in the skill picker. Example: `Cross-session memory retrieval and storage`
- **`usedBy`** (Required) — Which personas use this skill. `[all]` if injected universally via boot. Example: `[all]` or `[maestro]`
- **`relatedTo`** (Optional) — External tools, CLIs, or APIs this skill wraps or abstracts. Example: `[docker, awk]` or `[anthropic-api]`
- **`version`** (Required) — Semantic version. Example: `0.1.0`
- **`lastUpdated`** (Required) — Last modification date. Example: `2026-02-05`

### Body

- **Purpose** (Required) — What this skill does and why it exists. One paragraph, no bullet points. Answer "what problem does this solve?" not "what steps does it take."
- **Procedure** (Required) — Numbered steps for executing the skill. Each step that produces an artifact must describe its output inline — format, structure, and destination. Reference other skills or rules with `(uses: path)` or `(follows: path)` as needed.
- **Guardrails** (Optional) — Skill-specific pitfalls to avoid. Not rules, not procedure repetition. Ask: "what mistake would an agent make when using this skill carelessly?"

Nothing sits between `Purpose` and `Procedure`. Definitions the steps depend on (modes, scopes, path rules) fold into `Procedure` as a preamble. All other sections are reference material and sit after `Procedure`.
