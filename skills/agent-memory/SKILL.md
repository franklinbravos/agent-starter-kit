---
name: agent-memory
description: Long-term and session memory across sessions.
usedBy: [maestro]
version: 0.4.0
lastUpdated: 2026-09-12
---

## Purpose

Agents start cold every session — lessons, preferences, and interrupted work vanish when the conversation ends. This skill defines a file-based memory with two layers: long-term memory (project knowledge that feeds every dispatch) and session memory (an interaction log that lets the next session resume with full context). Together they form a loop: feedback given once stays, and interrupted work resumes with its full trail.

## Procedure

1. **Check for the memory directory.** Look for `.memory/` at the project root. If it does not exist, create it with `long-term.md` (initialized with the six section headers from the long-term schema below) and subdirectories: `session/`, `plan/`, `todo/`, `reviews/` (all empty).

2. **Read session memory at session start.** List all files in `.memory/session/`. For each file with status `paused` or `in-progress`, read its Current Task and last 5 log entries. Present the list to the user and ask which action to take:
   - **Resume** a paused session — that session becomes the current session. If it has an Active Todo, read the todo and include its unchecked items in the summary.
   - **Start new** — create a new session file in `.memory/session/` (naming convention below). Any existing paused sessions remain on disk for later.
   - **Switch** mid-conversation — pause the current session and resume or start a different one. The user may request this at any point, not just at session start.
   - Files with status `done` are stale — delete them silently.

3. **Read long-term memory.** Read `.memory/long-term.md`. This step is read-only — do not modify long-term memory here.

4. **Record lessons as they surface.** Watch for learning signals throughout the session — do not wait for the user to explicitly frame something as "feedback." Three signal tiers govern when to write:
   - **Strong signal — explicit statement.** The user says "I prefer X," "always do Y," "never do Z." Record immediately.
    - **Medium signal — correction.** The user modifies, rejects, or overrides a sub-agent's output. Extract the underlying preference or rule. Before you record a code-related observation, read the relevant files to verify it. Do not record raw claims without checking.
   - **Weak signal — implicit pattern.** The user consistently does X across multiple interactions but has never stated it. Do not record yet — wait for a strong or medium signal to confirm.

   Write mechanics: one line per entry, optional context tag (a short bracketed label that scopes the entry to a domain, e.g. `[auth]`, `[UI]`, `[refactor]`). Before appending, scan the section for duplicates or contradictions. Two entries contradict only if they share the same context tag (or both have no tag). If they contradict, replace the old entry with the new one. If the tags differ, both entries coexist — they represent different contexts.

5. **Update session memory on every interaction.** After each meaningful interaction — user request, sub-agent dispatch, sub-agent handoff, user feedback, or decision — update the current session file:
   - **Log entry:** Append a one-line summary prefixed with timestamp and actor to the Log section.
   - **Timestamp:** Run `date '+%Y-%m-%d %H:%M'` — never guess or reuse prior values. Use `%Y-%m-%d` for the `Last Active` field and the full `%Y-%m-%d %H:%M` for the log entry prefix.
   - **Active Todo:** When a sub-agent creates a todo (uses: `skills/task-tracking/SKILL.md`), set the field to the todo file path. When the todo is closed, clear the field. This ensures a paused session always points to outstanding work.

6. **Distill session into long-term memory before closing.** When all work for the session is done, run a structured scan of the session log — do not free-associate:
   1. **Corrections** — Did the user change or reject sub-agent output? Extract the preference or rule behind the correction.
   2. **Struggles** — Were there repeated dispatches to the same area, failed approaches, or stuck loops? Record what did not work and why as a learned rule.
   3. **Decisions** — Were structural or architectural choices made during planning or implementation? Record them as project notes.
   4. **Preferences** — Did the user state "I want...", "don't ever...", "I prefer..."? Verify these were captured during step 4. If any were missed, capture them now.
   5. **Prune** — Scan existing entries for anything superseded by today's work, contradicted by the current codebase, or no longer relevant. Remove or replace stale entries.

   Write insight, not inventory. "User prefers small focused PRs" is a lesson. "User asked for a small PR on 2026-03-18" is a log entry — it belongs in session memory, not long-term.

   Append new entries using the same deduplication and tagging rules as step 5.

7. **Mark session complete or paused.** After distillation (or if the session ends mid-work), set the status in the current session file to `done` or `paused` respectively. The next session start will pick it up in step 2.

## Schemas

### Long-term memory (`long-term.md`)

```markdown
## Preferences

- [tag] <one preference per line>

## Feedback

- [tag] <one feedback entry per line>

## Learned Rules

- [tag] <one rule per line>

## Discovered Issues

- [tag] <one issue per line — pre-existing bugs, tech debt, or code smells found during work but outside the current task's scope>

## Observations

- [tag] <one observation per line — opinions, concerns, patterns, or suggestions from persona handoffs that fall outside the deliverable but may matter later>

## Project Notes

- [tag] <one note per line>
```

The six sections above are the defaults. Maestro may create additional sections when an entry does not fit any existing one — for example `## Architecture Decisions` or `## Technical Debt`. New sections follow the same entry format and rules.

**Context tags** are optional. They scope an entry to a domain so that entries with different tags never contradict each other. Examples: `[auth]`, `[UI]`, `[API]`, `[testing]`. Omit the tag when the entry is project-wide.

**Schema notes:**

- Entries are plain text, one line each. No nested lists, no multi-line blocks.
- Deduplication and contradiction replacement happen at write time (step 4), scoped by context tag.
- The user may prune or reorganize manually at any time.

**Size discipline:**

- Target: under 80 entries total across all sections. When approaching this threshold, prune aggressively during distillation (step 6).
- Every entry must answer: "Will this actually help a future session?" If not, it does not belong.
- Prefer updating an existing entry over adding a new one when they cover the same concern.

### Session memory (`.memory/session/<slug>.md`)

```markdown
## Status

<in-progress | paused | done>

## Last Active

YYYY-MM-DD

## Current Task

<brief description of what is being worked on>

## Active Todo

<path to the active todo file, e.g. `.memory/todo/2026-02-18-feat-user-auth.md` — omit section if no todo exists>

## Log

- `YYYY-MM-DD HH:MM` **[actor]** <what happened>
- `YYYY-MM-DD HH:MM` **[actor]** <what happened>
```

**Naming convention:** Each session file is `.memory/session/<slug>.md`, where `<slug>` is a short kebab-case summary of the task (e.g., `refactor-auth-module.md`, `feat-user-auth.md`). Multiple session files can coexist — one per task.

**Actor values:** `user`, or the persona name with provider, model, and effort level — e.g. `maestro (deepseek/deepseek-v4-flash, high)`, `architect (anthropic/claude-opus-4, max)`, `coder (opencode-go/deepseek-v4-flash, high)`. This records which provider, model, and effort level ran each persona so the next session knows what produced each result.

**Example** (`.memory/session/refactor-auth-module.md`):

```markdown
## Status

paused

## Last Active

2026-02-18

## Current Task

Refactor auth module into a separate package.

## Active Todo

.memory/todo/2026-02-18-refactor-auth-module.md

## Log

- `2026-02-18 14:02` **[user]** Asked to refactor the auth module into a separate package.
- `2026-02-18 14:02` **[maestro (deepseek/deepseek-v4-flash, high)]** Dispatched architect to draft a refactor plan.
- `2026-02-18 14:10` **[architect (anthropic/claude-opus-4, max)]** Returned a plan: extract auth into `pkg/auth`, update imports, add tests.
- `2026-02-18 14:11` **[user]** Approved the plan but asked to skip tests for now.
- `2026-02-18 14:11` **[maestro (deepseek/deepseek-v4-flash, high)]** Noted preference (skip tests). Dispatched coder with the approved plan.
- `2026-02-18 14:25` **[coder (opencode-go/deepseek-v4-flash, high)]** Completed phase 1. 8 files changed. Phase 2 pending.
- `2026-02-18 14:26` **[maestro (deepseek/deepseek-v4-flash, high)]** Session paused — user stepping away. Phase 2 remains.
```

**Schema notes:**

- **Status** is `in-progress`, `paused`, or `done`.
- **Active Todo** records the path to the current todo file (uses: `skills/task-tracking/SKILL.md`). When resuming a paused session, the Maestro must read this file and relay its unchecked items to the sub-agent so work picks up where it stopped. Omit the section entirely when no todo exists. Clear it when the todo is closed.
- **Log** is append-only within a session. Each entry is a single line.
- **Keep entries concise.** Record only what matters for resuming: what the user requested, what the agent dispatched, what it delivered, and what it decided. Skip chatter, acknowledgements, and details the code or commit history already hold. The log is a trail, not a transcript.
- When resuming a session, keep the existing log and continue appending.
- When status is set to `done`, the file will be deleted at the next session start (step 2).

## Guardrails

- Never write from weak signals alone. Record explicit statements and corrections (strong and medium signals). Do not record implicit patterns until confirmed by a stronger signal. When recording observations about code, verify by reading the relevant files first — do not record raw claims.
- Never leave a stale session file. If work is complete, set status to `done`. If the session ends mid-work, set status to `paused`. Either way the log must reflect the last thing that happened.
- Never store sensitive data (credentials, tokens, secrets) in either memory file.
- Never let sub-agents write directly to `.memory/` — except for to-do files managed through the task-tracking skill, review progress files under `.memory/reviews/`, and plan artifacts under `.memory/plan/`. Memory writes are Maestro's responsibility — sub-agents return output, Maestro decides what to remember.
