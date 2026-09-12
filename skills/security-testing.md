---
shortDescription: Active security testing catalog — per-mode checklists and controlled-exploitation discipline.
usedBy: [secops-engineer]
relatedTo: [burp, nuclei, ffuf, sqlmap, mitmproxy]
version: 0.1.0
lastUpdated: 2026-09-11
---

## Purpose

Reconnaissance finds the surface; testing finds the flaws. This skill is the catalog of what to test and the discipline for testing it without becoming the incident — a structured set of checklists per asset type, gated by authorization, rate-limited, and bounded so that a finding is proven without damaging the system or exfiltrating data.

## Procedure

1. **Confirm authorization for the specific action.** Every active test starts by checking the scope gate from `skills/security-assessment.md`: the asset is in scope, the action is permitted by the rules of engagement, and the window covers now. When unsure, stop — an unauthorized request is a legal event, not a finding.

2. **Web application (OWASP Top 10 / WSTG).** Test, as the mode allows:
   - **Injection** — SQL/NoSQL, OS command, LDAP, template (SSTI), XPath; trace untrusted input to each sink.
   - **Broken access control** — IDOR/BOLA, forced browsing, missing function-level authorization, tenant isolation.
   - **Authentication** — credential policy, lockout, MFA bypass, password reset flows, session fixation.
   - **Session management** — cookie flags (`Secure`, `HttpOnly`, `SameSite`), token entropy, logout invalidation, JWT (`alg:none`, key confusion).
   - **SSRF** — user-supplied URLs, metadata endpoints (`169.254.169.254`), allowlist bypass.
   - **XXE / deserialization** — external entities, native deserializers on untrusted input.
   - **File upload** — type/size restrictions, storage path, execution from the web root.
   - **Business logic** — price/quantity manipulation, workflow step skipping, race conditions.
   - **Client-side** — DOM/reflected/stored XSS, CSRF, postMessage, CORS misconfiguration.
   - **Security misconfiguration** — default creds, verbose errors, exposed admin, missing headers, debug endpoints.

3. **APIs (REST and GraphQL).** Authentication and token scope, object- and function-level authorization, mass assignment, rate limiting, introspection (GraphQL), batching/aliasing abuse, excessive data exposure, injection through parameters.

4. **Infrastructure and network (as scoped).** Exposed services and versions, TLS configuration and ciphers, default or weak credentials **only under explicit authorization**, patch-level correlation, management interfaces exposed to the internet.

5. **Cloud and infrastructure misconfiguration.** Public object storage, over-permissive IAM roles, exposed metadata, leaked keys in build artifacts or public repos, CI/CD exposure.

6. **Mobile (if in scope).** Insecure storage, transport (certificate pinning, cleartext), authentication/token handling, platform-specific IPC/deep links, jailbreak/root checks.

7. **Supply chain (always OSINT).** Identify third-party platforms and services and check them against `knowledge/security/watchlist.md`; never test a vendor's systems.

8. **Controlled exploitation discipline.** When authorized to exploit:
   - Prove the minimum: one record, one command, one request. Never dump a database, never exfiltrate bulk data, never pivot beyond the agreed boundary.
   - No destructive or state-changing actions against production without explicit, itemized authorization; prefer a test account or staging.
   - Stop at impact. Once impact is proven, withdraw and document. Do not chase a deeper shell for its own sake.
   - Log every request: timestamp, target, action, result. The evidence must let another engineer reproduce the finding.

9. **Evidence capture.** For each validated finding record: the raw request/response (or source location), the preconditions, the reproducible steps, the observed impact, and the timestamp. Chain evidence to the finding ID used in the report.

10. **Bounded and rate-limited.** One request per probe until a response is understood; throttle active tests; avoid fuzzing that can exhaust resources. If a test could degrade availability, it is out of scope unless explicitly permitted.

## Guardrails

- Never run an active test without recorded authorization for that asset and action.
- Never conduct denial of service, resource exhaustion, or high-volume fuzzing, regardless of authorization framing.
- Never perform credential stuffing or password guessing against real accounts — brute force is a separate, explicitly authorized engagement with defined lockout policy.
- Never exfiltrate more than the minimum needed to prove impact; one record is proof, ten is a breach.
- Never test a third party, and never pivot beyond the agreed network boundary.
- Never mark a candidate finding as confirmed until the impact is reproduced with captured evidence.
