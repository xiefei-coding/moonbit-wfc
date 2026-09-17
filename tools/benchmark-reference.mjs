import fs from 'node:fs/promises';import path from 'node:path';import os from 'node:os';import assert from 'node:assert/strict';import {spawn} from 'node:child_process';import readline from 'node:readline';import {createHash} from 'node:crypto';
import {archipelago} from '../web/samples.mjs';import {encodePNG,readPNG} from './images.mjs';import {request} from '../web/engine.mjs';
const ref=path.resolve(process.argv[2]??''),warmup=2,repeats=7;
const unique={width:8,height:8,pixels:Array.from({length:64},(_,i)=>0xff000000|i*302011)};
const island={width:5,height:5,pixels:[0,0,0,0,0,0,1,1,1,0,0,1,2,1,0,0,1,1,1,0,0,0,0,0,0].map(i=>[0xff244f5c|0,0xffd8be83|0,0xff8eaf75|0][i])};
const specs=[{name:'archipelago-3',sample:archipelago,size:3,width:64,height:64,symmetry:8},{name:'archipelago-4',sample:archipelago,size:4,width:48,height:48,symmetry:8},{name:'unique-64',sample:unique,size:2,width:128,height:128,symmetry:1},{name:'island-large',sample:island,size:3,width:128,height:128,symmetry:8}];
await fs.mkdir(path.join(ref,'samples'),{recursive:true});const jobs=[];
for(const s of specs){await fs.writeFile(path.join(ref,'samples',s.name+'.png'),encodePNG(s.sample));for(let i=0;i<warmup+repeats;i++)jobs.push({name:s.name,size:s.size,width:s.width,height:s.height,symmetry:s.symmetry,seed:17+i,output:path.join(ref,`${s.name}-${i}.png`)});}
const child=spawn('dotnet',[path.join(ref,'reference-benchmark.dll')],{cwd:ref,stdio:['pipe','pipe','pipe']}),rows=[];let errors='';
readline.createInterface({input:child.stdout}).on('line',line=>{if(line.startsWith('RESULT '))rows.push(JSON.parse(line.slice(7)))});child.stderr.on('data',v=>errors+=v);const timer=setTimeout(()=>child.kill(),120000);
for(const job of jobs)child.stdin.write(JSON.stringify(job)+'\n');child.stdin.end();const code=await new Promise((resolve,reject)=>{child.on('exit',resolve);child.on('error',reject)});clearTimeout(timer);assert.equal(code,0,errors);assert.equal(rows.length,jobs.length);
function patches(image,patterns,size){const allowed=new Set(patterns.map(p=>p.join(',')));for(let y=0;y<=image.height-size;y++)for(let x=0;x<=image.width-size;x++){const p=[];for(let dy=0;dy<size;dy++)for(let dx=0;dx<size;dx++)p.push(image.pixels[(y+dy)*image.width+x+dx]);assert(allowed.has(p.join(',')),'Unknown generated patch');}}
const summary=[];let index=0;
for(const s of specs){const measurements=[];let patterns;for(let i=0;i<warmup+repeats;i++,index++){
 const reference=rows[index];assert(!reference.error,reference.error);patterns=reference.patterns;
 const start=performance.now(),actual=JSON.parse(request(JSON.stringify({mode:'overlap',sample:s.sample.pixels,sampleWidth:s.sample.width,sampleHeight:s.sample.height,size:s.size,width:s.width,height:s.height,symmetry:s.symmetry,periodicInput:true,periodic:false,seed:17+i,budget:50000000}))),elapsedMs=performance.now()-start;
 assert(actual.ok,actual.error);assert.equal(actual.status,'solved');patches(actual,patterns,s.size);
 if(reference.solved)patches(await readPNG(jobs[index].output),patterns,s.size);
 if(i>=warmup)measurements.push({seed:17+i,localMs:elapsedMs,referenceLearnMs:reference.learnMs,referenceSolveMs:reference.solveMs,referenceMs:reference.totalMs,referenceSolved:reference.solved,localSolved:true});
 }
 const median=key=>measurements.map(r=>r[key]).sort((a,b)=>a-b)[3];
 summary.push({name:s.name,width:s.width,height:s.height,size:s.size,patterns:patterns.length,localMedianMs:median('localMs'),referenceMedianMs:median('referenceMs'),localAllSolved:true,referenceSolved:measurements.filter(r=>r.referenceSolved).length,measurements});
}
const report={cpu:os.cpus()[0].model,platform:process.platform,node:process.version,referenceRuntime:'.NET 9.0.13; Roslyn 4.12; original upstream project targets .NET 10',commit:(await fs.readFile(path.join(ref,'commit.txt'),'utf8')).trim(),warmup,repeats,scope:'Same host, sequential processes. Local includes JSON, learning, solving, pixel rendering; C# includes construction and Run, excludes PNG save and harness reflection. Different RNG/search and boundary-wave representation; not identical work or seed-identical images. No memory or cross-platform claim.',allSuccessfulOutputsCheckedAgainstOfficialPatterns:true,referenceHarnessSHA256:createHash('sha256').update(await fs.readFile(new URL('./ReferenceBenchmark.cs',import.meta.url))).digest('hex'),cases:summary};
await fs.writeFile(new URL('../evidence/reference-performance.json',import.meta.url),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(summary.map(({measurements,...rest})=>rest)));
