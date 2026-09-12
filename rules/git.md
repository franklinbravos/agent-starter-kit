---
shortDescription: Git workflow rules for all coders.
scope: coding
version: 0.2.0
lastUpdated: 2026-09-12
---

## Statement

Run git from the repository root. Do not put global git flags between `git` and the command — no `git -C <path>`, `git -c <config>`, or `git --git-dir`. The permission patterns match plain `git <command>` forms only.

All commits MUST use conventional commit prefixes: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`.

Branch names MUST follow the same prefixes: `feat-*`, `fix-*`, `refactor-*`, `docs-*`, `test-*`, `chore-*`.

Commit messages MUST be short — a single phrase. If you need to describe too much, you should have committed earlier.

Commits SHOULD be scoped to a single logical change. When staged changes span multiple concerns (e.g., a refactor, a new feature, and a config update), split them into separate commits.

Database schema changes MUST be called out explicitly in the commit message.

Squash and rebase MUST NOT be used — ever. Merge commits preserve the true history. Rewriting history risks destroying work and misleading anyone who reads the log.

## Rationale

Consistent commit conventions enable automated changelogs, semantic versioning, and make git history readable. Short commits with clear intent are easier to review, revert, and bisect. Forbidding squash and rebase eliminates an entire class of mistakes — lost commits, force-push conflicts, and diverged histories — with no meaningful trade-off.

Global flags between `git` and the command hide the subcommand from the permission patterns. `git -C <path> push --force` matches no deny rule and slips through a broad allow. Plain `git <command>` forms keep every command visible to the permission layer.

A schema change alters what existing data means. Burying it in a commit about something else hides the migration risk from every future reader of the log.
