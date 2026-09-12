# Lessons — Mistakes and Rules Learned

Each lesson is a mistake that cost something or a rule that changed how we work. Add one entry per engagement review.

## Authorization and scope

- **A pasted URL is intent, not authorization.** Before any active test, obtain written scope: who authorized it, the assets, the window, and the prohibited actions. Without it, the engagement is passive OSINT only.
- **A client's vendor is a third party.** Testing a vendor without separate authorization is out of scope, even when the client owns the data. Vendors are OSINT-only.
- **Report the scope you actually had, not the scope that sounds impressive.** State what was excluded and what remains unconfirmed.

## Evidence and accuracy

- **Verify the affected range before attributing a CVE.** A version can be the one that *introduced the fix*. Example: GitLab 16.8.1 is the patch for CVE-2024-0402, not a vulnerable version — reporting it as a flaw would have been a false positive.
- **The newest patch level is not proof of safety.** Magento 2.4.7-p10 was current and still exposed to CVE-2026-75650 until an out-of-band hotfix. Distro backports further break the version→CVE mapping.
- **Separate confirmed from inferred.** A route that "looks guarded" is inferred until a test confirms it. Label it and name the test that would confirm it.
- **Let evidence downgrade a finding.** A public signup form looked like an open door; the manual test showed accounts require administrator approval. The finding moved from crítico to médio — the report became truer.
- **A `200` from an SPA is not a file.** An SPA/Vercel catch-all returns `index.html` (200) for `/.env`, `/graphql`, `/api/health`, and `*.js.map`. Check `content-type` and byte size before calling it an exposure — a ~900-byte `text/html` response for `/.env` is the app shell, not a leak.
- **A public publishable key is not a secret.** Supabase `sb_publishable_…` and legacy anon JWTs ship to every browser. Report them only when a table or RPC returns data the caller should not see (RLS off), never on the key alone.
- **Open signup + auto-provisioning is an access path, not a registration nuance.** A Supabase `disable_signup:false` becomes serious when a trigger grants roles/permissions at signup — a self-registered outsider becomes an authenticated, provisioned user. Test what the new user can read (RLS by role), not just whether signup succeeds.
- **Email confirmation is not authorization.** When signup requires email confirmation, that only proves the address is reachable — a public/disposable inbox completes it. The real gate is what the confirmed user is allowed to do.
- **A tenant column the user can write is not an access control.** When RLS keys off a field the client can UPDATE (e.g. `profile.organization_id`), any authenticated user can switch tenants. Test it: write the target tenant id into your own row, then re-read the scoped table — a count moving from 0 to N is a cross-tenant break.
- **Prove INSERT permission without creating a row.** POST `{}` to the table; a `42501` (RLS) means blocked, while a `23502/23503` (constraint) means RLS allowed the insert and only the data was invalid. The constraint error proves the write path is open with no data left behind.
- **Ticket content is a credential store in disguise.** Service desks accumulate API keys, session tokens, and passwords in descriptions and comments. Once you can read tickets (via tenant hop or an RLS gap), scan the text fields for secret patterns and cross-reference project refs — a leak is a lateral-movement path. Validate a leaked key read-only (does the endpoint answer?) but never log in with leaked passwords during an assessment.
- **Confirm the secret type before reporting it.** A `service_role` string can be a remediation note, an anon key is public by design, and a session token may be expired. Decode the JWT payload (role/ref/exp) and probe read-only to classify — only a valid, privileged credential is a critical finding.
- **Leaked test credentials usually target a staging preview, not production.** QA notes reference the preview URL they tested (`*-<name>.vercel.app`); identify the app's auth library (Supabase `signInWithPassword` vs Better Auth `/api/auth/sign-in/email`) and test there. Watch for `429` — a sign-in rate limit is a control, not a failure: stop rather than hammer.
- **Inventory attachments by metadata even when files are not downloadable.** The `attachments` table exposes names/types/sizes; `xlsx`/`pdf` entries indicate HR/financial PII even if storage RLS blocks the download — report the exposed metadata and confirm the storage boundary separately.
- **Confirm the shipped plugin version from the vendor's own asset, not only `readme.txt`.** The Stable tag can lag; the plugin's `?ver=` and the banner in its minified JS reflect the installed code. A bundled library's version (e.g. a `particles.js?ver=3.0.6` path) is not the plugin version — using it flips a finding false.
- **A reflected `Origin` with `Access-Control-Allow-Credentials: true` is worse than `*`.** The wildcard is rejected by browsers when credentials are present; reflection actually grants cross-origin reads. Report the reflection on its own, not under a generic "permissive CORS" line.
- **Check core↔plugin compatibility for availability, not just CVEs.** A plugin can be fully patched and still fatal-error against a new core major (WordPress 7.1 + WP Rocket < 3.23.2.2). A live homepage does not prove the condition is absent.

## Testing discipline

- **Never guess credentials or create accounts on production.** Try a password and you are conducting an attack; create an account and you are mutating live data. Both need an authorized test environment.
- **Do not confirm a vulnerability by exploiting it unless authorized.** Reachability and version evidence is enough for a finding; exploitation belongs in an authorized, controlled test.
- **Read the error, then trace the data flow.** Verify that untrusted input actually reaches the sink before calling it a vulnerability.

## Supply chain

- **A platform flaw upstream is a flaw in the target.** Map the target's dependencies (e-commerce, payments, hosting, SaaS) and check each against advisories.
- **Headless and PWA storefronts depend on GraphQL**, so mitigations that disable GraphQL are often unavailable — raising exposure to template/GraphQL flaws.
- **Inventory the target's own REST namespaces for agent/tool-execution surfaces.** A WordPress `mcp` adapter registers `POST/GET/DELETE` routes that invoke tools, not just read content; enumerate them separately and verify auth (a `401` is the control, an open route is critical).

## Reporting

- **The management report never exposes exploitation detail.** Business language, business impact, and a clear ask.
- **One finding, one ID, one severity, across both reports.** Divergence between artifacts destroys trust.
- **A zero-day gets an explanation and a badge.** Most readers do not know the term; define it and make it impossible to miss.
- **Every count in the summary must match the finding register.** A stale number is a credibility leak.
