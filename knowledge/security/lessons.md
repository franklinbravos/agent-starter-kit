# Lessons — Mistakes and Rules Learned

Each lesson is a mistake that cost something or a rule that changed how we work. Add one entry per engagement review.

## Authorization and scope

- **A pasted URL is intent, not authorization.** Before any active test, obtain written scope: who authorized it, the assets, the window, and the prohibited actions. Without it, the engagement is passive OSINT only.
- **A client's vendor is a third party.** Testing a vendor without separate authorization is out of scope, even when the client owns the data. Vendors are OSINT-only.
- **Report the scope you actually had, not the scope that sounds impressive.** State what was excluded and what remains unconfirmed.
- **Ownership is per-domain and per-TLD, not per-brand.** A client owned the `.com` domain, while an unrelated `.com.br` domain of the same brand belonged to a different company. Verify each domain separately through WHOIS; never infer ownership from a matching brand, a sibling domain, or a certificate organization alone. An attributed domain is probed; an unattributed one is OSINT-only.

## Evidence and accuracy

- **Verify the affected range before attributing a CVE.** A version can be the one that *introduced the fix*. Example: GitLab 16.8.1 is the patch for CVE-2024-0402, not a vulnerable version — reporting it as a flaw would have been a false positive.
- **The newest patch level is not proof of safety.** Magento 2.4.7-p10 was current and still exposed to CVE-2026-75650 until an out-of-band hotfix. Distro backports further break the version→CVE mapping.
- **Separate confirmed from inferred.** A route that "looks guarded" is inferred until a test confirms it. Label it and name the test that would confirm it.
- **Let evidence downgrade a finding.** A public signup form looked like an open door; the manual test showed accounts require administrator approval. The finding moved from crítico to médio — the report became truer.
- **A `200` from an SPA is not a file.** An SPA/Vercel catch-all returns `index.html` (200) for `/.env`, `/graphql`, `/api/health`, and `*.js.map`. Check `content-type` and byte size before calling it an exposure — a ~900-byte `text/html` response for `/.env` is the app shell, not a leak.
- **`dig +short A` prints the CNAME target when the final A record is missing.** A resolver answering with a hostname in the A lookup is not a resolution — it is a dangling CNAME. Build the "active host" test on a real IP (`first_ip()`), never on a non-empty answer string; otherwise every dangling CNAME looks alive.
- **DNS answers can be inconsistent mid-propagation.** Two queries minutes apart returned a cached CNAME for a host whose authoritative servers no longer served it. Query the authoritative nameservers *and* two public resolvers, keep both snapshots, and record the discrepancy honestly instead of picking one.
- **Anonymous object-storage listing is medium, not automatic critical.** A CDN bucket exists to be read; the misconfiguration is the *listing*, which exposes the whole inventory and any `int-`/`dev` namespace. Read one page of the XML, confirm no secret/PII, and rate on that evidence — public marketing assets are medium; any credential or personal data makes it high.
- **An unprotected framing directive and a dead one look the same in a header dump.** `X-Frame-Options: ALLOW-FROM <uri>` is ignored by modern browsers, and `frame-ancestors;` with no value is an invalid directive that is also ignored. Both are findings; neither is a control. Read the directive's value, not its presence.
- **A wildcard certificate under a third party's domain is a dependency to name.** When the apex and `www` serve `CN=*.agency-domain` with a SAN of `*.target.tld`, the target's wildcard is issued inside the agency's certificate account. Report it as an ownership/redundancy observation, not as a vulnerability — but do not omit it.
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
- **Email possession is not authorization.** Supabase password recovery to a **public/disposable inbox** completes the identity loop. A public signup or a public inbox turns "verified e-mail" into a self-service credential — the gate must be the role/provisioning, not address reachability.
- **A private bucket can still leak through a writable-tenant hop.** Storage RLS keyed to `profile.organization_id` is only as strong as that column's immutability. Test the app's real bucket and path, then hop; an object that is "not found" at `organization_id:null` becomes downloadable under another tenant.
- **A `SECURITY DEFINER` RPC that fails on a foreign key has already passed authorization.** The `23503` proves the function reached the INSERT/UPDATE. Do not mistake the constraint failure for a control — test with a non-existent UUID and read the error, never with a real record.
- **Revalidate a prior "blocked" claim against the exact object before repeating it.** "Attachment download is blocked" was true for the `attachments` bucket and false for a second, differently-scoped bucket; naming the wrong object would have buried a real finding.
- **An exposed origin is not automatically "alto".** A leaked backend reachable directly (CDN/WAF bypass + plaintext HTTP + internal hostname disclosure) only rates high when it serves non-public surface. Confirm read-only what the origin actually answers (`/api`, `/admin`, auth paths) before rating; if those `404` on the origin, the impact is public content and the finding is `médio`. Same discipline as the GitLab fix-version false positive — evidence sets the severity, not the adrenaline.

- **CT/DNS brute-force only see the live surface; the Wayback CDX sees what was removed.** A domain's most sensitive historical exposure (a legacy HR portal, a decommissioned admin) often has no current DNS record and no individual cert, so `crt.sh` and brute-force miss it. The CDX `matchType=domain` call surfaced a legacy recruiting subdomain and a decommissioned portal that were NXDOMAIN — those were the real finds of the phase, not any live host.
- **A `.js.map` with no secrets is still a finding.** The exposure is the source itself (structure, controller names, internal naming). Grep the `sourcesContent` for keys/buckets/hostnames to set severity, but report the map exposure regardless.
- **Client-side keys are not database keys — classify before escalating.** A Google Maps `AIza…`, a reCAPTCHA site key, and a New Relic browser `licenseKey` are all `public-by-design` (embedded in client code) and none grants access to a database or to the client's data. Report them for the *billing/quota-abuse* angle (unrestricted `referer`) only, and name the third-party-console test that would confirm the restriction — never call them a "leaked database key".

- **Decode a hardcoded token before calling it a leaked secret.** A literal JWT in a production front-end bundle is a credential-management smell, not automatically a high. Read the `iss`, the claims, and the `exp`: a token from a vendor *sandbox* issuer, naming an example merchant, and already expired has zero live impact — rate it low/info and flag the pattern, not the token.
- **A public-by-design key is only a finding alongside an open data surface.** A Firebase web API key, a reCAPTCHA site key, a OneSignal app id, and an Azure tenant/client id all ship to every browser. Report them as inventory; escalate only when the key reaches a database or function that returns data the caller should not see (e.g. open Firestore rules).
- **The development `environment` object can ship inside a production bundle.** Angular ships `environment.ts` at build time; an `apiUrl` of `http://localhost:8080/api` or an MSAL `redirectUri` of `http://localhost:4200` in a production artifact is a misconfiguration — verify the redirect URI is not registered on the production identity provider.
- **A single HTTP method does not characterize a route.** A `GET`/`HEAD` that returns `401` proves the *read* path needs auth; it says nothing about whether `POST` (sign-up) is public. Do not upgrade or dismiss a registration finding from one method — label the untested method inferred and name the test.

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
