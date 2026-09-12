---
shortDescription: Deterministic self-evaluation rubric for the SecOps Manager — scored every run using CLEAR.
usedBy: [secops-manager]
version: 0.1.0
lastUpdated: 2026-09-11
---

## Purpose

A management report that overstates risk destroys credibility on the first question from the client's technical team; one that understates it leaves a real exposure unfunded. Before delivering, the SecOps Manager evaluates its own output against the CLEAR rubric. Each letter is scored 0, 1, or 2. The total decides whether to deliver, correct, or restart. It replaces persuasive instinct with a checklist that keeps the business narrative faithful to the evidence.

## Procedure

1. **Score each criterion.** After completing the management report, read the CLEAR rubric and assign 0, 1, or 2 to each letter. Keep the breakdown internal.
2. **Apply the hard-fail rule.** If any letter scores 0, do not deliver — go to step 3.
3. **Determine action by total score:**
   - **9 – 10** — **DELIVER** — The narrative is faithful, prioritized, and actionable. Deliver the handoff.
   - **7 – 8** — **FIX the scored < 2 criteria.** Correct the gaps, re-score, and deliver if 9-10. After 2 failed attempts, yield with scores and blocking letters.
   - **0 – 6** — **RESTART** — The report misrepresents the technical reality. Rebuild it from the findings register, or yield with an explanation.

## CLEAR Rubric

### C — COVERAGE

_Did every technical finding make it into the business picture, with none invented?_

- **0** — A confirmed technical finding is missing from the management report, or a risk appears that has no technical finding behind it.
- **1** — All findings are represented but not mapped to finding IDs, so the link to the technical report is not traceable.
- **2** — Every confirmed technical finding maps to a business risk by ID, nothing is dropped, and nothing is invented; unreported inferred items are explicitly excluded.

### L — LEGITIMACY

_Is each claim backed by the evidence, with nothing exaggerated or softened?_

- **0** — A business claim exceeds the evidence (a "likely breach" built on an outdated version) or is softened below it to please the room.
- **1** — Claims are defensible but one impact is stated more confidently than the evidence supports.
- **2** — Each claim is proportional to its finding's severity and evidence; confirmed and inferred are kept apart; nothing is inflated to win work or softened to keep comfort.

### E — EVIDENCE CONSISTENCY

_Do the numbers match the technical artifact?_

- **0** — A count, ID, severity, version, or date differs between the management and technical reports.
- **1** — Numbers match, but a severity label or finding count is phrased inconsistently enough to confuse.
- **2** — IDs, severities, counts, versions, and dates are identical across both artifacts; the register reconciles exactly.

### A — AUDIENCE

_Is it written for a decision-maker, without an exploitation path?_

- **0** — Contains an exploitation path, payload, step-by-step attack, or dense jargon a decision-maker cannot act on.
- **1** — Business language throughout, but one section drifts into technical detail that adds no decision value.
- **2** — Every section is readable by a non-technical executive; impact is in data/LGPD, money, operations, and reputation; no exploitation detail appears anywhere.

### R — RECOMMENDATION

_Is the ask concrete, prioritized, and tied to the risk?_

- **0** — No recommendation, or a generic pitch unconnected to the findings.
- **1** — Recommendations exist but are unprioritized or only loosely tied to the findings.
- **2** — Each risk has a prioritized action mapped to finding IDs, and the proposal states concretely what the full engagement adds and the requested next step.

## Guardrails

- Never deliver if any letter scores 0 — a zero is a hard fail, regardless of total.
- Never inflate a finding to strengthen the proposal or soften one to keep the room comfortable.
- Never add exploitation detail to make the report "more concrete" — concreteness comes from impact, not payloads.
- Never skip scoring any letter — all 5 are evaluated every run.
- The rubric is fixed — do not add or remove criteria. If a criterion proves inadequate, file a framework change request.
- After 2 failed fix attempts, yield — do not keep looping.
