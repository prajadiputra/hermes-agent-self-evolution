#!/usr/bin/env bash
# Retry wrapper: run evolve_resume.sh up to 3 passes (handles out-of-credit transient fails)
set -uo pipefail
cd /root/AI/hermes-agent-self-evolution || exit 1
for pass in 1 2 3; do
  echo "===== PASS ${pass} ====="
  bash evolve_resume.sh > "output/resume_pass${pass}.log" 2>&1
  fails=$(grep -cE "FAIL" "output/resume_pass${pass}.log" || true)
  done_ts=$(find output -mindepth 2 -maxdepth 2 -name metrics.json -path 'output/*/[0-9]*/metrics.json' | wc -l)
  echo "PASS ${pass}: done=${done_ts} fails=${fails}"
  # stop when no skill actually ran (all done) OR pass 3 finished
  ran=$(grep -cE "^════" "output/resume_pass${pass}.log" || true)
  [ "$ran" -eq 0 ] && break
done
echo "ALL_PASSES_DONE"
