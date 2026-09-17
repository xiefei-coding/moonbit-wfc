import fs from 'node:fs/promises';import path from 'node:path';import {spawn} from 'node:child_process';import readline from 'node:readline';import {createHash} from 'node:crypto';import {prepareJob} from './runtime.mjs';import {request} from '../web/engine.mjs';
const ref=path.resolve(process.argv[2]??''),cases=JSON.parse(await fs.readFile(path.join(ref,'cases.json'),'utf8'));
const child=spawn('dotnet',[path.join(ref,'oracle.dll')],{cwd:ref,stdio:['pipe','pipe','pipe']});const responses=[],warnings=[];let stderr='';
const lines=readline.createInterface({input:child.stdout});lines.on('line',line=>line.startsWith('RESULT ')?responses.push(JSON.parse(line.slice(7))):warnings.push(line));child.stderr.on('data',chunk=>stderr+=chunk);
const timer=setTimeout(()=>child.kill(),120000);for(const c of cases)child.stdin.write(JSON.stringify(c.reference)+'\n');child.stdin.end();
const exit=await new Promise((resolve,reject)=>{child.once('error',reject);child.once('exit',resolve)});clearTimeout(timer);
if(exit!==0||responses.length!==cases.length)throw Error('Reference failed '+exit+' '+responses.length+' '+stderr);
const equal=(a,b)=>JSON.stringify(a)===JSON.stringify(b),rows=[];
// Upstream uses west,south,east,north. Local public rules use east,south,west,north.
for(let i=0;i<cases.length;i++){
 const c=cases[i],reference=responses[i],job=await prepareJob(c.job,ref),actual=JSON.parse(request(JSON.stringify(job)));
 const r=reference.propagator?.[2]?.map((_,t)=>[reference.propagator[2][t],reference.propagator[1][t],reference.propagator[0][t],reference.propagator[3][t]]);
 const same=actual.ok&&!reference.error&&equal(actual.model.rules.weights,reference.weights)&&equal(actual.model.rules.neighbors,r)&&(c.reference.kind==='overlap'?equal(actual.model.patterns,reference.patterns):equal(actual.model.rules.labels,reference.labels)&&equal(actual.model.tiles,reference.tiles));
 rows.push({name:c.name,kind:c.reference.kind,job,reference,actual,match:same});
}
const report={upstream:'mxgmn/WaveFunctionCollapse',commit:(await fs.readFile(path.join(ref,'commit.txt'),'utf8')).trim(),scope:'exact learned patterns, weights, adjacency, tiled labels and oriented pixels; random outputs are not compared by seed',total:rows.length,matched:rows.filter(r=>r.match).length,mismatches:rows.filter(r=>!r.match).length,referenceWarnings:warnings,sourceSHA256:{},cases:rows};
for(const name of ['Model.cs','OverlappingModel.cs','SimpleTiledModel.cs','Helper.cs','Oracle.cs','LICENSE','WaveFunctionCollapse.csproj'])report.sourceSHA256[name]=createHash('sha256').update(await fs.readFile(path.join(ref,name))).digest('hex');
report.referenceBuild={originalTarget:'net10.0',testedTarget:'net9.0',runtime:'Microsoft.NETCore.App 9.0.13',unmodifiedModelSources:true,harness:'tools/ReferenceOracle.cs',packages:{}};
for(const name of ['microsoft.net.compilers.toolset','sixlabors.imagesharp'])report.referenceBuild.packages[name]=JSON.parse(await fs.readFile(path.join(ref,name+'.json'),'utf8'));
await fs.writeFile(new URL('../evidence/upstream-comparison.json',import.meta.url),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({total:report.total,matched:report.matched,mismatches:report.mismatches,warnings:warnings.length}));
for(const row of rows.filter(r=>!r.match))console.log(JSON.stringify({name:row.name,error:row.reference.error??row.actual.error,localPatterns:row.actual.model?.patterns?.length,referencePatterns:row.reference.patterns?.length}));
process.exitCode=report.mismatches?1:0;
