import assert from 'node:assert/strict';import fs from 'node:fs/promises';import os from 'node:os';import path from 'node:path';import {spawnSync} from 'node:child_process';import {fileURLToPath} from 'node:url';
import {decodePNG,encodePNG} from './images.mjs';import {loadTileset,parseTileset} from './tileset.mjs';import {prepareJob,execute,writeImage} from './runtime.mjs';
const root=path.dirname(path.dirname(fileURLToPath(import.meta.url))),dir=await fs.mkdtemp(path.join(os.tmpdir(),'wfc-runtime-')),groups=[];
const color=(r,g,b,a=255)=>(a<<24)|(r<<16)|(g<<8)|b;
const invoke=(args,input)=>{const r=spawnSync(process.execPath,[path.join(root,'tools/generate.mjs'),...args],{input,encoding:'utf8',timeout:20000,maxBuffer:12000000});assert.equal(r.error,undefined);return r};
async function group(name,fn){await fn();groups.push(name)}
try{
 const image={width:2,height:2,pixels:[color(1,2,3,255),color(4,5,6,128),color(7,8,9,0),color(255,254,253,17)]};
 await group('PNG exact ARGB and malformed header/CRC bounds',async()=>{
  assert.deepEqual(decodePNG(encodePNG(image)),image);
  const bad=encodePNG(image);bad[bad.length-1]^=1;assert.throws(()=>decodePNG(bad));
  const big=encodePNG(image);big.writeUInt32BE(1000000,16);assert.throws(()=>decodePNG(big),/pixel limit/);
  assert.throws(()=>decodePNG(Buffer.alloc(40)));assert.throws(()=>encodePNG({...image,pixels:[1]}));
 });
 await group('Independent Pillow RGB RGBA palette gray and 16-bit imports',async()=>{
  const python=`import sys,json\nfrom pathlib import Path\nfrom PIL import Image\np=Path(sys.argv[1]);out=[]\nfor mode in ['RGB','RGBA','P','1','L']:\n im=Image.new(mode,(4,3))\n if mode=='P': im.putpalette([i for v in range(256) for i in (v,255-v,v//2)])\n data=[(i*13,i*7,i*17,255-i*11)[:len(mode)] if mode in ('RGB','RGBA') else i%2 if mode=='1' else i*19 for i in range(12)]\n im.putdata(data);file=p/(mode+'.png');im.save(file);out.append({'file':str(file),'rgba':list(im.convert('RGBA').getdata())})\nim=Image.frombytes('I;16',(3,1),bytes([0,0,255,255,128,128]));im.save(p/'gray16.png')\nprint(json.dumps(out))`;
  const r=spawnSync('python',['-c',python,dir],{encoding:'utf8',timeout:15000});assert.equal(r.status,0,r.stderr);
  for(const item of JSON.parse(r.stdout)){const png=decodePNG(await fs.readFile(item.file));assert.deepEqual(png.pixels,item.rgba.map(([r,g,b,a])=>color(r,g,b,a)))}
  assert.deepEqual(decodePNG(await fs.readFile(path.join(dir,'gray16.png'))).pixels,[color(0,0,0),color(255,255,255),color(128,128,128)]);
 });
 await group('Unicode text palette produces visible pixels',async()=>{
  const job=await prepareJob({mode:'overlap',sample:'海🌳\n🌳海',palette:{'海':color(1,2,3),'🌳':color(40,50,60)},size:2,width:4,height:4});const result=await execute(job);assert(result.ok);assert.equal(result.status,'solved');assert(result.pixels.every(p=>p===color(1,2,3)||p===color(40,50,60)));assert(result.pixels.every(p=>(p>>>24)===255));
  await assert.rejects(prepareJob({sample:'x'}),/palette/);await assert.rejects(prepareJob({sample:'xy',palette:{x:-1}}),/palette/);
 });
 await group('XML strict parsing and tile image loading',async()=>{
  for(const xml of ['<!DOCTYPE set [<!ENTITY x SYSTEM "file:///private">]><set/>','<set><tiles></set>','<set><tiles><tile name="../bad"/></tiles></set>','<set><tiles><tile name="a"/></tiles><neighbors><neighbor left="missing" right="a"/></neighbors></set>'])assert.throws(()=>parseTileset(xml));
  await fs.mkdir(path.join(dir,'set'));await fs.writeFile(path.join(dir,'set/a.png'),encodePNG(image));await fs.writeFile(path.join(dir,'set/b.png'),encodePNG({...image,pixels:[...image.pixels].reverse()}));
  const xml='<set><tiles><tile name="a"/><tile name="b" weight="2.5"/></tiles><neighbors><neighbor left="a" right="a"/><neighbor left="a" right="b"/><neighbor left="b" right="b"/></neighbors><subsets><subset name="one"><tile name="a"/></subset></subsets></set>';
  await fs.writeFile(path.join(dir,'set.xml'),xml);const tiles=await loadTileset(path.join(dir,'set.xml'));assert.equal(tiles.tiles.length,2);assert.equal(tiles.tileSize,2);
  const subset=await loadTileset(path.join(dir,'set.xml'),{subset:'one'});assert.equal(subset.tiles.length,1);assert.deepEqual(subset.neighbors,[['a','a']]);
  await assert.rejects(loadTileset(path.join(dir,'set.xml'),{subset:'missing'}));
 });
 await group('Worker generation and actual tiled PNG rendering',async()=>{
  const job=await prepareJob({xml:'set.xml',width:24,height:20,seed:17},dir);const result=await execute(job);assert(result.ok,result.error);assert.equal(result.status,'solved');assert.equal(result.width,48);assert.equal(result.height,40);
  const target=path.join(dir,'tiled.png');await writeImage(target,result);const decoded=decodePNG(await fs.readFile(target));assert.deepEqual(decoded.pixels,result.pixels);
  const r=spawnSync('python',['-c',"from PIL import Image; import sys; im=Image.open(sys.argv[1]); assert im.size==(48,40); im.load(); print('ok')",target],{encoding:'utf8'});assert.equal(r.status,0,r.stderr);
 });
 await group('Cancellation timeout worker cleanup and next job',async()=>{
  const job={mode:'overlap',sample:[color(3,4,5)],sampleWidth:1,sampleHeight:1,size:1,width:128,height:128};
  const controller=new AbortController();const running=execute(job,{signal:controller.signal});controller.abort(Error('test cancellation'));await assert.rejects(running,/cancellation/);
  await assert.rejects(execute(job,{timeoutMs:1}),/timeout/);
  const result=await execute(job);assert(result.ok);assert.equal(result.pixels.length,16384);
 });
 await group('No-overwrite and atomic replacement policy',async()=>{
  const target=path.join(dir,'keep.png');await fs.writeFile(target,'original');await assert.rejects(writeImage(target,image));assert.equal(await fs.readFile(target,'utf8'),'original');
  await writeImage(target,image,{overwrite:true});assert.deepEqual(decodePNG(await fs.readFile(target)),image);
  assert(!(await fs.readdir(dir)).some(n=>n.endsWith('.tmp')));
 });
 await group('Real CLI file paths stdout and statuses',async()=>{
  const job=path.join(dir,'job.json');await fs.writeFile(job,JSON.stringify({xml:'set.xml',width:8,height:8,seed:42}));const target=path.join(dir,'cli.png');let r=invoke(['--job',job,'--out',target]);assert.equal(r.status,0,r.stderr);assert.equal(JSON.parse(r.stdout).image.path,target);
  r=invoke(['--job',job,'--out',target]);assert.equal(r.status,1);r=invoke(['--job',job,'--out',target,'--force']);assert.equal(r.status,0,r.stderr);
  const impossible={mode:'rules',model:{labels:['a'],weights:[1],neighbors:[[[],[],[],[]]]},width:2,height:1};r=invoke([],JSON.stringify(impossible));assert.equal(r.status,2);assert.equal(JSON.parse(r.stdout).status,'unsat');
  r=invoke([],JSON.stringify({...impossible,width:0}));assert.equal(r.status,1);
  assert.equal(invoke(['--help']).status,0);assert.equal(invoke(['--bad']).status,1);assert.equal(invoke([],Buffer.from([255])).status,1);
 });
 await group('Budget errors remain distinct from unsat',async()=>{
  const job={mode:'rules',model:{labels:['a','b'],neighbors:Array.from({length:2},()=>Array.from({length:4},()=>[0,1]))},width:32,height:32,budget:1};const r=await execute(job);assert.equal(r.ok,false);assert.match(r.error,/budget exhausted/);
  const oversized={mode:'overlap',sample:[1],sampleWidth:1,sampleHeight:1,width:65536,height:2,size:1};assert.equal((await execute(oversized)).ok,false);
 });
 await fs.writeFile(path.join(root,'evidence/runtime-validation.json'),JSON.stringify({runtime:process.version,platform:process.platform,groups,passed:groups.length},null,2)+'\n');console.log(groups.length+' PNG/XML/worker/CLI groups passed');
}finally{
 // Every descendant is created by this test in its unique temporary directory.
 const real=await fs.realpath(dir),base=await fs.realpath(os.tmpdir());assert(!path.relative(base,real).startsWith('..'));await fs.rm(real,{recursive:true,force:true});
}
