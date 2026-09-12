---
name: grill
description: Protocol that interviews the user in rounds over the Architect's design tree. Three paths control depth. Produces plan.md, arch.md, impl.md.
usedBy: [maestro]
version: 0.2.1
lastUpdated: 2026-09-12
---

## Purpose

Reach shared understanding with the user before execution. The Architect owns the design tree — the decisions the feature must settle, mapped with dependencies, pruned by path, ranked by impact. You work the frontier in rounds: ask up to 5 frontier questions, wait for the user's answers, transcribe the settled decisions into the artifacts. After the user confirms, execution is autonomous. The user is bothered in rounds, not on every micro-delivery.

## Procedure

The path determines which branches the tree explores. Step 1 resolves it from long-term memory, or asks the user when none is recorded:

- **Beginner** — business questions only. The Architect infers architecture from the maintenance, lightweight, and safe principles (KISS, single responsibility, safe boundaries — `rules/code/general.md`). Ceiling: 30 business questions.
- **Tinkerer** — business and architecture questions. Ceiling: 30 business, 10 architecture.
- **Pro** — business, architecture, and implementation questions. Ceiling: 100 questions per branch.

Artifacts live at `.memory/plan/<feature-slug>/`:

- `tree.md` — the design tree. The Architect owns it.
- `plan.md` — acceptance criteria, from the settled business decisions.
- `arch.md` — directory structure, layer separation, reference projects. Tinkerer and pro. Beginner gets defaults.
- `impl.md` — epics grouped at one day of work, with parallelizable groups.

You transcribe `plan.md`, `arch.md`, and `impl.md` as decisions settle. The Architect owns `tree.md` and the grounded `impl.md`.

1. **Select path.** Check long-term memory (uses: `skills/agent-memory/SKILL.md`) for a recorded grill path under `## Preferences`. If one exists, proceed with it — state the path in the first message to the user so they can override in one word. If the user overrides, replace the recorded entry. If none exists, ask the user to choose: beginner, tinkerer, or pro. Record the choice under `## Preferences` as `[grill] path: <beginner | tinkerer | pro>`.
2. **Build the tree.** Dispatch the Architect (`personas/architect.md`) (follows: `skills/dispatch/SKILL.md`) in tree mode with the selected path. The Architect writes `tree.md`.
3. **Work the frontier in rounds.** The frontier is every open node in `tree.md` whose dependencies are all settled. Send up to 5 frontier questions per round, ordered by impact. Each question carries the tree's recommendation. Wait for the user's answers before the next round.

   Format each round:

   ```
   ❓ **Q1** - **<question title>**: <question body>

   ➡️ <recommendation from the tree>
   ```

   - If the frontier exceeds 5, ask the 5 questions whose answers unblock the most downstream questions.
   - A node that depends on another question open in this round belongs to a later round.
   - A node that depends on a fact in `## Facts`: dispatch a host exploration agent (e.g., the host's Explore tool) to find the fact. Never ask the user for a fact you can look up. Do not block the rest of the frontier on a running fact-finder. Record the found fact in `tree.md` when it lands.
4. **Checkpoint after each round.** Transcribe the settled decisions of the round into the relevant artifact files. Create a file if it does not exist. This survives context compaction and keeps the session on track.
5. **Re-tree on scope change.** If an answer does not map to a node in the tree — a new branch, a scope change — re-dispatch the Architect (`personas/architect.md`) (follows: `skills/dispatch/SKILL.md`) in tree mode to extend `tree.md`. Settled nodes stay settled.
6. **Terminate.** The grill is done when the frontier is empty. Present `plan.md`, `arch.md`, and `impl.md` to the user. Do not act until the user confirms you have reached a shared understanding.

## Post-Grill Execution

After the user confirms, the plan-management flow takes over (follows: `skills/plan-management/SKILL.md`): ground, review, then the coder per epic.

Interrupt the user only for escalations:
- A fact that contradicts a settled decision.
- A business rule the grill did not cover.

The Architect classifies every discovery as adjust (folded into the remaining epics, no user gate) or escalate (user gate). Anything else, the Architect decides and documents inline.

## Guardrails

- Never ask for a path that is recorded in long-term memory. State it; do not ask.
- The quality filter and the ceilings are applied by the Architect in the tree. Stop when the frontier is empty, not when you hit a ceiling.
- Send at most 5 questions per round.
- Never ask the user for a fact you can look up. Dispatch a subagent.
- Never skip the checkpoint.
- Never work a node whose dependencies are unsettled.
- Never act on the tree until the user confirms shared understanding.
- Never let a persona talk to the user directly. You are the only voice.
