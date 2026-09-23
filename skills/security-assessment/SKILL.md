---
name: security-assessment
description: Security engagement methodology — scope gate, black/gray/white-box modes, full lifecycle.
usedBy: [secops-engineer, secops-manager]
relatedTo: [dig, curl, openssl, crt.sh, certspotter, nvd, cisa-kev]
version: 0.4.0
lastUpdated: 2026-09-23
---

## Purpose

A security engagement fails in three ways: it crosses a line it had no right to cross, it reports something it never observed, or it tests the wrong things because the rules were never fixed. This skill defines the engagement models (black, gray, white-box), the scope gate that precedes all work, and the lifecycle every engagement follows from reconnaissance to retest. It is the backbone the other security skills hang from — `skills/security-testing/SKILL.md` executes the phases, `skills/security-report/SKILL.md` delivers them, `skills/security-knowledge/SKILL.md` carries the learning forward.

## Engagement modes

The mode defines how much information the tester starts with and, therefore, which phases apply.

- **Black-box.** No internal information. The tester sees only what an outside attacker sees: public DNS, certificates, HTTP responses, exposed services. Emphasizes reconnaissance, enumeration, and exposed-surface findings. Slowest and shallowest — it measures the view from outside.
- **Gray-box.** Partial information: credentials for one or more roles, an architecture summary, API docs, or a staging environment. Emphasizes authorization testing (RBAC, IDOR/multi-tenant), business logic, and authenticated API testing. The most common real-world engagement.
- **White-box.** Full information: source code, architecture, configuration, infrastructure, credentials. Emphasizes static analysis, code-level flaw hunting, dependency and secret review, and configuration auditing. Uses the code review skills (`skills/code-sec-review/SKILL.md`, `skills/code-coherence-review/SKILL.md`, `skills/code-quality-review/SKILL.md`) for the source-code pass.

A mode is not fixed by the marketing name — record exactly what was provided. "Gray-box" with only a staging URL and no credentials is black-box with a hint; say so.

## Authorization

Active work needs two grants in the engagement record:

- **Client authorization** — the asset owner's permission, with a reference to the instrument that grants it: a contract, a signed rules-of-engagement, or a written authorization. A pasted URL is intent, not authorization.
- **Operator authorization** — the operator's express, dated grant to run active work. The record names who granted it, the date, the assets and actions it covers, and the client-authorization reference it rests on.

When both grants are present and non-empty, the scope gate passes. The agent executes the authorized work without per-step escalation. It does not re-ask for permission the operator already granted. When either grant is absent or ambiguous, the engagement is **passive OSINT only** — every active step is skipped, and the limit is stated in the deliverable.

### Hard limits

No authorization waives these four limits. An agent stops and reports instead of acting:

- A third-party, shared-hosting, or out-of-scope asset.
- Denial of service, resource exhaustion, or high-volume fuzzing.
- Exfiltration beyond the minimum needed to prove impact.
- Credential stuffing or password guessing against real accounts — brute force is its own engagement, with a defined lockout policy.

## Procedure

1. **Scope gate (before any collection).** Read the authorization section of the engagement record. Extract the in-scope assets, the client authorization, the operator authorization, the rules of engagement (window, rate limits, prohibited actions), the mode, and the emergency contact. When both grants pass, active work proceeds without per-step escalation. When either fails, the engagement is passive OSINT only — every active step is skipped and the limit is stated in the deliverable.
2. **Engagement record.** Create or update the client workspace with title, targets, mode, authorization status, dates, and rules of engagement. Every later artifact references it. Read the prior record if the workspace exists.
3. **Knowledge load (step zero).** Read and follow `skills/security-knowledge/SKILL.md` — load the watchlist and refresh intelligence before reconnaissance.
4. **Phase 1 — Reconnaissance.** Passive and, in gray/white-box, active as authorized: DNS, WHOIS/RDAP, Certificate Transparency, TLS, HTTP headers, technology fingerprint, and — for white-box — the provided source/architecture. Record raw evidence.
5. **Phase 2 — Enumeration and surface mapping.** Build the asset and endpoint inventory appropriate to the mode: hosts and services (black), authenticated roles and APIs (gray), code modules and dependency tree (white).
6. **Phase 3 — Vulnerability analysis.** Match the fingerprinted stack against `knowledge/security/watchlist.md` and vendor advisories; run the relevant checklist from `skills/security-testing/SKILL.md`. For white-box, add the static review. Produce candidate findings with evidence.
7. **Phase 4 — Controlled validation.** Confirm findings by the least invasive means that proves impact, strictly within authorization. Prefer version/reachability evidence; exploit only when authorized and only to the minimum depth that proves the issue. Never exceed scope, never damage data, never move laterally beyond the agreed boundary.
8. **Phase 5 — Impact and severity.** For each confirmed finding, state the concrete impact (data, availability, integrity, chain) and assign severity on the fixed scale: **crítico**, **alto**, **médio**, **baixo**, **info**. Separate confirmed from inferred.
9. **Phase 6 — Findings register.** One row per finding: `ID | Severity | Finding | Evidence | Remediation`. Every finding carries a locator to its evidence and a remediation.
10. **Phase 7 — Reporting.** Read and follow `skills/security-report/SKILL.md`: the SecOps Engineer produces the technical report, the SecOps Manager produces the management report from the same findings.
11. **Phase 8 — Retest.** After remediation, re-verify each finding with the same evidence discipline and report pass/fail per finding.
12. **Knowledge write (at handoff).** Read and follow `skills/security-knowledge/SKILL.md` — append lessons, techniques, and watchlist updates.

## Integrity log

Every engagement states its method and limits: read-only or authorized-active, the operator authorization that covered the active work, data altered only as the authorization allowed, no third-party systems touched, and what remains unconfirmed without credentials or authorization. This log is part of the deliverable.

## Guardrails

- Never begin active work without a recorded authorization, scope, and rules of engagement.
- Never re-escalate for an action the recorded operator authorization already covers — execute the authorized work.
- Never treat any authorization as waiving the hard limits — a third-party asset, denial of service, bulk exfiltration, and real-account brute force stay out.
- Never test a third party, a shared-hosting neighbour, or an asset absent from the scope — a client's vendor is OSINT-only unless separately authorized.
- Never exceed the agreed boundary in Phase 4, even when a deeper step is technically possible.
- Never substitute the mode: if credentials were not provided, it is not gray-box — do not guess.
- Never report a version→CVE match without checking the exact affected range.
- Never carry secrets, tokens, or personal data out of a system into a report or workspace.
