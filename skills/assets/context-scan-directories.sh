#!/usr/bin/env bash
#
# @description  Lists project directories that need a .context.md created or
#               updated, skipping hidden, vendored, and generated directories.
# @usage        context-scan-directories.sh [root]
# @output       One directory path per line, sorted. Only directories missing
#               a .context.md or whose .context.md is older than any immediate
#               file in that directory.
# @requires     bash v4+
# @version      0.0.5
# @updated      2026-04-04
set -euo pipefail

resolveRoot() {
  local scanRoot="${1:-}"
  if [[ -z "$scanRoot" ]]; then
    scanRoot="."
    if [[ -d "src" ]]; then
      scanRoot="src"
    fi
  fi

  if [[ ! -d "$scanRoot" ]]; then
    echo "DirectoryNotFound: '$scanRoot'" >&2
    exit 1
  fi

  echo "$scanRoot"
}

isDirectoryStale() {
  local dir="$1"
  local contextFile="$dir/.context.md"

  if [[ ! -f "$contextFile" ]]; then
    echo "true"
    return
  fi

  local newerFiles
  newerFiles=$(find "$dir" -maxdepth 1 -newer "$contextFile" 2>/dev/null)
  if [[ -n "$newerFiles" ]]; then
    echo "true"
    return
  fi

  echo "false"
}

scanDirectories() {
  local scanRoot="$1"
  local allDirs
  allDirs=$(find "$scanRoot" -type d \( -path "$scanRoot/.*" -o -name node_modules -o -name vendor -o -name __pycache__ \) -prune -o -type d -print | sort)

  local dir
  while IFS= read -r dir; do
    local stale
    stale=$(isDirectoryStale "$dir")
    if [[ "$stale" == "true" ]]; then
      echo "$dir"
    fi
  done <<< "$allDirs"
}

scanRoot=$(resolveRoot "${1:-}")
scanDirectories "$scanRoot"
