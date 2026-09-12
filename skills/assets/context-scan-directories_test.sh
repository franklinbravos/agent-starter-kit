#!/usr/bin/env bash
#
# @description  Table-driven tests for context-scan-directories.sh.
# @usage        context-scan-directories_test.sh
# @output       PASS/FAIL per test case, summary at end.
# @requires     bash v4+
# @version      0.0.5
# @updated      2026-04-04
set -euo pipefail

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scanScript="$scriptDir/context-scan-directories.sh"

passCount=0
failCount=0

assertScan() {
  local label="$1"
  local testDir="$2"
  local scanArgs="$3"
  local expectedOutput="$4"
  local expectedExit="$5"

  local actualOutput actualExit
  actualExit=0
  actualOutput=$(cd "$testDir" && bash "$scanScript" $scanArgs 2>&1) || actualExit=$?

  if [[ "$actualExit" != "$expectedExit" ]]; then
    cat <<EOF
FAIL $label
  expected exit=$expectedExit, got exit=$actualExit
  output: $actualOutput
EOF
    failCount=$((failCount + 1))
    return
  fi

  if [[ "$actualOutput" != "$expectedOutput" ]]; then
    echo "FAIL $label"
    diff <(echo "$expectedOutput") \
      <(echo "$actualOutput") | sed 's/^/  /'
    failCount=$((failCount + 1))
    return
  fi

  echo "PASS $label"
  passCount=$((passCount + 1))
}

# ── Test 1: Default root with src/ present ────────────────────────────
testDir=$(mktemp -d)
mkdir -p "$testDir/src/api" "$testDir/src/lib"
assertScan \
  "default root prefers src/ when present" \
  "$testDir" \
  "" \
  "$(printf 'src\nsrc/api\nsrc/lib')" \
  "0"
rm -rf "$testDir"

# ── Test 2: Default root without src/ ────────────────────────────────
testDir=$(mktemp -d)
mkdir -p "$testDir/cmd" "$testDir/pkg"
assertScan \
  "default root falls back to . when src/ absent" \
  "$testDir" \
  "" \
  "$(printf '.\n./cmd\n./pkg')" \
  "0"
rm -rf "$testDir"

# ── Test 3: Explicit root argument ────────────────────────────────────
testDir=$(mktemp -d)
mkdir -p "$testDir/src/handlers" "$testDir/src/models" "$testDir/other"
assertScan \
  "explicit root argument scans only that subtree" \
  "$testDir" \
  "src" \
  "$(printf 'src\nsrc/handlers\nsrc/models')" \
  "0"
rm -rf "$testDir"

# ── Tests 4-7: Skips known noise directories ──────────────────────────
skipTargets=(".hidden" "node_modules" "vendor" "__pycache__")
for skipTarget in "${skipTargets[@]}"; do
  testDir=$(mktemp -d)
  mkdir -p "$testDir/src/app" "$testDir/src/$skipTarget"
  assertScan \
    "skips $skipTarget" \
    "$testDir" \
    "" \
    "$(printf 'src\nsrc/app')" \
    "0"
  rm -rf "$testDir"
done

# ── Test 8: Non-existent root fails ───────────────────────────────────
testDir=$(mktemp -d)
assertScan \
  "non-existent root exits with error" \
  "$testDir" \
  "does-not-exist" \
  "DirectoryNotFound: 'does-not-exist'" \
  "1"
rm -rf "$testDir"

# ── Test 9: Directory with no .context.md appears in output ──────────
testDir=$(mktemp -d)
mkdir -p "$testDir/src/api"
touch "$testDir/src/api/handler.go"
assertScan \
  "directory without .context.md appears in output" \
  "$testDir" \
  "" \
  "$(printf 'src\nsrc/api')" \
  "0"
rm -rf "$testDir"

# ── Test 10: Directory with up-to-date .context.md excluded ──────────
testDir=$(mktemp -d)
mkdir -p "$testDir/src/api"
touch "$testDir/src/api/handler.go"
sleep 1
touch "$testDir/src/api/.context.md"
touch "$testDir/src/.context.md"
assertScan \
  "directory with up-to-date .context.md excluded from output" \
  "$testDir" \
  "" \
  "" \
  "0"
rm -rf "$testDir"

# ── Test 11: Directory with stale .context.md appears in output ───────
testDir=$(mktemp -d)
mkdir -p "$testDir/src/api"
touch "$testDir/src/api/.context.md"
sleep 1
touch "$testDir/src/api/handler.go"
touch "$testDir/src/.context.md"
assertScan \
  "directory with stale .context.md appears in output" \
  "$testDir" \
  "" \
  "$(printf 'src/api')" \
  "0"
rm -rf "$testDir"

cat <<EOF

Results: $passCount passed, $failCount failed
EOF
[[ $failCount -eq 0 ]]
