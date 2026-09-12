# Techniques — Tested Recipes

Reusable, read-only-first techniques confirmed to work during real engagements. Each entry states the goal, the command, and how to read the result.

## Passive reconnaissance

- **Enumerate subdomains via Certificate Transparency.** `crt.sh` and Cert Spotter cross-check each other; either may be rate-limited or flaky.
  - `curl -s "https://crt.sh/?q=%25.<domain>&output=json"` — parse `name_value`.
  - `curl -s "https://api.certspotter.com/v1/issuances?domain=<domain>&include_subdomains=true&expand=dns_names"`
- **DNS and mail posture.** `dig +short NS/MX/TXT/AAAA/CAA <domain>` and `dig +short TXT _dmarc.<domain>`. A DMARC `p=none` permits spoofing; `p=reject` enforces.
- **TLS fingerprint.** `echo | openssl s_client -connect <host>:443 -servername <host> 2>/dev/null | openssl x509 -noout -subject -issuer -dates`.
- **HTTP fingerprint.** `curl -sS -D - -o /dev/null https://<host>/` — server, CDN, security headers, cookie flags, redirect chain, framework hints (`x-redirect-by`, `x-magento-*`, `x-powered-by`, `X-Jenkins`).

## Version discovery

- **Magento version via setup page.** `GET /setup/` often exposes `Magento Version X.Y.Z-pN`.
- **Jenkins version via header.** `X-Jenkins: <version>` on any response, including `403`.
- **GitLab version via page data.** The `gon` JSON on `/help` or the sign-in page carries `gitlab_version` `{major, minor, patch}`.
- **WordPress hardening probe.** `GET /wp-json/wp/v2/users` (401/403 = hardened), `/xmlrpc.php` (403 = hardened), `/wp-login.php` (404 = hidden).

## Attack-surface probes (read-only)

- **Exposed setup / docs / APIs.** Probe `/setup/`, `/graphql`, `/rest/V1/`, `/api/documentation`, `/docs`, `/.env`, `/.git/config`, `/app/etc/env.php`, `/*.sql`, backup paths. Record status and headers.
- **GraphQL introspection.** `POST /graphql` with `{"query":"{__schema{queryType{name}}}"}` — a JSON `data.__schema` response means introspection is enabled (aids attackers; the interim mitigation for template/GraphQL flaws is not applied).
- **Open registration (do not create an account).** `GET /users/sign_up` — a rendered form with fields is evidence of a public form; whether it yields access requires an authorized test.
- **Cookie flags.** `Set-Cookie` attributes: `Secure`, `HttpOnly`, `SameSite`. Absence of `Secure`/`HttpOnly` on a session cookie is a finding.

## Supply-chain OSINT

- Extract vendor hosts from page source (`src`/`href`), answer headers, and DNS; identify platform, payments, marketing, CDN, hosting.
- For each vendor, map platform/version and check the watchlist + vendor advisories. Third parties are OSINT-only.

## Supabase-backed single-page apps

- **Find the backend.** Grep the JS bundle for `*.supabase.co`, `createClient`, and key patterns. A `sb_publishable_…` (or legacy `eyJ…` anon) key is public by design — the risk is RLS, not the key. A `sb_secret_…` key in a bundle is a critical finding.
- **Check the auth policy.** `GET /auth/v1/settings` with the public key shows `disable_signup`, `mailer_autoconfirm`, and enabled providers.
- **Measure RLS without reading rows.** `HEAD /rest/v1/<table>?select=id&limit=1` with `Prefer: count=exact`; the `content-range` header reveals whether the public key can read. `*/0` = RLS blocks anonymous; `0-N/N` with N>0 = exposed.
- **REST schema root.** `GET /rest/v1/` may return `401 {"message":"Secret API key required"}` (new Supabase behavior) — that is hardening, not a finding.
- **Edge functions.** Live at `<project>.supabase.co/functions/v1/<name>`, not on the app domain. Probe with `OPTIONS`/`GET`; an unauthenticated `GET` returning `401` confirms auth is enforced.
- **Extract tables/RPCs from the bundle.** Grep for `` .from(`table`) ``, `.select(`, `.rpc(` — this reveals the real data model to target with the RLS check.
- **Find storage buckets and test them unauthenticated.** Grep for `.storage.from(` to get bucket names, then `POST /storage/v1/object/list/<bucket>` and the `/storage/v1/object/public/<bucket>/<file>` URL with no auth — a public bucket lists and downloads.
- **Test tenant isolation via a writable tenant column.** If `profiles.organization_id` (or similar) is user-writable, read the target tenant id from a readable table (`projects.organization_id`), PATCH it onto your own row, and re-count the scoped table (`demands`). Revert afterward.

## Next.js applications

- **Map the auth model.** A `307`/`302` to `/login` on every route means middleware auth. NextAuth exposes `/api/auth/providers`, `/api/auth/csrf`, `/api/auth/session` publicly — `/api/auth/signin/<provider>` returning `?error=Configuration` means the provider is misconfigured (no client id/secret).
- **Test the middleware bypass (CVE-2025-29927).** Add `x-middleware-subrequest` header (`middleware`, `middleware:middleware:middleware:middleware:middleware`, `pages/middleware`, `src/middleware`) to a protected route; a `200` instead of the redirect is a bypass. A repeated `307` means it is not applicable.
- **Server Actions.** Grep the bundle for `createServerReference("<id>",…,"<name>Action")` to get action IDs. Actions are invoked with `POST <page>` + `Next-Action: <id>`; a foreign `Origin` should be rejected — verify CSRF handling.

## Rules of engagement for every technique

- `GET`/`HEAD` only unless an authorized active test says otherwise. No credentials, no bodies, no mutations.
- One request per probe; never mass-scan. Rate-limit any active test and respect the agreed window.
- Cross-check a version with a second source before attributing a CVE.
