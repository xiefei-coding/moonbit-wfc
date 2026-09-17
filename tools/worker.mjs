import {parentPort} from 'node:worker_threads';import {request} from '../web/engine.mjs';
parentPort.once('message',job=>{try{parentPort.postMessage({result:JSON.parse(request(JSON.stringify(job)))})}catch(error){parentPort.postMessage({error:String(error.message||error)})}});
