# AGENTS.md

**Fork:** franklinbravos/agent-starter-kit — version tracked in `VERSION`.
**Original:** [ntorga/agent-starter-kit](https://github.com/ntorga/agent-starter-kit).

> **Before anything else:** read `AGENTS.override.md` in the project root if it exists. It holds project-specific behavior changes and important instructions that take precedence over every rule in this file.

This is a style book for code that reads itself. You will apply these rules by matching patterns, so match on the reasoning behind each rule, not its wording. The goal is code that explains itself and clearly belongs in the project it lives in. The concrete rules live in `.agents/rules/code/`. They are split by domain: general coding, shell, debugging. Read the files your change touches.

Specialized workflows have their own playbooks under `.agents/skills/`: agent behavior, code review, UI verification, architecture, context maintenance. Read the relevant playbook before doing that kind of work.

## Honesty and Ambiguity

If a request is flawed, say so.

- Proceed without asking: any non-destructive, reversible action the task needs. Git is the safety net. Stopping to confirm the obvious wastes the session.
- Stop and ask: destructive or irreversible actions (deleting a repository, dropping a database, force-pushing to main), and genuinely non-obvious trade-offs.
- When intent could mean different things, or your work surfaces a finding worth raising, state the problem, offer three options with trade-offs, and recommend one (`.agents/skills/agent-decision/SKILL.md`). Keep it brief, in a conversational tone.
- When the ambiguity only changes how (not what), proceed and document your default.

## Git

- Run git from the repository root. Do not use `git -C` or other global git flags. Permission patterns match plain `git <command>` forms only.
- Commit mechanics follow `.agents/rules/git.md`: conventional prefixes, branch names that mirror them, single-phrase messages, one logical change per commit, schema changes called out. You MUST NOT squash or rebase.

## Readability Over Performance

<audience-directive>
You do not write code for the compiler. The compiler only validates syntax. You write code for a stranger at 3am: they never saw this codebase, lack your context, and must fix a bug without breaking anything else. Every choice answers one question — will the stranger understand this without reverse-engineering it, without reading documentation, without doing arithmetic in their head? If not, the code is wrong, even when it compiles. Compiling is the floor. Readable-by-a-stranger-at-3am is the goal.
</audience-directive>

Before writing non-trivial logic, express the full logic in plain English. Use no code terms, short sentences, one idea per sentence, and active voice. If the expression stacks concepts, needs multi-idea sentences, or reads like a proof, the design is too complex. Simplify first, then re-express until it reads simply. The English is the specification. Code machinery it does not mention solves a problem the requirement does not have.

A mechanism is earned by a problem that exists today — measured or named by a caller. A problem the code might someday have earns nothing, performance optimization included.

Defensive programming is the exception. A guard earns its line when it verifies a contract the current code already depends on, and silently trusting the contract would cost more than the check. The guard fails loud. The response matches how much the violation corrupts the state: log the violation so it surfaces at 3am, then skip the item, stop the operation, or raise.

Apply the test to every frame the reader enters, not just whole functions. When a frame fails, fix it with a named extraction that absorbs the non-English concept. Do not add a comment or guard in place.

## Code Shape

Function boundaries are right when the reader never reassembles scattered logic or untangles mixed concerns. Three questions decide the boundary: what to extract, what to unify, what to keep together.

### Function Extraction

Extract a function when it performs a transformation through genuine logic: input processed into distinct output. Size is a thermometer, not a verdict. Under roughly ten lines a function is likely a wrapper. Past one hundred lines it owes a hunt for a split along the criterion seams. A long function serving one criterion is correct; a thin wrapper is indirection. The test: inline the body at the call site; keep the function only when the caller loses clarity. Not every small function is a wrapper: one holding a translation the caller should not know — a format mapping, an encoding, a stdlib contract — is not indirection, however small. Inlining puts the non-English back where the name was.

### Duplication

Two code paths that share knowledge require synchronized edits — unify them. Two paths that look similar but answer different questions are two responsibilities that happen to resemble each other. The test: would a requirement change affect both paths identically? Identical means unify; divergent means the resemblance is coincidental — keep them separate.

### Single Responsibility

One reason to change per function, module, file. A responsibility is one acceptance criterion, not one operation. What serves one criterion stays together at any length; what changes for independent reasons splits. Length is not the signal. The name is the first test. After any split, rename until each name reads as one concrete action.

- A conjunction (`recordAndStartContainer`) forces the question: would the two verbs change independently? If yes, split and let the caller sequence the parts. If no, keep the work under one verb that names the whole criterion (`loadConfig`, not `parseAndValidateConfig`).
- A condition (`deleteContainerDbRecordsIfCreated`) is a decision for the caller — move it to the call site, or drop it when the operation is safe to repeat.
- A recognized idiom (`upsert`) is one action.

## Flow and Structure

The reader should follow the happy path without indentation. Every extra indent level costs the reader, so the main flow runs at the left margin. The reader should see where every value comes from.

- Every helper sits directly above its first caller — adjacent, not merely earlier in the file. The most composed entry point closes the file.
- An expression the reader cannot decode without outside knowledge — a syscall errno, a stdlib counter, a format detail — earns a named variable before it is used, so the name carries the concept the operator hides. A name that only restates the expression is noise: it must say what the expression means. A self-evident expression earns no name: the name must carry knowledge the expression lacks.

## Naming and Communication

Comments, plans, documentation, and CHANGELOG entries MUST use STE-100 (Simplified Technical English). Write short sentences. Keep one idea per sentence. Use active voice.

The reader should learn what a variable holds or a function does from the name alone, without inspecting the body.

A comment is a confession, not a tool: it admits the code failed to explain itself. The default is no comment. When code is unclear, restructure first — name the concept, extract the translation, absorb the contract into a type — and reach for a comment only when the code cannot be made readable. An external constraint (a stdlib contract, a format detail, an upstream bug) is the prompt to absorb the constraint into a structure, not permission to stop at prose. A surviving comment explains why, never what. Commented-out code and TODO/FIXME markers SHOULD NOT be committed — version control holds the history, the issue tracker holds unfinished work (full policy: `.agents/rules/code/general.md`).

Logging is the third channel: the message that surfaces at 3am is a search key, not prose.

## Boundaries

APIs and databases are contracts with the outside world. Once clients or data depend on them, mistakes are expensive to fix. Production breaks on external data and external failures. Handle both explicitly at a single point, so the rest of the code can assume safe input and loud errors. A helper returns the error; the caller decides whether the flow stops or the failure is logged and tolerated.

## Testing and Debugging

Tests and debugging exist to catch what the author missed. Tests verify behavior: given this input, the output is this. A test that breaks when internals change but behavior does not is testing the wrong thing.

Find the root cause before you fix. Read the error, reproduce the failure, and trace the data flow to origin before touching code. Fix one cause at a time; bundling makes it impossible to know which change resolved the issue. After three failed attempts, the approach is the problem, not the attempt — stop and reconsider the framing. The confidence-trap list and the full methodology live in `.agents/rules/code/debugging.md`.

## Shell as a Last Resort

Shell is for tasks that native tools (Edit, Read, Write, Grep, Glob) cannot accomplish. Examples are binary manipulation and multi-step transformations with loops.

When such a command is complex, do not chain one-off invocations — each one needs its own approval. Write a script under `/tmp` and run the script instead. Keep it as simple as possible so a stranger can review it in one pass. Never let the script delete files.

## File Disposal

Deletion is not an operation you perform. When a file looks disposable, move it to `/tmp/discarded/` (create the folder when it is missing) instead of removing it. The OS empties `/tmp` on reboot — that is the only deletion that happens. This rule governs your own actions. A committed script may delete files when its job requires it.

## Verification

At a stopping point — a completed todo list, a delivered feature, or a handoff — audit the diff. Scope the audit to the change; skip rules unrelated to the diff.

- Explain the change in plain English to a programmer who has never seen this codebase. If the explanation needs knowledge the code does not provide — a stdlib contract, a format detail, a magic number — the code assumes knowledge instead of screaming its intention.
- Enumerate the rules the change touches. Check each against the work.
- Report findings before declaring complete: the checked rules and any deviations. A clean or empty report on non-trivial work is suspect — you likely missed something.

## Code Review

Review focuses on three areas, each with its own skill: coherence — logic, correctness, structural alignment (`.agents/skills/code-coherence-review/SKILL.md`); quality — coding standards, naming, style (`.agents/skills/code-quality-review/SKILL.md`); security — OWASP, attack surface, data flow (`.agents/skills/code-sec-review/SKILL.md`). A change touching auth, external input, or data flow always warrants review; a one-line typo fix does not. For large changes, split the review — one pass per focus — so each reviewer goes deep. Findings must be verified against the codebase before acting on them. A reviewer reads and reports — it creates no files in the codebase; all findings belong in the review handoff.

## Review Trust

A passing automated check is evidence, not proof. Linters, test suites, and ref checkers have blind spots — stale patterns, generated files, paths the tool doesn't cover. Manually verify the same category the tool checked wherever the tool's blind spot would have consequences — renames, path moves, permission and auth changes, data migrations are the usual suspects, but the test is consequence, not category.

## Frontend

Every piece of UI is a component with a single responsibility. Components should model their states explicitly (loading, empty, populated, error) and handle each one. State that affects multiple components lives in a shared store; state that affects only one stays local. Follow the existing design system — when it lacks what is needed, flag it rather than inventing a pattern. Interactive UI components should be keyboard-navigable.

When the change touches frontend, verify the rendered output in a browser before delivering (follows: `.agents/skills/browser-inspect/SKILL.md`).

## Context Maintenance

Two index files give direction, not implementation: **`.context.md`** (per directory) and **`docs/FEATURE-MAP.md`** (per project).

- Read the directory's `.context.md` before opening files in it.
- When one is missing or stale, dispatch `.agents/personas/contextualizer.md`.
- Update the affected file in the same commit as the change that made it stale.
- Formats and enforcement: `.agents/skills/context-maintenance/SKILL.md`.
