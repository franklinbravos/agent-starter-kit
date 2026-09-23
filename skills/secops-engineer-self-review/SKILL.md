---
name: secops-engineer-self-review
description: Deterministic self-evaluation rubric for the SecOps Engineer — scored every run using PROOF.
usedBy: [secops-engineer]
version: 0.3.0
lastUpdated: 2026-09-23
---

## Purpose

A security finding is a claim about reality, and a wrong claim is worse than no claim — it sends a team to fix the wrong thing and destroys trust in the next report. Before delivering a handoff, the SecOps Engineer evaluates its own output against the PROOF rubric. Each letter is scored 0, 1, or 2. The total decides whether to deliver, correct, or restart. This replaces confidence with a checklist that mirrors what an adversary or an auditor would challenge.

## Procedure

1. **Score each criterion.** After completing the engagement work and the technical report, read the PROOF rubric and assign 0, 1, or 2 to each letter. Keep the breakdown internal.
2. **Apply the hard-fail rule.** If any letter scores 0, do not deliver — go to step 3.
3. **Determine action by total score:**
   - **9 – 10** — **DELIVER** — Every finding is grounded, scoped, and accurate. Deliver the handoff.
   - **7 – 8** — **FIX the scored < 2 criteria.** Identify the gaps, correct them by re-verifying evidence or re-checking the range — never by softening a real finding — then re-score and deliver if 9-10. After 2 failed attempts, yield with scores and blocking letters.
   - **0 – 6** — **RESTART** — The assessment or its reporting is unsound. Rebuild it with corrected understanding, or yield with an explanation.

## PROOF Rubric

### P — PROVENANCE

_Did every finding come from something I actually observed?_

- **0** — One or more findings rest on assumption, a tool's inference, or prior memory rather than evidence in this engagement; a version, status, or header is asserted without a capture.
- **1** — All findings have evidence, but a locator is vague or an inference is not labeled as such.
- **2** — Every finding traces to concrete evidence (status code, response header, certificate field, CT record, source location, advisory). Confirmed and inferred are separated, and inferred items name the test that would confirm them.

### R — RANGE

_Was every CVE and version attribution verified against the exact affected range?_

- **0** — A CVE is attributed without checking the range, a fix version is named as vulnerable, or the newest patch level is assumed safe without checking for an out-of-band hotfix.
- **1** — Ranges checked but from a secondary source, or the exploited-in-the-wild (KEV) status is unstated.
- **2** — Every attribution is checked against the vendor advisory or NVD, records identifier and CVSS, states KEV status where known, and distinguishes a confirmed vulnerability from a merely outdated version.

### O — OWNERSHIP

_Did I stay inside the authorized scope, and treat third parties as OSINT-only?_

- **0** — Tested outside scope, ran an active probe against a third party or neighbour, or took an intrusive action (credential submission, account creation, exploitation, fuzzing, load) without authorization.
- **1** — Stayed in scope, but a boundary is unclear in the report — the scope, the exclusions, or the mode is not stated, or a third party's OSINT is not labeled.
- **2** — Every action is within the authorized scope and covered by the recorded operator authorization; third parties are public-information only; the report states what was in and out of scope and the mode; the scope-gate decision is recorded.

### O — OBJECTIVITY

_Are the conclusions honest about what is confirmed and what is not?_

- **0** — Inferred behavior is presented as a confirmed vulnerability, or severity is inflated or softened beyond the evidence.
- **1** — Severities are defensible but limitations are thin — what could not be tested without credentials or authorization is not clearly listed.
- **2** — Severities follow the scale and match the evidence; confirmed and inferred stay apart; limitations and untested areas are stated plainly; nothing is inflated or softened.

### F — FABRICATION-FREE

_Is the record clean of invented data and of other people's secrets?_

- **0** — Any invented datum (route, version, count, screenshot) or any secret, token, credential, or personal data copied out of a client system.
- **1** — No fabrication and no secrets, but a count, asset name, or date is inconsistent between the technical and management artifacts.
- **2** — No fabricated data and no secrets, tokens, or personal data anywhere; IDs, severities, and counts match across artifacts; the integrity statement (read-only/authorized-active, 0 data altered, no accounts, no exploitation) is present and true.

## Guardrails

- Never deliver if any letter scores 0 — a zero is a hard fail, regardless of total.
- Never soften a confirmed finding to reach a passing score. Fix the evidence or the scoping, not the truth.
- Never skip scoring any letter — all 5 are evaluated every run.
- The rubric is fixed — do not add or remove criteria. If a criterion proves inadequate, file a framework change request.
- When fixing gaps (7-8), only address the letters that scored below 2.
- After 2 failed fix attempts, yield — do not keep looping.
