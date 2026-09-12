# Personas

Personas are specialized AI roles. Role-playing matters. Different perspectives trigger different reasoning patterns.

## Available Personas

- **maestro** — Orchestrates personas
- **architect** — Owns the grill's design tree; grounds plan artifacts in the codebase
- **coder** — Software development
- **reviewer** — Review safety net — sniper focus or full squad review, adapts to task
- **contextualizer** — Rebuilds .context.md files
- **secops-engineer** — Hands-on security testing, findings, technical report
- **secops-manager** — Business risk, management reporting, proposals

## Execution Model

Personas run as **subagents only**, never as the main agent. The exception is `maestro`, which runs as the main agent and orchestrates all personas.

## Isolation Principle

Personas MUST NOT reference framework internals (maestro, dispatch mechanics). A persona knows only what it needs to do its job — it receives a task, executes its playbook, and delivers a handoff. How it was invoked is not its concern.

## File Naming

Lowercase, short name: `reviewer.md`, `architect.md`

## Schema (v0.3.0 // 2026-09-12)

### Frontmatter

- **`name`** (Required) — Must match the filename without extension. Example: `reviewer`
- **`description`** (Required) — What the persona does in one sentence. Example: `Reviews code for quality and security`
- **`preferredModel`** (Optional) — `host`, `claude`, `codex`, `cursor`, `deepseek`, `gemini`, or `[claude, codex]`
- **`modelTier`** (Required) — `tier-2`
- **`version`** (Required) — `0.1.0`
- **`lastUpdated`** (Required) — `2026-02-04`
- **`humor`** (Optional) — `introvert` / `pragmatic` / `sympathetic` / `extrovert` / `robotic` / `default`

**`preferredModel`** selects which provider handles the persona. The value must match a `preferredModel` entry in the Providers list (`skills/dispatch/SKILL.md`). Use `host` for native dispatch on the host runtime's own model. A single string routes to one provider; a list enables round-robin or fallback. When omitted, the persona runs on the host runtime's native provider.

**`modelTier`** declares the minimum capability class the persona requires. Tier classes: **tier-1** = fast/cheap, **tier-2** = balanced, **tier-3** = reasoning/smartest. The field is a floor, not a ceiling — a more capable tier may be selected at dispatch time depending on task complexity.

**`humor`** controls response temperature and thinking budget. Available values: `introvert`, `pragmatic`, `sympathetic`, `extrovert`, `robotic`. Lower temperatures produce more conservative, focused responses; higher temperatures encourage broader exploration. The concrete temperature, top_p, and thinking-budget values per humor live in `skills/assets/maestro-boot-configure-cli.sh` — that script is the single source of truth. Omit the field when no special temperature or thinking budget is needed.

### Body

- **Identity** (Required) — Written in second person. Establish a vivid character with a clear mindset, perspective, and tone. This is not a job description — it's a personality. One to two paragraphs, no bullet points. Identity must not contain prohibitions, constraints, or "never" statements — those belong in Red Lines. Identity answers "who are you" not "what don't you do." Test: remove all Red Lines. If Identity still implies them, it's leaking.
- **Playbook** (Required) — Numbered steps the persona follows. Each step that loads a skill or rule must reference it inline with `(uses: path)` or `(follows: path)`. No naked steps. **Extraction rule**: if a step describes a reusable protocol, format, or procedure that another persona could also need, it belongs in `skills/`, not here. The step should reference the skill, not inline its contents. **Honesty rule**: every step must reflect something the agent can actually do given the execution model. Do not include steps the agent cannot verify or enforce at runtime — aspirational steps erode trust in the entire playbook.
- **Handoff** (Required) — One to two sentences. When is the job done and what is delivered. If it takes more than two sentences, you are over-specifying — extract the delivery format into a skill. The exception is `maestro`, whose Handoff also carries orchestration policy such as the commit gate. Every handoff may include an optional `Observations` section — things the persona noticed that fall outside its deliverable but may concern the team: unexpected patterns, risks, suggestions, or structural issues. Observations are not findings to fix — they are opinions to consider.
- **Red Lines** (Required) — Specific to this persona. Things this persona might be tempted to do but must not. Do not repeat rules or playbook steps as prohibitions. Ask: "what mistake would this particular role make?"
- **Yield** (Optional) — Concrete situations where the persona must stop and return control to the user. Not vague categories — describe the actual trigger.
