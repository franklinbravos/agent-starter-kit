# Sources — Advisory Feeds

Monitor these at the start of every engagement, and whenever the target's stack is known. Prefer the vendor advisory or NVD over secondary articles.

## Databases and aggregators

| Source | URL | Use |
|---|---|---|
| NVD | https://nvd.nist.gov | CVE metadata, CVSS, affected ranges |
| CISA KEV | https://www.cisa.gov/known-exploited-vulnerabilities-catalog | Confirmed in-the-wild exploitation |
| GitHub Advisory | https://github.com/advisories | Open-source dependency advisories |
| Exploit-DB | https://www.exploit-db.com | Public exploits and PoC availability |
| CERT.br | https://www.cert.br | Brazilian CERT advisories (pt-BR) |

## Vendor advisories

| Vendor / product | URL |
|---|---|
| Adobe Commerce / Magento | https://helpx.adobe.com/security/products/magento.html |
| GitLab | https://about.gitlab.com/releases/categories/releases/ |
| Jenkins | https://www.jenkins.io/security/advisories/ |
| Atlassian | https://confluence.atlassian.com/security-advisories |
| WordPress core / plugins | https://wpscan.com , https://wordpress.org/news/category/security/ |
| Microsoft | https://msrc.microsoft.com/update-guide |
| Apache | https://httpd.apache.org/security/ |

## Specialized

| Source | URL | Use |
|---|---|---|
| Sansec | https://sansec.io/research | E-commerce / Magento threat research |
| Shadowserver | https://www.shadowserver.org | Exposed-service reporting |
| Have I Been Pwned | https://haveibeenpwned.com | Breach history for a domain/vendor |

## Feeds

- CISA KEV JSON: `https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json`
- GitHub Advisory GraphQL/REST: `https://api.github.com/advisories`
- NVD API 2.0: `https://services.nvd.nist.gov/rest/json/cves/2.0`

## Cadence

- **Every engagement start:** check KEV for entries published since the last engagement date in `watchlist.md`.
- **When a stack is fingerprinted:** query the vendor advisory index and NVD for that product and version.
- **Weekly (if active):** scan KEV and Sansec for platforms in `watchlist.md`.
