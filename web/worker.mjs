import {request} from './engine.mjs';
self.onmessage=event=>{try{self.postMessage(JSON.parse(request(JSON.stringify(event.data))))}catch(error){self.postMessage({ok:false,error:String(error.message||error)})}};
