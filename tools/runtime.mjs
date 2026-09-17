import {Worker} from 'node:worker_threads';import fs from 'node:fs/promises';import path from 'node:path';import {randomUUID} from 'node:crypto';import {readPNG,encodePNG} from './images.mjs';import {loadTileset} from './tileset.mjs';
export async function prepareJob(job,baseDir=process.cwd()){
 if(!job||typeof job!=='object'||Array.isArray(job))throw Error('Expected job object');
 const result={...job};delete result.png;delete result.xml;delete result.imageDir;delete result.palette;
 if(job.png){if(typeof job.png!=='string')throw Error('png must be a path');const image=await readPNG(path.resolve(baseDir,job.png));Object.assign(result,{sample:image.pixels,sampleWidth:image.width,sampleHeight:image.height})}
 else if(typeof job.sample==='string'){const rows=job.sample.replaceAll('\r\n','\n').replace(/\n$/,'').split('\n').map(row=>Array.from(row));if(!rows.length||!rows[0].length||rows.some(r=>r.length!==rows[0].length))throw Error('Sample rows must be nonempty and equal width');const palette=job.palette;if(!palette||typeof palette!=='object'||Array.isArray(palette))throw Error('String samples require a palette of signed ARGB32 colors; use tools/overlap.mjs for symbols');const pixels=rows.flatMap(r=>r.map(c=>{const v=palette[c];if(!Object.hasOwn(palette,c)||!Number.isInteger(v)||v< -2147483648||v>2147483647)throw Error('Missing or invalid palette color for '+c);return v}));Object.assign(result,{sample:pixels,sampleWidth:rows[0].length,sampleHeight:rows.length})}
 if(job.xml){if(typeof job.xml!=='string')throw Error('xml must be a path');Object.assign(result,await loadTileset(path.resolve(baseDir,job.xml),{subset:job.subset,imageDir:job.imageDir?path.resolve(baseDir,job.imageDir):undefined}));delete result.subset;result.mode=job.mode==='expand'?'expand':'tiled'}
 return result;
}
export function execute(job,{timeoutMs=30000,signal}={}){
 if(!Number.isInteger(timeoutMs)||timeoutMs<1||timeoutMs>300000)throw Error('timeoutMs must be 1..300000');
 if(signal?.aborted)return Promise.reject(signal.reason??Error('Aborted'));
 return new Promise((resolve,reject)=>{
  const worker=new Worker(new URL('./worker.mjs',import.meta.url),{resourceLimits:{maxOldGenerationSizeMb:512}});let settled=false;
  const finish=async(error,value)=>{if(settled)return;settled=true;clearTimeout(timer);signal?.removeEventListener('abort',abort);await worker.terminate();error?reject(error):resolve(value)};
  const abort=()=>finish(signal.reason??Error('Aborted'));const timer=setTimeout(()=>finish(Error('Generation timeout')),timeoutMs);
  signal?.addEventListener('abort',abort,{once:true});worker.once('error',error=>finish(error));worker.once('exit',code=>{if(!settled)finish(Error('Worker exited without a result: '+code))});
  worker.once('message',message=>finish(message.error?Error(message.error):null,message.result));
  try{worker.postMessage(job)}catch(error){finish(error)}
 });
}
export async function writeImage(file,result,{overwrite=false}={}){
 const bytes=encodePNG(result);const target=path.resolve(file);await fs.mkdir(path.dirname(target),{recursive:true});const temporary=path.join(path.dirname(target),'.wfc-'+randomUUID()+'.tmp');
 const handle=await fs.open(temporary,'wx');
 try{try{await handle.writeFile(bytes);await handle.sync()}finally{await handle.close()}
  if(overwrite)await fs.rename(temporary,target);else{await fs.link(temporary,target);await fs.unlink(temporary)}
 }catch(error){await fs.unlink(temporary).catch(()=>{});throw error}
 return {path:target,bytes:bytes.length};
}
