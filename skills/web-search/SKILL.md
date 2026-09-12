---
name: web-search
description: Web search and page fetch through the TinyFish CLI.
usedBy: [all]
relatedTo: [tinyfish]
version: 0.1.0
lastUpdated: 2026-09-12
---

## Purpose

Answers about current facts, public tools, and external systems need web grounding. Search finds pages. Fetch reads them. Search runs through the TinyFish CLI. Page fetch tries the host's native web fetch tool first and falls back to the TinyFish CLI when the native tool is blocked. This skill defines when to use each surface, the exact commands, and how to read the output. Full flag reference: https://docs.tinyfish.ai/cli/commands

## Procedure

### Verify the tool is installed

1. **Check for the CLI.** Run `command -v tinyfish`. If it is missing, stop and tell the user:
   - The TinyFish CLI is required for web search and fetch.
   - Install it by following https://docs.tinyfish.ai/cli/commands.
   - It is free, but it requires an API key — the user creates one and completes login with `tinyfish auth login` themselves.
   Do not install the tool or run `tinyfish auth login` on your own. Once the user confirms setup, continue.

2. **Check authentication.** Run `tinyfish auth status`. If it reports no valid key, tell the user to run `tinyfish auth login` themselves and stop. Do not run `tinyfish auth login` or `tinyfish auth set` on your own.

### Choose the surface

3. **Answer from local context first.** Use project files and the conversation when they hold the answer. Skip the web when the question is about this codebase.
4. **Search when the right page is unknown.** Use search for "what is", "how does", and "compare" questions, and for anything time-sensitive: versions, releases, prices, news.
5. **Fetch when the page is known.** Try the host's native web fetch tool first. Fall back to `tinyfish fetch content get` when the native tool is blocked, fails, or returns empty content.

### Search

6. **Run the search:**

   ```bash
   tinyfish search query "best React state management libraries"
   ```

   Add hints when the question is geo- or language-specific:

   ```bash
   tinyfish search query "best pho in Saigon" --location "Vietnam" --language "en"
   ```

7. **Read the results.** The default output is JSON. Each result carries `position`, `site_name`, `title`, `url`, and `snippet`. A snippet often answers a simple question. Fetch only the pages that need full content.

### Fetch

8. **Fetch with the TinyFish CLI.** Use this when the native web fetch tool is blocked or fails:

   ```bash
   tinyfish fetch content get "https://example.com/article"
   ```

   One call accepts up to 10 URLs. The server fetches them in parallel.

9. **Read the content.** Each entry in `results` carries `title`, `final_url`, `author`, `published_date`, and `text`. The `text` field holds clean markdown. Ads and navigation are stripped. Check `errors` for failed URLs. The other results still succeed.

10. **Adjust the extraction when needed.** Pass `--links` or `--image-links` to also collect outbound links or images. Set `--per-url-timeout-ms 45000` for slow sites. Use `--format html` or `--format json` when markdown loses structure you need.

### Ground the answer

11. **Cite the sources.** Name the URL behind every external fact. Never state a fact the fetched content does not support.

## Guardrails

- Never use `tinyfish agent run` for plain reading. It drives a real browser and bills per step. Search and fetch cover reading tasks for free.
- Never guess or invent URLs. Search first when the address is unknown.
- Never fetch more pages than the answer needs. Every page adds context cost.
- If a command fails with an auth error, run `tinyfish auth status` and report the result. Do not run `tinyfish auth login` or `tinyfish auth set` on your own.
