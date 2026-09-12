# Security Knowledge Base

Durable, engagement-independent security intelligence. This is how the SecOps agents get smarter over time instead of restarting from zero every session.

## Files

- **`sources.md`** — the advisory feeds and databases to monitor.
- **`watchlist.md`** — CVEs and platform flaws being tracked, with affected ranges and status.
- **`techniques.md`** — tested recipes for reconnaissance, fingerprinting, and validation.
- **`lessons.md`** — mistakes made and rules learned, so they are not repeated.

## Rules

- Never store client secrets, tokens, credentials, or personal data here. This file is versioned with the agent.
- Record only what was verified. Rumor, unconfirmed claims, and vendor silence are marked as such.
- This base is read at the start of every engagement and written at the end of every engagement (`skills/security-knowledge.md`).
