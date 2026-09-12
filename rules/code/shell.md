---
shortDescription: Shell script conventions for readability, safety, and determinism.
scope: coding
version: 0.1.0
lastUpdated: 2026-09-12
---

## Statement

These conventions govern scripts committed to the project. A throwaway session script under `/tmp` is exempt: keep it minimal and reviewable, without the header or companion test file.

### Header

Scripts MUST include a structured header using `@tag` annotations. Required tags:

```bash
# @description  What the script does (one line).
# @usage        command <required> [optional]
# @output       What stdout produces.
# @requires     External dependencies (e.g., bash v4+, yq v4+).
# @version      Semantic version.
# @updated      Last modification date.
```

Optional tags: `@author`, `@license`, `@see`.

### Strictness

Scripts MUST start with `set -euo pipefail`.

### Naming

Variables MUST use camelCase. UPPER_SNAKE_CASE is reserved for environment variables and public output keys.

Function names MUST be fully self-descriptive. Shell functions are freestanding — no class or module provides context. A function named `validate` or `check` without specifying WHAT it validates or checks forces the reader to inspect the body or trace call sites. The name alone must communicate the function's purpose without relying on section headers, filenames, or surrounding code for disambiguation.

Functions that incrementally construct a data structure (start empty, loop, accumulate) MUST end with the word `Builder` — e.g., `personaAgentJsonBuilder`. This signals the mutation pattern so readers don't mistake a constructor for a passive reader.

### Structure

Logical sections MUST be functions grouped under three-line headers, not comment-separated blocks:

```bash
#
## SectionName
#
```

Scripts MUST NOT define a `main()` function. The entry point is a `## Runtime` section at the bottom of the script. The calls sit directly on the script body, not in a function. They SHOULD read as a sequence of calls. Scripts that may be sourced MUST guard the runtime with a source check (`if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then return 0; fi`). The check lets callers use the functions without running the runtime on import.

Functions MUST follow the Single Responsibility Principle — one reason to change. Two operations that serve the same purpose (e.g., checking two files to answer "does context exist?") are one responsibility and MUST stay in one function. A function that performs setup AND reporting, or cleanup AND collection, has two responsibilities and MUST be split. When in doubt, ask: "if the requirements change, would these two operations change independently?" If yes, split. If no, keep together.

Function definitions MUST be ordered top-down: every function MUST appear above its first caller in the file. Bash tolerates forward references but readers MUST NOT scroll down to find a definition. Helpers come first, the function that consumes them next, and the `## Runtime` section sits at the bottom as the final consumer.

Multi-line or long string output MUST use heredocs (`cat <<'EOF'` or `cat <<EOF`), not `printf` with escaped newlines or long `echo` commands. The output structure must be readable at a glance without mentally unescaping `\n` sequences.

Two or more sequential `echo`/`printf` statements producing related output MUST be combined into a single heredoc. Block structure must be visible in one place.

Reserve `printf` and `echo` for single-line formatted output (e.g., `printf '%d. %s\n' "$i" "$value"` inside a loop).

### Pipelines

Pipelines MUST NOT exceed 3 stages (2 pipe characters). If data needs more than 2 pipes, store intermediate results in local variables and chain them explicitly. This makes each step inspectable and prevents silent failures in long chains.

When a loop body produces output that needs aggregation (deduplication, sorting, joining), attach the aggregation pipeline to the `done` keyword — do not accumulate in a variable. Loop body commands write to stdout; the pipeline at `done` captures the complete output. Manual accumulators add invisible state, require non-empty guards, and obscure the data flow. Note: this pattern only applies when the loop body does not need to set variables for use after the loop. If post-loop state is required, accumulate in a file or temp variable instead.

### Output Validation

Captured output MUST be validated before piping it to a downstream consumer. An empty or malformed result from a failed command silently corrupts data further down the chain. Check that variables hold the expected shape (non-empty, valid JSON/YAML, expected sentinel value) before passing them to `jq`, `yq`, or file writers.

### Parser Discipline

Use ONE parser per data extraction. Do NOT layer `yq | jq` on the same field — `yq` natively handles YAML scalars, arrays, and fallback (`//` operator). If `jq` is needed, it should operate on JSON data produced by a different operation, not re-parse what `yq` just extracted.

### Side Effects

Functions MUST return values via stdout (`echo`), not by writing to variables defined outside the function. Callers capture output with `result=$(fn arg1 arg2)`. For multi-value returns, use `read -r var1 var2 <<< "$(fn)"`. Guard functions (validation with early exit) are the exception — they may exit but MUST NOT write globals.

Functions that conditionally return a value (echo on one branch, nothing on the other) produce empty output when the guard does not fire. The caller MUST check the captured output against the expected sentinel value — never assume the function produced data. Empty output is silent and indistinguishable from success without an explicit check.

### Determinism

Scripts MUST NOT hardcode values that exist in config files. If a value is defined in a YAML or config, read it from there. One source of truth.

### Testing

Every script MUST have a companion `_test.sh` file. The test file sits next to the script and shares its name with a `_test` suffix (e.g., `cmk-instances.sh` → `cmk-instances_test.sh`).

Tests MUST verify behavior, not implementation. Each test calls the function with known input and checks the output. Tests MUST NOT inspect internal state or depend on private helpers.

Test files MUST source the script under test and call its functions directly. Tests MUST NOT run the script as a subprocess to check its runtime section. The source guard in the script prevents the runtime from executing on import.

Each test file MUST own its setup and teardown inline. A test that leaves state behind poisons the next test.

## Rationale

Shell scripts in this framework are read by both humans and AI agents. Readable pipelines, strict error handling, and data-driven design prevent silent failures and make scripts maintainable without deep bash expertise.
