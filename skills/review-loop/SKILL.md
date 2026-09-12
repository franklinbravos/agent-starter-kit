---
name: review-loop
description: Two-mode review loop — single reviewer per epic, three reviewers for full branch.
usedBy: [maestro]
version: 0.5.0
lastUpdated: 2026-09-12
---

## Purpose

This skill defines how the Maestro reviews sub-agent work before it reaches the user. Two modes serve different needs. Incremental reviews (per epic) use one reviewer. Full branch reviews (at feature completion) dispatch three reviewers for full coverage.

## Procedure

1. **Determine mode.**

   - **Incremental** (default) — used for per-epic reviews during plan execution.
   - **Full branch** — used when all epics in `impl.md` are marked ✓ and the review covers the entire branch's accumulated changes. Triggered by `skills/plan-management/SKILL.md` → Tracking Progress.

2. **Identify scope.** Determine the changed files. Use the command matching the current mode:

   - **Incremental** — files changed since the last commit:
     ```bash
     git diff HEAD --name-only; git ls-files --others --exclude-standard
     ```
   - **Full branch** — files changed against the base branch:
     ```bash
     git diff "$(git merge-base HEAD main)" --name-only; git ls-files --others --exclude-standard
     ```

   If no files changed, skip the review loop.

3. **Dispatch.** Dispatch the reviewer (`personas/reviewer.md`) (follows: `skills/dispatch/SKILL.md`).

   **Incremental mode** — single dispatch. Reviewer runs all three lenses.

   **Full branch mode** — three dispatches with focused `<task>`:
   - First: coherence focus (follows: `skills/code-coherence-review/SKILL.md`).
   - Second: quality focus (follows: `skills/code-quality-review/SKILL.md`).
   - Third: security focus (follows: `skills/code-sec-review/SKILL.md`).

   For plans and non-code work, use a single dispatch regardless of mode.

   The `<task>` for every reviewer dispatch must include:
    - What was produced (artifact type and affected scope).
    - The original `<task>` or acceptance criteria.
    - For code: the list of changed files.
    - The focus area (for Full branch mode).

4. **Merge findings.** When all dispatched reviewers return:
   - Union all blockers, warnings, and notes across all reviewers.
   - Deduplicate identical entries — same file, same line, same issue counts once. Dedup before verify is intentional; step 5 verifies each remaining finding.
   - If verdicts conflict, the stricter verdict wins.

   For single-dispatch reviews (incremental mode), use its findings directly.

5. **Verify findings.** Before acting on any reviewer output, spot-check each blocker and warning against the codebase. Reviewers can hallucinate — flag false positives (invented violations, misread paths, fabricated rules) and discard them. Only confirmed findings proceed. When confirmed hallucinations appear, classify the cause before re-dispatching:
   - **Missing context** — the boot payload lacked information the reviewer needed. Fix: enrich the task brief, add memory or skills.
   - **Ambiguous input** — the task brief had multiple interpretations. Fix: tighten the brief.
   - **Design flaw** — a skill or persona instruction led the reviewer astray. Fix: patch the framework file and record the fix in long-term memory.
   - **Model limitation** — the model cannot handle the task at this tier. Fix: switch provider.

    After verifying reported findings, spot-check for **missing** findings. Pick the first 3 paths in the changed code that involve error handling, authentication, authorization, data mutation, or external I/O, and verify the reviewers addressed them. A reviewer that returns zero findings on complex changes is suspect. A clean bill from a skimmed review is a false pass.

6. **Determine the verdict.**
   - `pass` — zero confirmed blockers and all review steps completed.
   - `partial-pass` — zero confirmed blockers but one or more review steps were skipped (e.g., external tool unavailable). Surface the gap to the user.
   - `fail` — one or more confirmed blockers.

7. **Handle failure.** If the verdict is `fail`:
    1. Present the verified findings to the user before re-dispatching.
    2. The user may provide additional input — incorporate it into the re-dispatch.
    3. If the failed artifact is a plan, re-dispatch the Architect (`personas/architect.md`) (follows: `skills/dispatch/SKILL.md`) with the confirmed findings. If the failed artifact is code, re-dispatch the Coder (`personas/coder.md`) (follows: `skills/dispatch/SKILL.md`) with the findings (blockers, warnings, notes).
    4. When the Coder returns, restart this procedure from step 1 with the new deliverable.
    5. Repeat until the verdict is `pass` or `partial-pass`. If the cycle exceeds 2 re-dispatches without reaching a passing verdict, yield to the user with the confirmed findings, conflicting verdicts, or ambiguous trade-offs that could not be resolved.

8. **Handle success.** If the verdict is `pass` and the artifact is code from a plan, mark the epic as delivered in `impl.md` (follows: `skills/plan-management/SKILL.md` → Tracking Progress).

## Guardrails

- Never skip the verify step (step 5). Unverified findings from reviewers must not reach the user or trigger re-dispatches.
- Never re-dispatch after a hallucination without investigating and fixing the cause first. Blind re-dispatch repeats the same failure.
