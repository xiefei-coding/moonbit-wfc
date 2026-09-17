import fs from 'node:fs/promises';
import {PNG} from 'pngjs';
export function decodePNG(bytes,{maxPixels=262144}={}){
 if(bytes.length>16777216||bytes.length<33||!bytes.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10]))||bytes.toString('ascii',12,16)!=='IHDR')throw Error('Invalid or oversized PNG');
 const width=bytes.readUInt32BE(16),height=bytes.readUInt32BE(20);
 if(!width||!height||width*height>maxPixels)throw Error('PNG dimensions exceed pixel limit');
 const png=PNG.sync.read(bytes,{checkCRC:true});
 const pixels=Array.from({length:width*height},(_,i)=>{const o=i*4;return (png.data[o+3]<<24)|(png.data[o]<<16)|(png.data[o+1]<<8)|png.data[o+2]});
 return {width,height,pixels};
}
export async function readPNG(file,options){const stat=await fs.stat(file);if(stat.size>16777216)throw Error('PNG exceeds 16 MiB');return decodePNG(await fs.readFile(file),options)}
export function encodePNG({width,height,pixels}){
 if(!Number.isInteger(width)||!Number.isInteger(height)||width<1||height<1||width*height>4000000||!Array.isArray(pixels)||pixels.length!==width*height)throw Error('Invalid output image dimensions');
 const data=Buffer.alloc(width*height*4);
 for(let i=0;i<pixels.length;i++){const c=pixels[i];if(!Number.isInteger(c)||c<-2147483648||c>2147483647)throw Error('Pixel must be signed ARGB32');const o=i*4;data[o]=c>>>16&255;data[o+1]=c>>>8&255;data[o+2]=c&255;data[o+3]=c>>>24}
 return PNG.sync.write({width,height,data},{colorType:6,inputColorType:6,bitDepth:8});
}
