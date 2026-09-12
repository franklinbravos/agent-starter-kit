#!/usr/bin/env bash
#
# @description  Detects CLI config files and writes persona agent bindings.
#               Each persona gets a named agent with its model read
#               directly from frontmatter. Thinking budget is set
#               per-agent based on persona humor style.
#
# Multi-CLI agent configuration. Currently OpenCode only — add new CLIs
# by adding a resolve<Name>ConfigPath function and updating resolveSupportedCliConfigPath.
#
# @usage        maestro-boot-configure-cli.sh
# @output       Summary line with agent count and configStatus, or nothing if no CLI config found.
# @requires     bash v4+, yq v4+, jq v1.6+, ps
# @version      0.7.0
# @updated      2026-09-12
#
# ── Thinking/Reasoning Configuration ─────────────────────────────────────────
#
# Agent bindings emit BOTH Anthropic and OpenAI thinking formats so either SDK
# respects the setting. The provider SDK determines which format is used:
#
#   Anthropic SDK (@ai-sdk/anthropic):
#     - Uses "thinking" field: {type: "enabled", budgetTokens: N}
#     - Config-level thinking is IGNORED by `opencode run` (only --thinking flag works)
#     - `--thinking` CLI flag forces thinking ON, overriding config
#
#   OpenAI-compatible SDK (@ai-sdk/openai-compatible):
#     - Uses "reasoning" field: {effort: "low"|"medium"|"high"|"xhigh"|"max"}
#     - Also emits "reasoningEffort" (flat) for opencode pass-through compatibility
#     - Config-level thinking IS respected by `opencode run`
#
# Humor → Thinking Budget → Effort Mapping:
#   robotic     → budget=6144  → thinking.type=enabled,  reasoning.effort=medium, reasoningEffort=medium
#   introvert   → budget=8192  → thinking.type=enabled,  reasoning.effort=high,   reasoningEffort=high
#   pragmatic   → budget=12288 → thinking.type=enabled,  reasoning.effort=xhigh,  reasoningEffort=xhigh
#   sympathetic → budget=14336 → thinking.type=enabled,  reasoning.effort=max,    reasoningEffort=max
#   extrovert   → budget=16384 → thinking.type=enabled,  reasoning.effort=max,    reasoningEffort=max
#
# ── Host Model Selection ─────────────────────────────────────────────────────
#
# Personas with `preferredModel: host` get an agent binding WITHOUT a model
# field. OpenCode routes these agents to whatever model the user selected in
# the TUI at session start — the binding follows the live selection instead of
# freezing a stale value. The maestro persona uses the `build` agent name.
# OpenCode keeps `build` as the visible primary agent and hides all other
# generated persona agents as subagents.
#
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

checkRequiredDependencies() {
  local toolName missingToolList
  missingToolList=""

  for toolName in "$@"; do
    if ! command -v "$toolName" >/dev/null 2>&1; then
      if [ -n "$missingToolList" ]; then
        missingToolList="${missingToolList}, ${toolName}"
        continue
      fi
      missingToolList="$toolName"
    fi
  done

  if [ -n "$missingToolList" ]; then
    echo "Skipping: $missingToolList not installed — CLI configuration requires these tools" >&2
    exit 0
  fi
}

# ── Environment Detection ───────────────────────────────────────

isRunningInsideSupportedCli() {
  if [ -n "${isRunningInsideSupportedCliEnvOverride:-}" ]; then
    echo "$isRunningInsideSupportedCliEnvOverride"
    return 0
  fi

  local currentPid="$PPID"
  local processName

  while [ "$currentPid" -gt 1 ] 2>/dev/null; do
    processName=$(ps -o comm= -p "$currentPid" 2>/dev/null || true)
    if [ -z "$processName" ]; then
      break
    fi
    processName="${processName#.}"
    if [ "$processName" = "opencode" ]; then
      echo "true"
      return 0
    fi
    currentPid=$(ps -o ppid= -p "$currentPid" 2>/dev/null || true)
    currentPid="${currentPid// /}"
  done

  echo "false"
  return 0
}

resolveScriptDir() {
  (cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
}

resolveSupportedCliConfigPath() {
  if [ -f "opencode.json" ]; then
    echo "opencode.json existed"
    return 0
  fi
  cat <<'EOF' > opencode.json
{"$schema": "https://opencode.ai/config.json", "agent": {"plan": {"disable": true}}}
EOF
  echo "opencode.json created"
  return 0
}

readPersonaFrontmatter() {
  local personaPath="$1"
  awk '/^---$/{n++; next} n==1{print} n==2{exit}' "$personaPath"
}

readProvidersYamlBlock() {
  local dispatchMdPath
  dispatchMdPath="$(resolveScriptDir)/../dispatch/SKILL.md"
  awk '/^## Providers$/{inProviders=1; next} /^## /{inProviders=0} inProviders && /^```yaml$/{inBlock=1; next} inBlock && /^```$/{exit} inBlock{print}' "$dispatchMdPath"
}

isProviderOnSupportedCli() {
  local providerName="$1"
  local providerCli
  providerCli=$(readProvidersYamlBlock | yq ".providers[\"$providerName\"].cli // \"\"" 2>/dev/null || true)
  if [ "$providerCli" = "opencode" ]; then
    echo "true"
    return 0
  fi
  echo "false"
}

shouldSkipDispatch() {
  local preferredModel="$1"
  if [ "$preferredModel" = "host" ] || [ -z "$preferredModel" ]; then
    echo "true"
    return 0
  fi
  echo "false"
}

resolveProviderModelId() {
  local providerName="$1"
  local modelTier="$2"

  local resolvedModelString
  resolvedModelString=$(readProvidersYamlBlock | yq ".providers[\"$providerName\"][\"$modelTier\"] // \"\"")

  if [ "$resolvedModelString" = "null" ]; then
    echo ""
    return 0
  fi

  echo "$resolvedModelString"
  return 0
}

readPersonaPreferredModel() {
  local personaPath="$1"
  readPersonaFrontmatter "$personaPath" | yq '.preferredModel // "host"'
}

resolvePersonaModelId() {
  local personaPath="$1"

  local frontmatterYaml preferredModelValue modelTierValue resolvedModelString
  frontmatterYaml=$(readPersonaFrontmatter "$personaPath")
  preferredModelValue=$(echo "$frontmatterYaml" | yq '.preferredModel // ""')

  if [ -z "$preferredModelValue" ] || [ "$preferredModelValue" = "host" ]; then
    echo ""
    return 0
  fi

  if [ "$(isProviderOnSupportedCli "$preferredModelValue")" != "true" ]; then
    echo ""
    return 0
  fi

  modelTierValue=$(echo "$frontmatterYaml" | yq '.modelTier // "tier-2"')
  resolvedModelString=$(resolveProviderModelId "$preferredModelValue" "$modelTierValue")
  echo "$resolvedModelString"
}

readPersonaDescription() {
  local personaPath="$1"
  readPersonaFrontmatter "$personaPath" | yq '.description // ""'
}

readPersonaHumor() {
  local personaPath="$1"
  readPersonaFrontmatter "$personaPath" | yq '.humor // "default"'
}

resolveHumorAttributes() {
  local humor="$1"
  local attribute="$2"
  case "$humor" in
    robotic)
      case "$attribute" in
        temperature)      echo "0.2" ;;
        topP)             echo "0.7" ;;
        thinkingBudget)   echo "6144" ;;
        reasoningEffort)  echo "medium" ;;
      esac
      ;;
    introvert)
      case "$attribute" in
        temperature)      echo "0.2" ;;
        topP)             echo "0.75" ;;
        thinkingBudget)   echo "8192" ;;
        reasoningEffort)  echo "high" ;;
      esac
      ;;
    pragmatic)
      case "$attribute" in
        temperature)      echo "0.25" ;;
        topP)             echo "0.8" ;;
        thinkingBudget)   echo "12288" ;;
        reasoningEffort)  echo "xhigh" ;;
      esac
      ;;
    sympathetic)
      case "$attribute" in
        temperature)      echo "0.3" ;;
        topP)             echo "0.85" ;;
        thinkingBudget)   echo "14336" ;;
        reasoningEffort)  echo "max" ;;
      esac
      ;;
    extrovert)
      case "$attribute" in
        temperature)      echo "0.35" ;;
        topP)             echo "0.85" ;;
        thinkingBudget)   echo "16384" ;;
        reasoningEffort)  echo "max" ;;
      esac
      ;;
    *)
      echo ""
      ;;
  esac
}

extractPersonaName() {
  local personaPath="$1"
  basename "$personaPath" .md
}

shouldSkipPersona() {
  local personaName="$1"
  if [ "$personaName" = "README" ]; then
    echo "true"
    return 0
  fi
  echo "false"
}

resolveAgentName() {
  local personaName="$1"
  if [ "$personaName" = "maestro" ]; then
    echo "build"
    return
  fi
  echo "$personaName"
}

applyPermissionProfile() {
  local personaName="$1"
  local agentBindings="$2"

  local profileJson

  case "$personaName" in
    maestro|build)
      profileJson='{
  "permission": {
    "bash": {
      "*": "ask",
      "rm *": "deny",
      "rm -f /tmp/*": "allow",
      "rm -r /tmp/*": "allow",
      "rm -rf /tmp/*": "allow",
      "rm /tmp/*": "allow",
      "mkfs *": "deny",
      "dd *": "deny",
      "chmod *": "deny",
      "chown *": "deny",
      "curl *": "deny",
      "wget *": "deny",
      "sudo *": "deny",
      "git -*": "deny",
      "git clean *": "deny",
      "git reset *": "deny",
      "git rebase *": "deny",
      "git push --force *": "deny",
      "git push -f *": "deny",
      "bash skills/assets/*.sh *": "allow",
      "yq *": "allow",
      "jq *": "allow",
      "mktemp *": "allow",
      "echo *": "allow",
      "printf *": "allow",
      "which *": "allow",
      "command *": "allow",
      "basename *": "allow",
      "dirname *": "allow",
      "realpath *": "allow",
      "readlink *": "allow",
      "env": "allow",
      "env *": "deny",
      "pwd *": "allow",
      "date *": "allow",
      "id *": "allow",
      "ps *": "allow",
      "test *": "allow",
      "tinyfish auth status": "allow",
      "tinyfish auth status *": "allow",
      "tinyfish fetch content get *": "allow",
      "tinyfish search query *": "allow",
      "ls *": "allow",
      "find *": "allow",
      "find * -delete*": "deny",
      "grep *": "allow",
      "rg *": "allow",
      "cat *": "allow",
      "head *": "allow",
      "tail *": "allow",
      "wc *": "allow",
      "sort *": "allow",
      "sed *": "allow",
      "awk *": "allow",
      "tr *": "allow",
      "cut *": "allow",
      "uniq *": "allow",
      "stat *": "allow",
      "diff *": "allow",
      "tree *": "allow",
      "read *": "allow",
      "git *": "allow",
      "go test *": "allow",
      "go build *": "allow",
      "go vet *": "allow",
      "gofmt *": "allow",
      "go mod tidy *": "allow",
      "mkdir *": "allow",
      "touch *": "allow",
      "cp *": "allow",
      "mv *": "allow",
      "tee *": "allow",
      "xargs *": "allow",
      "ln *": "allow"
    },
    "edit": {
      ".memory/*": "allow",
      ".memory/**": "allow",
      ".memory/plan/*": "allow",
      ".memory/todo/*": "allow",
      ".memory/reviews/*": "allow",
      ".memory/session/*": "allow",
      "*.md": "allow",
      "/tmp/*": "allow",
      "*": "ask"
    },
    "read": {
      "*": "allow",
      "*.env": "deny",
      "*.env.*": "deny",
      "*.env.example": "allow",
      ".env.example": "allow"
    },
    "external_directory": {
      ".memory/*": "allow",
      ".memory/**": "allow",
      ".memory/plan/*": "allow",
      ".memory/todo/*": "allow",
      ".memory/reviews/*": "allow",
      ".memory/session/*": "allow",
      "/tmp/*": "allow"
    }
  }
}'
      ;;
    architect)
      profileJson='{
  "permission": {
    "bash": {
      "*": "deny",
      "sed -i *": "deny",
      "cp *": "deny",
      "mv *": "deny",
      "touch *": "deny",
      "tee *": "deny",
      "xargs *": "deny",
      "ln *": "deny",
      "rm *": "deny",
      "rm -f /tmp/*": "allow",
      "rm -r /tmp/*": "allow",
      "rm -rf /tmp/*": "allow",
      "rm /tmp/*": "allow",
      "mkfs *": "deny",
      "dd *": "deny",
      "chmod *": "deny",
      "chown *": "deny",
      "curl *": "deny",
      "wget *": "deny",
      "sudo *": "deny",
      "git -*": "deny",
      "git clean *": "deny",
      "git reset *": "deny",
      "git rebase *": "deny",
      "git push --force *": "deny",
      "git push -f *": "deny",
      "git stash *": "deny",
      "git checkout -- *": "deny",
      "git restore *": "deny",
      "git filter-branch *": "deny",
      "git cherry-pick *": "deny",
      "git worktree *": "deny",
      "git reflog expire *": "deny",
      "yq *": "allow",
      "jq *": "allow",
      "mktemp *": "allow",
      "echo *": "allow",
      "printf *": "allow",
      "which *": "allow",
      "command *": "allow",
      "basename *": "allow",
      "dirname *": "allow",
      "realpath *": "allow",
      "readlink *": "allow",
      "env": "allow",
      "env *": "deny",
      "pwd *": "allow",
      "date *": "allow",
      "id *": "allow",
      "ps *": "allow",
      "test *": "allow",
      "tinyfish auth status": "allow",
      "tinyfish auth status *": "allow",
      "tinyfish fetch content get *": "allow",
      "tinyfish search query *": "allow",
      "ls *": "allow",
      "find *": "allow",
      "find * -delete*": "deny",
      "grep *": "allow",
      "rg *": "allow",
      "cat *": "allow",
      "head *": "allow",
      "tail *": "allow",
      "sort *": "allow",
      "sed *": "allow",
      "awk *": "allow",
      "tr *": "allow",
      "cut *": "allow",
      "uniq *": "allow",
      "wc *": "allow",
      "tree *": "allow",
      "read *": "allow",
      "git status *": "allow",
      "git diff *": "allow",
      "git log *": "allow",
      "git show *": "allow",
      "git branch *": "allow",
      "git rev-parse *": "allow",
      "git ls-files *": "allow",
      "git blame *": "allow",
      "git merge-base *": "allow",
      "git describe *": "allow",
      "diff *": "allow",
      "stat *": "allow",
      "mkdir *": "allow"
    },
    "edit": {
      ".memory/*": "allow",
      ".memory/**": "allow",
      ".memory/plan/*": "allow",
      ".memory/todo/*": "allow",
      ".memory/reviews/*": "allow",
      ".memory/session/*": "allow",
      "*.md": "allow",
      "/tmp/*": "allow",
      "*": "ask"
    },
    "read": {
      "*": "allow"
    },
    "external_directory": {
      ".memory/*": "allow",
      ".memory/**": "allow",
      ".memory/plan/*": "allow",
      ".memory/todo/*": "allow",
      ".memory/reviews/*": "allow",
      ".memory/session/*": "allow",
      "/tmp/*": "allow"
    }
  }
}';
      ;;
    coder)
      profileJson='{
  "permission": {
    "bash": {
      "*": "ask",
      "rm *": "deny",
      "rm -f /tmp/*": "allow",
      "rm -r /tmp/*": "allow",
      "rm -rf /tmp/*": "allow",
      "rm /tmp/*": "allow",
      "mkfs *": "deny",
      "dd *": "deny",
      "chmod *": "deny",
      "chown *": "deny",
      "curl *": "deny",
      "wget *": "deny",
      "sudo *": "deny",
      "git -*": "deny",
      "git clean *": "deny",
      "git reset *": "deny",
      "git rebase *": "deny",
      "git push --force *": "deny",
      "git push -f *": "deny",
      "git stash *": "deny",
      "git checkout -- *": "deny",
      "git restore *": "deny",
      "git filter-branch *": "deny",
      "git cherry-pick *": "deny",
      "git worktree *": "deny",
      "git reflog expire *": "deny",
      "mkdir *": "allow",
      "yq *": "allow",
      "jq *": "allow",
      "mktemp *": "allow",
      "echo *": "allow",
      "printf *": "allow",
      "which *": "allow",
      "command *": "allow",
      "basename *": "allow",
      "dirname *": "allow",
      "realpath *": "allow",
      "readlink *": "allow",
      "env": "allow",
      "env *": "deny",
      "pwd *": "allow",
      "date *": "allow",
      "id *": "allow",
      "ps *": "allow",
      "test *": "allow",
      "tinyfish auth status": "allow",
      "tinyfish auth status *": "allow",
      "tinyfish fetch content get *": "allow",
      "tinyfish search query *": "allow",
      "ls *": "allow",
      "find *": "allow",
      "find * -delete*": "deny",
      "grep *": "allow",
      "rg *": "allow",
      "cat *": "allow",
      "head *": "allow",
      "tail *": "allow",
      "wc *": "allow",
      "sort *": "allow",
      "sed *": "allow",
      "awk *": "allow",
      "tr *": "allow",
      "cut *": "allow",
      "uniq *": "allow",
      "stat *": "allow",
      "tree *": "allow",
      "read *": "allow",
      "diff *": "allow",
      "git status *": "allow",
      "git diff *": "allow",
      "git log *": "allow",
      "git show *": "allow",
      "git branch *": "allow",
      "git rev-parse *": "allow",
      "git ls-files *": "allow",
      "git blame *": "allow",
      "git merge-base *": "allow",
      "git describe *": "allow",
      "go vet *": "allow",
      "go build *": "allow",
      "go test *": "allow",
      "go run *": "allow",
      "go fmt *": "allow",
      "gofmt *": "allow",
      "go list *": "allow",
      "go doc *": "allow",
      "go version *": "allow",
      "go env *": "allow",
      "go mod tidy *": "allow",
      "go mod download *": "allow",
      "go mod verify *": "allow",
      "touch *": "allow",
      "cp *": "allow",
      "mv *": "allow",
      "tee *": "allow",
      "xargs *": "allow",
      "ln *": "allow"
    },
    "edit": {
      "*": "allow"
    },
    "read": {
      "*": "allow",
      "*.env": "deny",
      "*.env.*": "deny",
      "*.env.example": "allow",
      ".env.example": "allow"
    },
    "external_directory": {
      ".memory/*": "allow",
      ".memory/**": "allow",
      ".memory/plan/*": "allow",
      ".memory/todo/*": "allow",
      ".memory/reviews/*": "allow",
      ".memory/session/*": "allow",
      "/tmp/*": "allow"
    }
  }
}'
      ;;
    reviewer)
      profileJson='{
  "permission": {
    "bash": {
      "*": "ask",
      "sed -i *": "deny",
      "cp *": "deny",
      "mv *": "deny",
      "touch *": "deny",
      "tee *": "deny",
      "xargs *": "deny",
      "ln *": "deny",
      "rm *": "deny",
      "rm -f /tmp/*": "allow",
      "rm -r /tmp/*": "allow",
      "rm -rf /tmp/*": "allow",
      "rm /tmp/*": "allow",
      "mkfs *": "deny",
      "dd *": "deny",
      "chmod *": "deny",
      "chown *": "deny",
      "curl *": "deny",
      "wget *": "deny",
      "sudo *": "deny",
      "git -*": "deny",
      "git clean *": "deny",
      "git reset *": "deny",
      "git rebase *": "deny",
      "git push --force *": "deny",
      "git push -f *": "deny",
      "git stash *": "deny",
      "git checkout -- *": "deny",
      "git restore *": "deny",
      "git filter-branch *": "deny",
      "git cherry-pick *": "deny",
      "git worktree *": "deny",
      "git reflog expire *": "deny",
      "yq *": "allow",
      "jq *": "allow",
      "mktemp *": "allow",
      "echo *": "allow",
      "printf *": "allow",
      "which *": "allow",
      "command *": "allow",
      "basename *": "allow",
      "dirname *": "allow",
      "realpath *": "allow",
      "readlink *": "allow",
      "env": "allow",
      "env *": "deny",
      "pwd *": "allow",
      "date *": "allow",
      "id *": "allow",
      "ps *": "allow",
      "test *": "allow",
      "tinyfish auth status": "allow",
      "tinyfish auth status *": "allow",
      "tinyfish fetch content get *": "allow",
      "tinyfish search query *": "allow",
      "ls *": "allow",
      "find *": "allow",
      "find * -delete*": "deny",
      "grep *": "allow",
      "rg *": "allow",
      "cat *": "allow",
      "head *": "allow",
      "tail *": "allow",
      "sort *": "allow",
      "sed *": "allow",
      "awk *": "allow",
      "tr *": "allow",
      "cut *": "allow",
      "uniq *": "allow",
      "wc *": "allow",
      "tree *": "allow",
      "read *": "allow",
      "git status *": "allow",
      "git diff *": "allow",
      "git log *": "allow",
      "git show *": "allow",
      "git branch *": "allow",
      "git rev-parse *": "allow",
      "git ls-files *": "allow",
      "git blame *": "allow",
      "git merge-base *": "allow",
      "git describe *": "allow",
      "go vet *": "allow",
      "go build *": "allow",
      "go test *": "allow",
      "go list *": "allow",
      "go doc *": "allow",
      "go version *": "allow",
      "go env *": "allow",
      "gofmt *": "allow",
      "go fmt *": "allow",
      "diff *": "allow",
      "stat *": "allow",
      "mkdir *": "allow"
    },
    "edit": {
      ".memory/*": "allow",
      ".memory/**": "allow",
      ".memory/plan/*": "allow",
      ".memory/todo/*": "allow",
      ".memory/reviews/*": "allow",
      ".memory/session/*": "allow",
      "*.md": "allow",
      "/tmp/*": "allow",
      "*": "ask"
    },
    "read": {
      "*": "allow"
    },
    "external_directory": {
      ".memory/*": "allow",
      ".memory/**": "allow",
      ".memory/plan/*": "allow",
      ".memory/todo/*": "allow",
      ".memory/reviews/*": "allow",
      ".memory/session/*": "allow",
      "/tmp/*": "allow"
    }
  }
}';
      ;;
    contextualizer)
      profileJson='{
  "permission": {
    "bash": {
      "*": "ask",
      "rm *": "deny",
      "rm -f /tmp/*": "allow",
      "rm -r /tmp/*": "allow",
      "rm -rf /tmp/*": "allow",
      "rm /tmp/*": "allow",
      "mkfs *": "deny",
      "dd *": "deny",
      "chmod *": "deny",
      "chown *": "deny",
      "curl *": "deny",
      "wget *": "deny",
      "sudo *": "deny",
      "git -*": "deny",
      "git clean *": "deny",
      "git reset *": "deny",
      "git rebase *": "deny",
      "git push --force *": "deny",
      "git push -f *": "deny",
      "git stash *": "deny",
      "git checkout -- *": "deny",
      "git restore *": "deny",
      "git filter-branch *": "deny",
      "git cherry-pick *": "deny",
      "git worktree *": "deny",
      "git reflog expire *": "deny",
      "yq *": "allow",
      "jq *": "allow",
      "mktemp *": "allow",
      "echo *": "allow",
      "printf *": "allow",
      "which *": "allow",
      "command *": "allow",
      "basename *": "allow",
      "dirname *": "allow",
      "realpath *": "allow",
      "readlink *": "allow",
      "env": "allow",
      "env *": "deny",
      "pwd *": "allow",
      "date *": "allow",
      "id *": "allow",
      "ps *": "allow",
      "test *": "allow",
      "tinyfish auth status": "allow",
      "tinyfish auth status *": "allow",
      "tinyfish fetch content get *": "allow",
      "tinyfish search query *": "allow",
      "find *": "allow",
      "find * -delete*": "deny",
      "grep *": "allow",
      "rg *": "allow",
      "ls *": "allow",
      "cat *": "allow",
      "read *": "allow",
      "head *": "allow",
      "tail *": "allow",
      "wc *": "allow",
      "sort *": "allow",
      "sed *": "allow",
      "awk *": "allow",
      "tr *": "allow",
      "cut *": "allow",
      "uniq *": "allow",
      "tree *": "allow",
      "stat *": "allow",
      "file *": "allow",
      "mkdir *": "allow",
      "touch *": "allow",
      "cp *": "allow",
      "mv *": "allow",
      "tee *": "allow",
      "xargs *": "allow",
      "ln *": "allow"
    },
    "edit": {
      ".memory/*": "allow",
      ".memory/**": "allow",
      ".memory/plan/*": "allow",
      ".memory/todo/*": "allow",
      ".memory/reviews/*": "allow",
      ".memory/session/*": "allow",
      "*.md": "allow",
      "/tmp/*": "allow",
      "*": "ask"
    },
    "read": {
      "*": "allow",
      "*.env": "deny",
      "*.env.*": "deny",
      "*.env.example": "allow",
      ".env.example": "allow"
    },
    "external_directory": {
      ".memory/*": "allow",
      ".memory/**": "allow",
      ".memory/plan/*": "allow",
      ".memory/todo/*": "allow",
      ".memory/reviews/*": "allow",
      ".memory/session/*": "allow",
      "/tmp/*": "allow"
    }
  }
}';
      ;;
    *)
      echo "$agentBindings"
      return
      ;;
  esac

  echo "$agentBindings" | jq --arg name "$personaName" --argjson profile "$profileJson" \
    '.[$name] = .[$name] * $profile'
}

writeAgentsToConfigFile() {
  local configPath="$1"
  local agentBindings="$2"
  local tmpFile existingAgentBindings mergedBindings

  existingAgentBindings=$(jq -S '.agent // {}' "$configPath" 2>/dev/null || echo '{}')
  mergedBindings=$(jq -S --argjson bindings "$agentBindings" \
    '.agent = (.agent // {} | . + $bindings) | .agent' "$configPath" 2>/dev/null || echo '{}')

  if [ "$existingAgentBindings" = "$mergedBindings" ]; then
    echo "unchanged"
    return
  fi

  tmpFile=$(mktemp)
  jq --argjson bindings "$agentBindings" \
    '.agent = (.agent // {} | . + $bindings)' "$configPath" > "$tmpFile"
  mv "$tmpFile" "$configPath"
  echo "changed"
}

applyAgentVisibilityProfile() {
  local agentName="$1"
  local agentBindings="$2"

  if [ "$agentName" = "build" ]; then
    echo "$agentBindings" | jq --arg name "$agentName" \
      '.[$name] = .[$name] + {"mode": "primary"}'
    return
  fi

  echo "$agentBindings" | jq --arg name "$agentName" \
    '.[$name] = .[$name] + {"mode": "subagent", "hidden": true}'
}

disablePlanAgentBuilder() {
  local agentBindings="$1"
  echo "$agentBindings" | jq '. + {"plan": {"disable": true}}'
}

agentBindingBuilder() {
  local agentName="$1"
  local modelId="$2"
  local description="$3"
  local temperature="$4"
  local topP="$5"
  local thinkingBudget="$6"
  local agentBindings="$7"
  local reasoningEffort="$8"

  local thinkingJson=""
  if [ -n "$thinkingBudget" ]; then
    thinkingJson=$(jq -n \
      --argjson budget "$thinkingBudget" \
      --arg effort "$reasoningEffort" \
      '{"thinking":{"type":"enabled","budgetTokens":$budget},"reasoning":{"effort":$effort},"reasoningEffort":$effort}')
  fi

  local agentJson
  agentJson=$(jq -n --arg description "$description" \
    '{description: $description}')
  if [ -n "$modelId" ]; then
    agentJson=$(jq -n \
      --arg model "$modelId" \
      --arg description "$description" \
      '{model: $model, description: $description}')
  fi

  if [ -n "$temperature" ]; then
    agentJson=$(echo "$agentJson" | jq --argjson temp "$temperature" '. + {temperature: $temp}')
  fi

  if [ -n "$topP" ]; then
    agentJson=$(echo "$agentJson" | jq --argjson topP "$topP" '. + {top_p: $topP}')
  fi

  if [ -n "$thinkingJson" ]; then
    agentJson=$(echo "$agentJson" | jq --argjson thinking "$thinkingJson" '. + $thinking')
  fi

  jq -n --arg name "$agentName" --argjson agent "$agentJson" --argjson bindings "$agentBindings" \
    '$bindings | .[$name] = $agent'
}

personaAgentJsonBuilder() {
  local personasDir="$1"
  local personaPath agentName preferredModel modelId humor temperature topP thinkingBudget agentBindings personaDescription reasoningEffort
  agentBindings="{}"

  for personaPath in "$personasDir"/*.md; do
    agentName=$(extractPersonaName "$personaPath")
    if [ "$(shouldSkipPersona "$agentName")" = "true" ]; then
      continue
    fi

    agentName=$(resolveAgentName "$agentName")

    preferredModel=$(readPersonaPreferredModel "$personaPath")

    humor=$(readPersonaHumor "$personaPath")
    personaDescription=$(readPersonaDescription "$personaPath")
    temperature=$(resolveHumorAttributes "$humor" "temperature")
    topP=$(resolveHumorAttributes "$humor" "topP")
    thinkingBudget=$(resolveHumorAttributes "$humor" "thinkingBudget")
    reasoningEffort=$(resolveHumorAttributes "$humor" "reasoningEffort")

    if [ "$(shouldSkipDispatch "$preferredModel")" = "true" ]; then
      agentBindings=$(agentBindingBuilder "$agentName" "" "$personaDescription" "$temperature" "$topP" "$thinkingBudget" "$agentBindings" "$reasoningEffort")
      agentBindings=$(applyPermissionProfile "$agentName" "$agentBindings")
      agentBindings=$(applyAgentVisibilityProfile "$agentName" "$agentBindings")
      continue
    fi

    modelId=$(resolvePersonaModelId "$personaPath")

    if [ -z "$modelId" ]; then
      continue
    fi

    agentBindings=$(agentBindingBuilder "$agentName" "$modelId" "$personaDescription" "$temperature" "$topP" "$thinkingBudget" "$agentBindings" "$reasoningEffort")

    agentBindings=$(applyPermissionProfile "$agentName" "$agentBindings")
    agentBindings=$(applyAgentVisibilityProfile "$agentName" "$agentBindings")
  done

  echo "$agentBindings"
}

addGeneralAgent() {
  local agentBindings="$1"
  local coderConfig
  coderConfig=$(echo "$agentBindings" | jq '.coder // empty')
  if [ -z "$coderConfig" ]; then
    echo "$agentBindings"
    return
  fi
  echo "$agentBindings" | jq '. + {"general": .coder}'
}

ensureHiddenDirectoriesAreSearchable() {
  local ignorePath=".ignore"
  if [ ! -f "$ignorePath" ]; then
    cat <<'EOF' > "$ignorePath"
!.agents/
!.memory/
EOF
    return
  fi
  if ! grep -q '^!\.agents/$' "$ignorePath"; then
    echo '!.agents/' >> "$ignorePath"
  fi
  if ! grep -q '^!\.memory/$' "$ignorePath"; then
    echo '!.memory/' >> "$ignorePath"
  fi
}

isInsideSupportedCli=$(isRunningInsideSupportedCli)
if [ "$isInsideSupportedCli" != "true" ]; then
  exit 0
fi

configLine=$(resolveSupportedCliConfigPath)
if [ -z "$configLine" ]; then
  exit 0
fi

ensureHiddenDirectoriesAreSearchable || true

configPath="${configLine%% *}"
configStatus="${configLine##* }"

checkRequiredDependencies yq jq

personasDir=".agents/personas"
if [ ! -d "$personasDir" ]; then
  echo "PersonasDirectoryNotFound" >&2
  exit 0
fi

agentBindings=$(personaAgentJsonBuilder "$personasDir")
agentBindings=$(addGeneralAgent "$agentBindings")
agentBindings=$(disablePlanAgentBuilder "$agentBindings")
writeResult=$(writeAgentsToConfigFile "$configPath" "$agentBindings")

finalStatus="unchanged"
if [ "$configStatus" = "created" ]; then
  finalStatus="created"
fi
if [ "$writeResult" = "changed" ] && [ "$configStatus" != "created" ]; then
  finalStatus="updated"
fi

agentCount=$(echo "$agentBindings" | jq 'keys | length')
echo "${configPath}: configured ${agentCount} persona agent bindings"
echo "configStatus=${finalStatus}"
