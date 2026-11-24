#!/usr/bin/env bash
# Fast-first resume: evolve remaining skills, sorted by estimated speed
# (small SKILL.md + existing dataset first), 10 workers parallel.
# Correct skill path: skills/<category>/<skill>/SKILL.md
set -uo pipefail
V=/usr/local/lib/hermes-agent/venv
cd /root/AI/hermes-agent-self-evolution || exit 1
mkdir -p output

# Generate speed-sorted queue (score: KB size - 35 if dataset exists)
node > /tmp/evolve_queue.txt <<'NODE'
const fs=require('fs'), path=require('path');
const repo='/usr/local/lib/hermes-agent/skills';
const dirs=fs.readdirSync('output').filter(p=>{try{return fs.statSync(path.join('output',p)).isDirectory()}catch{return false}});
const done=new Set();
for (const p of dirs) {
  const sp=path.join('output',p);
  const sub=fs.readdirSync(sp).filter(d=>/^\d{8}_\d{6}$/.test(d)&&fs.existsSync(path.join(sp,d,'metrics.json')));
  if (sub.length) done.add(p);
}
const rows=[];
function walk(dir){
  for (const e of fs.readdirSync(dir)) {
    const p=path.join(dir,e);
    if (!fs.statSync(p).isDirectory()) continue;
    if (fs.existsSync(path.join(p,'SKILL.md'))) {
      const d=e;
      if (done.has(d)) continue;
      const size=fs.statSync(path.join(p,'SKILL.md')).size;
      const hasDs=fs.existsSync(path.join('datasets','skills',d,'train.jsonl'));
      rows.push({d,score:size/1000-(hasDs?35:0)});
    } else walk(p);
  }
}
walk(repo);
rows.sort((a,b)=>a.score-b.score);
for (const r of rows) console.log(r.d);
NODE

total=$(wc -l < /tmp/evolve_queue.txt)
echo "=== remaining: ${total} (sorted fast-first)"
cat /tmp/evolve_queue.txt | tr '\n' ' '; echo

# Run 4 workers over the sorted queue (avoids litellm circular-import race in GEPA parallelizer)
cat /tmp/evolve_queue.txt | xargs -P 4 -I{} bash evolve_one.sh {}
echo "ALL_DONE"
