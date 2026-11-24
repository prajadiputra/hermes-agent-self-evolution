#!/usr/bin/env bash
# Worker: evolve ONE skill (called in parallel by evolve_resume.sh)
set -uo pipefail
skill="$1"
V=/usr/local/lib/hermes-agent/venv
export OPENAI_API_BASE="http://127.0.0.1:20128/v1"
export OPENAI_API_KEY="${HERMES_CUSTOM_127_0_0_1_20128_API_KEY:-}"
export HERMES_AGENT_REPO=/usr/local/lib/hermes-agent
cd /root/AI/hermes-agent-self-evolution || exit 1
if find "output/${skill}" -maxdepth 2 -name metrics.json 2>/dev/null | grep -q .; then
  echo "⏭ ${skill} (done)"; exit 0
fi
if compgen -G "datasets/skills/${skill}/train.jsonl" >/dev/null; then
  ds_arg="--eval-source golden --dataset-path datasets/skills/${skill}"
  echo "♻ ${skill} (dataset reuse)"
else
  ds_arg="--eval-source synthetic"
  echo "⚙ ${skill} (new dataset)"
fi
"$V/bin/python" -m evolution.skills.evolve_skill \
  --skill "$skill" --iterations 2 $ds_arg \
  --optimizer-model openai/gtnk --eval-model openai/gtnk \
  --hermes-repo /usr/local/lib/hermes-agent \
  >"output/${skill}.log" 2>&1
rc=$?
if [ $rc -eq 0 ] && find "output/${skill}" -maxdepth 2 -name metrics.json 2>/dev/null | grep -q .; then
  echo "✓ ${skill}"; exit 0
fi
echo "✗ ${skill} FAIL (rc=$rc)"; exit 1
