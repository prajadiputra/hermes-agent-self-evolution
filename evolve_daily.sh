#!/usr/bin/env bash
# Daily evolve: next N of the USED skill set (only 11 skills ever used in sessions).
# Usage: evolve_daily.sh <N>   (default 10)
set -uo pipefail
N="${1:-10}"
V=/usr/local/lib/hermes-agent/venv
cd /root/AI/hermes-agent-self-evolution || exit 1
mkdir -p output
export OPENAI_API_BASE="http://127.0.0.1:20128/v1"
export OPENAI_API_KEY="${HERMES_CUSTOM_127_0_0_1_20128_API_KEY:-}"
export HERMES_AGENT_REPO=/usr/local/lib/hermes-agent

# 11 skills actually used in session history, sorted smallest-first (fastest)
USED_SKILLS=(
  github-auth
  plan
  github-code-review
  github-repo-management
  requesting-code-review
  simplify-code
  systematic-debugging
  test-driven-development
  google-workspace
  hermes-agent
  computer-use
)

# Collect not-done, sorted by SKILL.md size
queue=()
for s in "${USED_SKILLS[@]}"; do
  if find "output/$s" -maxdepth 2 -name metrics.json 2>/dev/null | grep -q .; then
    echo "⏭ $s (done)"
    continue
  fi
  queue+=("$s")
done

remaining=${#queue[@]}
echo "=== USED-remaining: ${remaining} | taking ${N}"
slice=("${queue[@]:0:$N}")
echo "${slice[@]}"
printf '%s\n' "${slice[@]}" | xargs -P 4 -I{} bash evolve_one.sh {}
echo "DAILY_DONE ($(find output -mindepth 3 -maxdepth 3 -name metrics.json 2>/dev/null | wc -l)/77 total, $((remaining > N ? remaining - N : 0)) used-remaining)"
