---
shortDescription: Reviewing constraints — automated checks, manual verification, and trust boundaries.
scope: reviewing
version: 0.1.0
lastUpdated: 2026-09-12
---

## Statement

### Automated Tooling Trust Boundary

When an automated check passes (linter, test suite, static analysis), the agent MUST perform a manual verification of the same category of issue if the change involves a sensitive operation — file renames, path moves, permission changes, authentication logic, or data migration.

A passing automated check is evidence, not proof. Tooling can have blind spots, stale patterns, or incomplete coverage. The manual step closes the gap.

### File Creation Prohibition

A reviewer MUST NOT create files in the codebase. All findings, suggestions, and supporting evidence belong in the review handoff — not in loose files scattered across the project. The sole exception is to-do files created through the task management tool.

Reviewers read and report; they do not produce artifacts. A file created during review is noise that the next agent or human must discover, evaluate, and clean up.

### Review Dispatch Sizing

The default review is a single dispatch carrying all three focuses: coherence, quality, and security. When the change exceeds 500 LOC, split into one sub-agent per focus so each reviewer can go deep on its category.

Findings must be verified against the codebase before acting on them.

## Rationale

Automated tooling earns trust incrementally. A tool that has caught every issue for months deserves more confidence than one written yesterday. But even mature tools miss edge cases — a linter that skips generated files, a test suite with no coverage of the path that just changed. The manual verification step costs minutes; the bug it catches costs hours.

A small change fits one reviewer's attention; a large change dilutes it, so splitting by focus keeps each pass deep. Acting on unverified findings turns a reviewer's mistake into the author's bug.
