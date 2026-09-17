import assert from 'node:assert/strict';import fs from 'node:fs/promises';import {request} from '../web/engine.mjs';
const call=job=>JSON.parse(request(JSON.stringify(job))),sample=Array.from({length:4096},(_,i)=>i);
const job={mode:'overlap',sample,sampleWidth:64,sampleHeight:64,size:2,width:16,height:16,periodicInput:true,symmetry:1,seed:37,budget:30000000};
const started=performance.now(),result=call(job);assert(result.ok,result.error);assert.equal(result.status,'solved');assert.equal(result.patternCount,4096);
// Independent coordinate oracle: unique source colors identify x and y exactly.
const ox=result.pixels[0]%64,oy=Math.floor(result.pixels[0]/64);
for(let y=0;y<16;y++)for(let x=0;x<16;x++)assert.equal(result.pixels[y*16+x],((oy+y)%64)*64+(ox+x)%64);
const tooMany=call({...job,sample:Array.from({length:65*64},(_,i)=>i),sampleWidth:65});assert(!tooMany.ok);assert.match(tooMany.error,/pattern count limit/);
const tooWide=call({...job,width:24,height:24});assert(!tooWide.ok);assert.match(tooWide.error,/state limit/);
const one=call({mode:'overlap',sample:[7],sampleWidth:1,sampleHeight:1,size:1,width:256,height:256});assert(one.ok);assert.equal(one.pixels.length,65536);assert(one.pixels.every(x=>x===7));
const deep=call({mode:'rules',model:{labels:['a','b'],weights:[1,1],neighbors:Array.from({length:2},()=>Array.from({length:4},()=>[0,1]))},width:256,height:256,seed:1});assert(deep.ok,deep.error);assert.equal(deep.status,'solved');assert.equal(deep.solution.decisions,65536);assert(deep.solution.tiles.every(t=>t===0||t===1));
const skewed=call({mode:'rules',model:{labels:['blocked','tiny','tiny2'],weights:[1e6,1e-200,2e-200],neighbors:[[[],[],[],[]],[[1,2],[1,2],[1,2],[1,2]],[[1,2],[1,2],[1,2],[1,2]]]},width:32,height:32,seed:17});assert(skewed.ok,skewed.error);assert.equal(skewed.status,'solved');assert(skewed.solution.tiles.every(x=>x===1||x===2));
const evidence={patterns:4096,validatedUniqueColorPixels:256,maxCellOutput:65536,iterativeSearchDecisions:deep.solution.decisions,overPatternAndStateLimitsRejected:true,dominantWeightRemovalSolved:true,elapsedMs:performance.now()-started,scope:'independent source-coordinate checks, not upstream compatibility for >256 colors'};
await fs.writeFile(new URL('../evidence/capacity-validation.json',import.meta.url),JSON.stringify(evidence,null,2)+'\n');console.log(JSON.stringify(evidence));
