---
shortDescription: Universal coding conventions for all languages and every agent.
scope: coding
version: 0.7.0
lastUpdated: 2026-09-12
---

## Statement

### KISS

When choosing between a clever solution and a simple one, you MUST choose simple. The simplest solution that fully solves the problem is correct — not "good enough." Complexity is a liability, not a feature. If a solution requires the reader to understand a design pattern, an algorithm, or a non-obvious language feature, a simpler alternative exists and should be preferred.

### DRY

Each piece of knowledge or behavior MUST have a single, unambiguous representation. When two code paths do the same thing, they share a function, a variable, or a constant — even if they differ by one line. If a change to one block requires an identical change to another, the duplication is a bug waiting to happen.

### Single Responsibility Principle

One responsibility means one acceptance criterion — one reason the code changes — not one operation. Validating and transforming raw input into a value object is one criterion (the input contract); it MUST stay together at any length. Querying and rendering, arranging and reporting change for independent reasons; they are two responsibilities and MUST split. When in doubt, ask: would these two operations change independently? If yes, split. If no, keep together.

Splitting is not free — every split scatters context the reader must reassemble at the call site. Extract only when the extraction names a distinct criterion.

The function name is the first signal. A conjunction (`recordAndStartContainer`) forces the question: would the two verbs change independently? If yes, the function MUST be split and the caller sequences the parts — call-site convenience never justifies a compound name. If no, the work MUST stay together under one verb that names the whole criterion (`loadConfig`, not `parseAndValidateConfig`). A condition (`deleteContainerDbRecordsIfCreated`) is a decision for the caller — the condition MUST move to the call site, or disappear when the operation is safe to repeat. A recognized idiom (`upsert`) is one action. After the split, rename until each name reads as one concrete action.

### Method Granularity

Size is a thermometer, not a verdict. A function under roughly ten lines is likely a wrapper — inline it unless it holds a translation the caller should not know. Past one hundred lines, hunt for a split — and take only the seams where a distinct criterion exists. A long function serving one criterion is correct, and the range in between needs no defense. Functions MUST do meaningful work: extract when the logic is reused, complex, or conceptually distinct — never to satisfy a reflexive "small functions are good" instinct. A thin wrapper is not abstraction; it is noise.

### Control Flow

Guard clauses first: handle failure conditions early and return, so the happy path stays unindented and visible.

When a function accumulates multiple `if` blocks branching on the same variable or condition, you SHOULD evaluate whether a `switch`/`case` (or language-equivalent strategy dispatch) would express the intent more clearly.

### Variable and Function Naming

Variable names MUST convey intention or purpose, not describe content.

Function names MUST NOT embed infrastructure or tool names (e.g., `resolveOpencodeConfigPath`). Use generic terms that describe the role (`resolveSupportedCliConfigPath`). The function should survive a tool swap without needing a rename.

Variable names SHOULD reflect the primary flow, not conditional outcomes.

Single-letter variable names MUST NOT be used — no `i`, `j`, `n`, `e`. Every variable MUST have a descriptive name. Language-specific exceptions belong in the relevant skill.

Single-word variable names are rarely correct. Use a compound name unless the single word is already fully specific and admits no meaningful prefix or suffix — e.g., `timestamp`, `hostname`. If adding a word clarifies kind, scope, or lifecycle, do it — `resolvedPaths`, `loadoutEntries`, `collectionName`.

Operation results MUST be stored in named variables that describe WHAT was produced, not HOW. The result of `%` is opaque — but `numberWithinRange` tells the reader exactly what they got.

### Boolean and Constant Naming

Boolean variables SHOULD start with `Is`, `Has`, `Should`, `Can`, or similar prefixes.

Variable names MUST signal the type when ambiguous. If the reader would need to check documentation to know whether a value is a decimal or integer, the name failed (e.g. `rawRandomInteger`, not `rawRandomNumber`).

### Method Naming

Function names describe WHAT the function is responsible for, not HOW it achieves the result. `emitYqUnionQuery` names a mechanism and leaves the reader guessing; `approvePayout` states the responsibility. A name that could label any function in the codebase — `finalizeCertainAction`, `processData` — names nothing. When a recognized role fits the work, the role name works as the suffix (`userFactory`, `loadoutPathsResolver`).

When engineering already names the concept — `rollback`, `retry`, `drain`, `reconcile` — use that term; it imports the contract no coined phrase carries.

### Method Ordering

Functions MUST be ordered top-down: if function A calls function B, then function B MUST be defined directly above function A — adjacent to its first caller, not merely somewhere earlier in the file. The reader should be able to read the file from top to bottom, encountering each function at the point of need, without scrolling past unrelated helpers to find a definition. When several functions share a helper, the helper sits above the first caller. The most composed entry point — the file's orchestrator — comes last.

Exception: constructors and factory functions (e.g., `NewFoo`, `CreateBar`) MUST be placed immediately after the struct/class/type declaration they construct, not at the bottom of the file. The type and its constructor form a single conceptual unit. Test teardown and cleanup helpers sit at the end of the test file, after the tests they clean up.

This applies within a file — cross-file ordering is out of scope.

### Parameter Naming

Parameter names MUST make sense without reading caller code. If a reader must check call sites to understand a parameter, the name failed. No CS jargon (`exclusiveMaximum`, `upperBound`). Use plain language that describes the role (`rangeSize`).

### Visible Assignment

When an API mutates in place, you MUST restructure for visible assignment. If there is no `=` sign, the reader cannot see where the value comes from. Capture return values explicitly.

Beyond in-place mutation, an inline condition that requires external knowledge to interpret — an errno, a stdlib sentinel, a counter convention — MUST be assigned to a named boolean at the point of comparison. The name states the business meaning (`moveCrossesDevices`, not `isExdev`); the comparison states the mechanism. The same applies to any opaque expression, not only conditions: a syscall errno, a stdlib counter, a format detail earns a named variable before it is used, so the name carries the concept the operator hides.

A name that only restates the expression is noise: it MUST say what the expression means. Naming an already-self-evident expression (`isEmpty := len(s) == 0`) adds a line and no meaning — this rule is not license to name every `if`; the name must carry knowledge the expression lacks.

### Logging

Log messages SHOULD use PascalCase without spaces whenever possible (e.g. `UserCreated`, `PaymentFailed`, `TokenExpired`). This makes logs greppable and removes ambiguity around word boundaries.

### Data Trust Boundary

Data from outside the code — user input, database results, API responses, environment variables, file contents — MUST be treated as untrusted regardless of origin. A database row is no safer than a query parameter; both can carry injection payloads, malformed values, or stale state.

External data MUST be converted into a value object (or language-equivalent typed representation) before use in business logic. The value object's constructor or factory is the single validation point — if the data passes construction, it is safe to use downstream. Raw external data MUST NOT flow directly into queries, templates, commands, or domain operations.

Do not create separate parse or convert functions when the value object's constructor already validates and transforms the input. A standalone `parseFoo(raw)` function alongside a `Foo` struct with a validating constructor is duplication — the constructor is the parse function. If the transformation is complex enough to warrant its own function, make it a method on the value object or an unexported helper called by the constructor, not a parallel public function.

### Error Handling

An error is either propagated or logged — an error that passes without a log entry is a silent failure. The tolerability decision belongs to the caller: a helper wraps the error with context and returns it, and MUST NOT log-and-continue on its own, because whether the failure is tolerable is context the helper does not have. The caller that drops an error logs it once, at the severity its context warrants, and carries on.

### Process-killing exceptions

Language constructs that terminate the process (`panic`, `os.Exit`, unhandled `throw`, `process.exit`, etc.) MUST NOT be used during runtime. They are acceptable only during application startup or initialization — if a required dependency is missing, a config is invalid, or a precondition for running is unmet. Once the application is serving, every failure MUST be handled gracefully through the language's error propagation mechanism.

### Hardcoding

Content that originates from a backend, API, or config MUST NOT be hardcoded in source.

### Schema Changes

Database schema modifications MUST be explicitly stated in any handoff or commit summary.

### Native Tooling

You MUST use native file operation tools (Edit, Read, Write, Grep, Glob) directly. Writing scripts (Python, Bash, etc.) to perform file reads, edits, searches, or any file system operation is forbidden. Scripts require user authorization and review, creating unnecessary friction. The native tools are purpose-built for these operations and execute without approval overhead. When shell is unavoidable, read and follow `rules/code/shell.md`.

### Readability Over Performance

When choosing between a faster but cryptic implementation and a slower but readable one, you MUST choose readability. Clever patterns — `Array.from` with callbacks, Fisher-Yates shuffles, bitwise hacks, dense one-liners, or any construct that requires prior knowledge to understand — are forbidden. Use plain loops and simple logic. Every line MUST read as plain English to a human who has never seen the codebase. Performance optimization is allowed only when a measured bottleneck demands it.

### Dependency Audit on Feature Change

When adding a feature or mechanism that changes the behavior of an existing dependency (config file, registry, shared data structure), you MUST audit the affected dependency for: (1) shared entries that belong in a shared layer, (2) entries the new mechanism makes redundant, and (3) logic the new mechanism fully replaces. The feature is not complete until duplicates are removed.

### Comments

A comment is a confession, not a tool: it admits the code failed to explain itself. The default is no comment. When code is unclear, restructure first — name the concept, extract the translation, absorb the contract into a type — and reach for a comment only when the code cannot be made readable.

An external constraint (a stdlib contract, a format detail, an upstream bug) is the prompt to absorb the constraint into a structure, not permission to stop at prose. A comment that a domain rule or a tool contract mandates is structure, not confession, and stays: a shell `@tag` header and three-line section headers (`rules/code/shell.md`), a marker syntax a template engine requires, a justification a suppression marker needs.

A surviving comment explains why, never what. If deleting it loses no constraint, it was narrating. Commented-out code and `TODO`/`FIXME` markers SHOULD NOT be committed — version control holds the history, the issue tracker holds unfinished work.

### Technical Writing

Any surviving comment, plus plans, documentation, and CHANGELOG entries, MUST use STE-100 (Simplified Technical English). Write short sentences. Keep one idea per sentence. Use active voice.

### Testing

Complex logic MUST have unit tests.

Test error messages MUST be descriptive and provide context.

Secrets, certificates, and private keys MUST NOT be hardcoded in tests.

Tests SHOULD use table-driven test cases.

Test data SHOULD use factories or builders, not hardcoded literals. Hardcoded test data obscures which values matter for the assertion and which are incidental.

Infrastructure tests MUST hit real external APIs (databases, queues, third-party services). Mocking at the infrastructure boundary hides integration failures — the test passes but the system breaks.

Test files MUST be independent across files — each test file guarantees its own preconditions. Shared test utilities are acceptable only when they have zero imports from the application's domain packages (e.g., database setup, test server helpers are fine; entity factories that pull in domain code are not).

Sibling tests within a file MAY depend on execution order — the first test's outcome feeding the second test's setup is acceptable when it reflects a natural workflow progression.

Each test file MUST handle its own setup and teardown inline. Setup helpers that create state must also restore it — a test that leaves state behind poisons the next test's assumptions. When setup fails, use early returns to prevent cascading failures — a skipped test with a clear message is better than a cascade of misleading failures.

Test setup helpers MUST NOT be package-level functions. They belong inside the test function (as a closure or local function), prefixed with the test name to signal ownership, or encapsulated in a struct. When helpers are extracted to the file level, setup helpers go above the test (callees above callers) and teardown/cleanup goes at the end of the file.

Tests MUST verify behavior (input → output), not implementation details. A test that breaks when internals are refactored without changing behavior is a maintenance burden, not a safety net.

## Rationale

These conventions produce code that reads linearly, names that communicate intent, and tests that explain failures. They reduce cognitive load during review and make codebases navigable by both humans and agents who arrive without prior context.
