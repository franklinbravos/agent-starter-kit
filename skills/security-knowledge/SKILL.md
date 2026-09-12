---
name: security-knowledge
description: Continuous security intelligence — read, refresh, and grow the knowledge base each engagement.
usedBy: [secops-engineer, secops-manager]
relatedTo: [nvd, cisa-kev, sansec]
version: 0.2.0
lastUpdated: 2026-09-12
---

## Purpose

The agents must never restart from zero. Intelligence gathered in one engagement must make the next one sharper — a CVE learned today is a finding avoided tomorrow, a technique validated once is reused forever, and a mistake made once is never repeated. This skill defines the durable knowledge base under `knowledge/security/` and the read-at-start, write-at-end loop that grows it.

## Procedure

1. **Read at engagement start (step zero).** Before any reconnaissance, read every file in `knowledge/security/`: `README.md`, `sources.md`, `watchlist.md`, `techniques.md`, `lessons.md`. Load the watchlist into working context so fingerprinting can be matched against known-bad versions.

2. **Refresh the intelligence.** Read the `Last checked` date in `watchlist.md`. Query the sources in `sources.md` for advisories and KEV entries published since that date, prioritizing platforms in the watchlist and the target's stack. Verify each new entry against the vendor advisory or NVD before adding it — never enter rumor. Update `watchlist.md` (ID, product, type, severity, affected range, exploited, fix) and bump `Last checked`.

3. **Apply during the engagement.** Use `techniques.md` recipes for reconnaissance and fingerprinting. When a version is identified, check it against `watchlist.md` and the vendor advisory before attributing any CVE.

4. **Capture new techniques.** When a read-only recipe is validated in the field and is likely reusable, append it to `techniques.md` with its goal, command, and how to read the result. Keep each entry short and reproducible.

5. **Capture lessons.** At handoff, append to `lessons.md` any mistake that cost time or credibility and any rule that changed how the work is done. One entry per lesson, written as a rule the next reader can apply.

6. **Feed the skills.** When a lesson exposes a gap in a skill (`security-assessment`, `security-testing`, `security-report`), update that skill and record the change in `CHANGELOG.md`. The knowledge base is where raw learning lands; the skills are where it becomes procedure.

7. **Never store secrets or PII.** The knowledge base is versioned with the agent. Record only platform-level intelligence — no client data, credentials, tokens, or personal information.

## Guardrails

- Never skip step 1. Reading the base is what prevents repeating a solved problem.
- Never write a watchlist entry from a secondary article alone — confirm against the vendor advisory or NVD, and mark anything unverified as such.
- Never let the knowledge base drift from the skills: if a procedure changed, the skill must change, not just the notes.
- Never record client-identifying detail. "A Magento store on 2.4.7-p10" is intelligence; the client's name and findings are not.
