import fs from 'node:fs/promises';import path from 'node:path';import {prepareJob,execute,writeImage} from './runtime.mjs';
try{
 const args=process.argv.slice(2);let file,output,overwrite=false,timeoutMs=30000;
 for(let i=0;i<args.length;i++){const a=args[i];if(a==='--help'){console.log('Usage: node tools/generate.mjs --job FILE [--out PNG] [--force] [--timeout MS]\nNo --job: UTF-8 JSON from stdin. Modes: overlap, learn, tiled, expand, rules, validate. Input pixels are signed ARGB32. Paths are relative to the job file. Exit: 0 solved, 2 unsat, 1 error.');process.exit(0)}else if(a==='--force')overwrite=true;else if(['--job','--out','--timeout'].includes(a)){if(++i>=args.length)throw Error('Missing '+a);if(a==='--job'){if(file)throw Error('Duplicate job');file=args[i]}else if(a==='--out')output=args[i];else timeoutMs=Number(args[i])}else throw Error('Unknown option '+a)}
 let bytes;if(file){if((await fs.stat(file)).size>16777216)throw Error('Job exceeds 16 MiB');bytes=await fs.readFile(file)}else{const chunks=[];let size=0;for await(const chunk of process.stdin){size+=chunk.length;if(size>16777216)throw Error('Job exceeds 16 MiB');chunks.push(chunk)}bytes=Buffer.concat(chunks)}
 const job=await prepareJob(JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(bytes)),file?path.dirname(path.resolve(file)):process.cwd());
 const result=await execute(job,{timeoutMs});if(!result.ok)throw Error(result.error);
 if(output){if(result.status==='solved'&&result.pixels){result.image=await writeImage(output,result,{overwrite});delete result.pixels}else if(result.status!=='unsat')throw Error('--out requires image generation')}
 await new Promise((resolve,reject)=>process.stdout.write(JSON.stringify(result)+'\n',error=>error?reject(error):resolve()));process.exitCode=result.status==='unsat'?2:0;
}catch(error){process.stderr.write(JSON.stringify({ok:false,error:String(error.message||error)})+'\n');process.exitCode=1}
