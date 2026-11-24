#!/usr/bin/env bash
# Evolve ALL Hermes skills via 9Router (batch loop)
# Usage: ./evolve_all.sh [iterations] [limit]
set -uo pipefail
V=/usr/local/lib/hermes-agent/venv
ITER="${1:-5}"
LIMIT="${2:-0}"   # 0 = all; else cap N skills
V='/usr/local/lib/hermes-agent/venv'
cd /root/AI/hermes-agent-self-evolution || exit 1
export OPENAI_API_BASE="http://127.0.0.1:20128/v1"
export OPENAI_API_KEY="${HERMES_CUSTOM_127_0_0_1_20128_API_KEY:-}"
export HERMES_AGENT_REPO=/usr/local/lib/hermes-agent
i=0
while IFS= read -r md; do
  skill="$(basename "$(dirname "$md")")"
  i=$((i+1))
  ((LIMIT>0 && i>LIMIT)) && break
  echo "════ [${i}] ${skill}"
  "$V/bin/python" -m evolution.skills.evolve_skill \
    --skill "$skill" --iterations "$ITER" --eval-source synthetic \
    --optimizer-model "openai/gtnk" --eval-model "openai/gtnk" \
    --hermes-repo /usr/local/lib/hermes-agent \
    > "output/${skill}.log" 2>&1 \
    && echo "  ✓ ${skill} done" || echo "  ✗ ${skill} FAIL (log: output/${skill}.log)"
done < <(find "$HERMES_AGENT_REPO/skills" -name SKILL.md | sort)
echo "── done: ${i} skills"
