---
shortDescription: Enforces use of context-maintenance skill on structural and feature changes.
scope: coding
version: 0.0.1
lastUpdated: 2026-09-12
---

## Statement

Any persona that modifies project files MUST follow `skills/context-maintenance/SKILL.md` to determine whether a `.context.md` or `docs/FEATURE-MAP.md` update is required and, if so, produce it in the same commit. A context file update that describes a code change is part of the same logical change — not a separate commit.

## Rationale

Without enforcement, context files and the feature map drift silently. By the time anyone notices, they are misleading rather than helpful — worse than having none at all. The feature map is especially critical: a stale map sends agents down the wrong code path and wastes entire sessions.
