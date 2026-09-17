import assert from 'node:assert/strict';import fs from 'node:fs/promises';import {request} from '../web/engine.mjs';
const call=job=>{const result=JSON.parse(request(JSON.stringify(job)));assert(result.ok,result.error);return result};
const cases=JSON.parse(await fs.readFile(new URL('./exhaustive-cases.json',import.meta.url),'utf8'));
let backtrackingSolutions=0;
function validate(tiles,model,width,height,periodic,pins=[]){
 assert.equal(tiles.length,width*height);for(const t of tiles)assert(Number.isInteger(t)&&t>=0&&t<model.labels.length);
 for(const [c,t]of pins)assert.equal(tiles[c],t);
 for(let y=0;y<height;y++)for(let x=0;x<width;x++){
  const tile=tiles[y*width+x];
  for(const [d,dx,dy]of [[0,1,0],[1,0,1],[2,-1,0],[3,0,-1]]){let nx=x+dx,ny=y+dy;if(periodic){nx=(nx+width)%width;ny=(ny+height)%height}if(nx>=0&&nx<width&&ny>=0&&ny<height)assert(model.neighbors[tile][d].includes(tiles[ny*width+nx]))}
 }
}
for(const job of cases){const result=call(job);assert.equal(result.status==='solved',job.expectedSatisfiable);if(result.solution){validate(result.solution.tiles,job.model,job.width,job.height,job.periodic,job.pins);if(result.solution.backtracks>0)backtrackingSolutions++}}
assert(backtrackingSolutions>0,'Must exercise successful rollback as well as unsat');
const sample=[0,0,0,0,0,0,1,1,1,0,0,1,2,1,0,0,1,1,1,0,0,0,0,0,0];
const learning={mode:'learn',sample,sampleWidth:5,sampleHeight:5,size:3,symmetry:8,periodicInput:true};
const learned=call(learning).model;const patterns=new Set(learned.patterns.map(p=>p.join(',')));let generated=0;
for(const periodic of [false,true])for(const seed of [1,2,3,17,42,123]){
 const width=25,height=20,result=call({...learning,mode:'overlap',width,height,seed,periodic,pins:[[0,0],[width*height-1,0]],budget:30000000});
 assert.equal(result.status,'solved');assert.equal(result.pixels[0],0);assert.equal(result.pixels.at(-1),0);
 for(let y=0;y<(periodic?height:height-2);y++)for(let x=0;x<(periodic?width:width-2);x++){const p=[];for(let dy=0;dy<3;dy++)for(let dx=0;dx<3;dx++)p.push(result.pixels[(y+dy)%height*width+(x+dx)%width]);assert(patterns.has(p.join(',')))}generated++;
}
assert.equal(call({...learning,mode:'overlap',width:12,height:12,pins:[[0,0],[0,99]]}).status,'unsat');
const weights=[1,3,6],neighbors=Array.from({length:3},()=>Array.from({length:4},()=>[0,1,2]));let counts=[0,0,0];
for(let seed=1;seed<=128;seed++){const result=call({mode:'rules',model:{labels:['a','b','c'],weights,neighbors},width:16,height:8,seed});for(const tile of result.solution.tiles)counts[tile]++}
for(let i=0;i<3;i++)assert(Math.abs(counts[i]/16384-weights[i]/10)<0.025);
const report={exhaustiveCases:cases.length,successfulBacktrackingCases:backtrackingSolutions,independentPatchChecks:generated,weightedSamples:16384,observedCounts:counts,passed:true};
await fs.writeFile(new URL('../evidence/generation-validation.json',import.meta.url),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));
