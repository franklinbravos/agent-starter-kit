---
name: code-quality-review
description: Reviews code and plans against the project's coding rules.
usedBy: [reviewer]
version: 0.3.0
lastUpdated: 2026-09-12
---

## Purpose

A code review without a checklist drifts toward gut feeling — the reviewer catches what they notice and misses what they don't. This skill turns the project's coding rules into a repeatable procedure. It tells the reviewer what to inspect and in what order.

## Procedure

1. **Initialize the progress file.** Create `.memory/reviews/review-quality-<timestamp>.md`:

   ```markdown
   # Quality Review Progress
   
   ## Status
   - Last updated: <timestamp>
   - Overall: In Progress
   
   ## Phases
   - [ ] 1. Collect applicable rules
   - [ ] 2. Walk work against rules
   - [ ] 3. Verify style proximity
   - [ ] 4. Dedup findings
   
   ## Files
   - [ ] <path>
   - [ ] <path>
   
   ## Findings
   ```

2. **Collect the applicable rules.** Load all files from `rules/code/`. Also load any applicable rules (e.g., `rules/git.md`). Classify each rule's statements by RFC language:
   - **MUST / MUST NOT / SHALL / SHALL NOT** — violations are always Blockers. No exceptions.
   - **SHOULD / SHOULD NOT** — violations require justification visible in the code (a comment earned under `rules/code/general.md` § Comments, a design note, or a `.context.md` entry). If the justification is clear, it is a Warning. If absent or unclear, it is a Blocker.

    Language-to-severity mapping:
    - MUST violation → always Blocker.
    - SHOULD violation without visible justification → Blocker.
    - SHOULD violation with documented justification → Warning.

   If the codebase uses a specific language with a dedicated rule file, include that file. If the language has no dedicated file, apply only `rules/code/general.md`. One pass-routing exception — severity rules are unchanged: the behavior-over-implementation rule in `rules/code/general.md` § Testing is a test-proof question — hand it to the coherence pass per the Guardrails; do not classify it here.

   Mark phase 1 as `[x]` in the progress file.

3. **Walk the work against every rule and classify findings.** Check each statement in each loaded rule file against the changed code or plan. Do not skip or paraphrase rules — the rules are the source of truth. Classify each issue found:
   - **Blocker** — MUST violation, unjustified SHOULD violation, readability violation (cryptic code is always a blocker). Must be fixed.
   - **Warning** — justified SHOULD deviation, minor inconsistency. Should be addressed.
   - **Note** — style suggestion beyond what rules mandate. No action required.

   After reviewing each changed file, update the progress file: mark the file as `[x]` with finding counts, add findings under `## Findings`:

   ```
   ### <file-path>
   
   **Blockers:**
   - <file>:<line> — <what violates which rule>. (rule: <rule-file-name>)
   
   **Warnings:**
   - <file>:<line> — <what violates which rule>. (rule: <rule-file-name>)
   
   **Notes:**
   - <file>:<line> — <observation>
   ```

   Mark the file as reviewed. Move to the next file only after the progress file is saved. Mark phase 2 as `[x]` when all files are reviewed.

4. **Verify style proximity.** For each changed file, run `ls` on its directory. Read one or two sibling files — pick those most similar in function to the changed code. Compare the changed code against the siblings. Flag any structural or pattern mismatch as a Warning. The Coder's self-review is not evidence — verify independently.

   Add style findings to the progress file under each file's section. Mark phase 3 as `[x]`.

5. **Dedup findings.** Review all findings in the progress file. If a style proximity finding overlaps with a rule-based finding (e.g., both caught the same naming issue — one as style mismatch, one as rule violation), keep the rule-based finding and remove the style duplicate. The rule finding has a specific rule reference; the style finding is redundant.

   Mark phase 4 as `[x]` and set Overall to `Complete`. If review is interrupted, the progress file shows which phases were completed.

## Guardrails

- Never flag a SHOULD deviation as a blocker when justification is documented. SHOULD is guidance, not law — documented justification earns a warning, not a veto.
- Never invent rules. If an issue does not trace back to a loaded rule file, it is a Note at most, not a Warning or Blocker.
- If a pattern match is ambiguous, skip it rather than rationalizing it into a finding.
- Never flag line length in template or markup files (templ, HTML, JSX, Vue SFCs, etc.). A single tag or attribute list often cannot be split without harming readability — the line-length rule exempts these. Apply the limit to surrounding logic code, not to the markup.
- Never flag test proof issues — whether a test verifies behavior or skip markers. Those are coherence questions. Test style issues land here through the rules: naming, table-driven cases, setup placement, file independence mechanics (`rules/code/general.md` § Testing).
