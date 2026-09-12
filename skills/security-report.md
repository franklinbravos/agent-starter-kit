---
shortDescription: Kolivo security report standard — technical and management HTML, reproducible from zero.
usedBy: [secops-engineer, secops-manager]
version: 0.2.0
lastUpdated: 2026-09-11
---

## Purpose

An assessment is only as good as the document that carries it. This skill is the complete specification of the Kolivo report standard: two deliverables (a technical report for the engineer, a management report for the executive), their mandated sections, the visual identity, the severity scale, the zero-day convention, and the integrity statement. It is written to be self-sufficient — a session starting from nothing must be able to reproduce a report of the same quality by following this file alone, without the prior artifact in context.

## Procedure

1. **Choose the deliverables.** The **technical report** is produced for every engagement by the SecOps Engineer. The **management report** is produced by the SecOps Manager when the result must inform a decision or win sign-off; it reframes the same findings in business language and may carry the proposal. Both are single, self-contained HTML files — no build step, no external dependency except a web font.

2. **Apply the Kolivo identity.**

   | Token | Value | Use |
   |---|---|---|
   | `--navy` | `#181828` | sidebar background |
   | `--accent` | `#5a5aff` | links, index, highlights |
   | `--accent-ink` | `#3d3dc9` | section numbers, emphasis |
   | `--ink` / `--ink-dim` / `--ink-faint` | `#14141f` / `#4b4c5e` / `#85869c` | text hierarchy |
   | `--red` / `--amber` / `--green` | `#d64437` / `#b9770e` / `#1f9d63` | severity critical/high, medium, low/positive |
   | font | **Raleway** 300–800 (Google Fonts) | all text |

   Layout: fixed left sidebar (navy) with the inline Kolivo SVG logo at top, the numbered index below, and scrollspy highlighting the active section; light content column to the right; cards and tables for findings; a print stylesheet. All CSS lives in one `<style>` block so the file renders standalone. Include a footer with the Kolivo logo/wordmark, the document line, and contact details.

3. **Technical report — mandated sections**, in order: `Resumo executivo` (opens with a risk verdict gauge and the finding counts by severity) · `Inventário de ativos` (asset | stack | infra | observation) · `Subdomínios e ambientes` (Certificate Transparency) · `DNS, e-mail e TLS` · `Headers de segurança` (comparison table) · one deep-dive section per topic (WordPress, application, APIs, infrastructure) · `Cadeia de suprimentos` when a dependency exists · `Registro de achados` (consolidated, one row per finding) · `Recomendações` (prioritized, mapped to finding IDs) · `Pontos positivos` · `Metodologia & log`. Each major finding is a card with ID, severity badge, locators, raw evidence, and remediation.

4. **Management report — mandated sections**, in order: `Resumo executivo` · `O que foi avaliado` · `Principais riscos` (one card per business risk — no exploitation detail, no payloads) · `Contexto de ameaça` (brand/reputational context when relevant) · `Impacto no negócio` (financial, data/LGPD, operational, reputation) · `Pontos positivos` · `O Pentest completo` (the proposal: what a full engagement adds beyond the diagnostic) · `Próximos passos`. It never exposes a technical exploitation path.

5. **Zero-day convention.** When a finding is a zero-day — a flaw exploited before an official fix exists — render, in **both** reports, a dedicated callout explaining the concept (the vendor had "zero days" to prepare; no fix or ready defense exists when exploitation begins; it typically needs no password, account, or user action; until the hotfix, containment and isolation are the only options) and tag the finding with a red **ZERO-DAY** badge. A zero-day in active exploitation is always `crítico`.

6. **Severity scale.** Use the same five levels in both reports: `crítico`, `alto`, `médio`, `baixo`, `info` (definitions in `skills/security-assessment.md`). A finding's severity is identical in every artifact.

7. **Integrity statement.** The methodology section states the method and limits: read-only or authorized-active, **0 data altered**, no accounts created, no credentials submitted, no third-party systems touched, and what remains unconfirmed without credentials or authorization. The management report carries a gate making clear the technical detail and exploitation live in the contracted engagement.

8. **Validate before delivery.** Confirm the HTML is well-formed (no unclosed or stray tags) and open the file to confirm it renders. Cross-check that every finding in the register appears in the deep-dive sections and the recommendations, with matching IDs.

## Guardrails

- Never ship a management claim with no evidence base in the technical artifact.
- Never present a finding without evidence and remediation — a risk with no fix is noise.
- Never include secrets, tokens, credentials, or personal data in either report.
- Never let an ID, severity, or count diverge between the two reports — one finding, one ID, one severity.
- Never bury a critical finding in a table only; it gets a visible card and, if a zero-day, the callout and badge.
- Never depend on a prior report being in context — regenerate the standard from this skill.
