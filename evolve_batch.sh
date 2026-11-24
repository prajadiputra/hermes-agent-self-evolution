#!/usr/bin/env bash
set -uo pipefail
REPO=/usr/local/lib/hermes-agent/skills
V=/usr/local/lib/hermes-agent/venv
cd /root/AI/hermes-agent-self-evolution || exit 1
mkdir -p output
export OPENAI_API_BASE="http://127.0.0.1:20128/v1"
export OPENAI_API_KEY="${HERMES_CUSTOM_127_0_0_1_20128_API_KEY:-}"
export HERMES_AGENT_REPO=/usr/local/lib/hermes-agent
while IFS= read -r md; do
  skill=$(basename "$(dirname "$md")")
  echo "════ ${skill}"
  "$V/bin/python" -m evolution.skills.evolve_skill \
    --skill "$skill" --iterations 5 --eval-source synthetic \
    --optimizer-model openai/gtnk --eval-model openai/gtnk \
    --hermes-repo /usr/local/lib/hermes-agent \
    >"output/${skill}.log" 2>&1 && echo "  ✓ ${skill}" || echo "  ✗ ${skill} FAIL"
done < <(find "$REPO" -name SKILL.md | sort -u)
echo "ALL_DONE"
