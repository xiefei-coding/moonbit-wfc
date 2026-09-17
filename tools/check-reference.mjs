// Offline replay: expectations come only from the captured official C# output.
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import {request} from '../web/engine.mjs';
const report=JSON.parse(await fs.readFile(new URL('../evidence/upstream-comparison.json',import.meta.url),'utf8'));
for(const row of report.cases){
 const ref=row.reference,n=ref.weights.length;
 const rules={labels:row.kind==='overlap'?Array.from({length:n},(_,i)=>String(i)):ref.labels,weights:ref.weights,neighbors:Array.from({length:n},(_,t)=>[2,1,0,3].map(d=>ref.propagator[d][t]))};
 const model=row.kind==='overlap'?{size:row.job.size,patterns:ref.patterns,rules}:{rules,tiles:ref.tiles,tile_size:row.job.tileSize};
 assert.deepEqual(JSON.parse(request(JSON.stringify(row.job))),{ok:true,model},row.name);
}
console.log(JSON.stringify({offlineOfficialVectors:report.cases.length,matched:report.cases.length,commit:report.commit}));
