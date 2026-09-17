import fs from 'node:fs/promises';import path from 'node:path';import {DOMParser} from '@xmldom/xmldom';import {readPNG} from './images.mjs';
const cardinalities={X:1,I:2,'\\':2,L:4,T:4,F:8};
const elements=(node,name)=>Array.from(node.childNodes).filter(n=>n.nodeType===1&&n.tagName===name);
const required=(node,key)=>{const value=node.getAttribute(key);if(value===null||value==='')throw Error('Missing XML attribute '+key);return value};
export function parseTileset(xml,{subset}={}){
 if(typeof xml!=='string'||Buffer.byteLength(xml)>2097152||/<!DOCTYPE|<!ENTITY/i.test(xml))throw Error('XML DTD/entities or input size not allowed');
 const errors=[];const doc=new DOMParser({onError:(level,message)=>errors.push(level+': '+message)}).parseFromString(xml,'application/xml');
 if(errors.length||doc.documentElement?.tagName!=='set')throw Error('Invalid tileset XML: '+errors.join('; '));
 const root=doc.documentElement,containers=elements(root,'tiles');if(containers.length!==1)throw Error('Expected one tiles section');
 const known=new Set(),tiles=elements(containers[0],'tile').map(node=>{const name=required(node,'name'),symmetry=node.getAttribute('symmetry')??'X',weight=Number(node.getAttribute('weight')??1);if(!/^[^\s/\\.:]+$/.test(name)||known.has(name)||!Object.hasOwn(cardinalities,symmetry)||!Number.isFinite(weight)||weight<=0||weight>1e6)throw Error('Invalid tile name, symmetry or weight');known.add(name);return {name,symmetry,weight}});
 if(!tiles.length||tiles.length>4096)throw Error('Tile count limit');
 let selected=[];if(subset!==undefined){const sections=elements(root,'subsets');const matches=sections.flatMap(s=>elements(s,'subset')).filter(n=>n.getAttribute('name')===subset);if(matches.length!==1)throw Error('Unknown or ambiguous subset');selected=elements(matches[0],'tile').map(t=>required(t,'name'));if(!selected.length||selected.some(n=>!known.has(n)))throw Error('Empty or invalid subset')}
 const neighbors=elements(root,'neighbors').flatMap(n=>elements(n,'neighbor')).map(n=>[required(n,'left'),required(n,'right')]);
 if(neighbors.length>100000)throw Error('Neighbor count limit');
 for(const pair of neighbors)for(const text of pair){const parts=text.trim().split(/\s+/);if(parts.length>2||!known.has(parts[0])||parts.length===2&&!/^[0-7]$/.test(parts[1]))throw Error('Unknown tile or invalid neighbor orientation')}
 const unique=root.getAttribute('unique');if(unique!==null&&!['true','false'].includes(unique))throw Error('unique must be true or false');
 return {tiles,neighbors,subset:selected,unique:unique==='true'};
}
export async function loadTileset(file,options={}){
 const stat=await fs.stat(file);if(stat.size>2097152)throw Error('XML exceeds 2 MiB');
 const xml=new TextDecoder('utf-8',{fatal:true}).decode(await fs.readFile(file));
 const parsed=parseTileset(xml,options);
 const imageDir=await fs.realpath(options.imageDir??path.join(path.dirname(file),path.basename(file,path.extname(file))));
 let tileSize,totalPixels=0;const tiles=[];
 for(const tile of parsed.tiles){
  if(parsed.subset.length&&!parsed.subset.includes(tile.name))continue;
  const count=parsed.unique?cardinalities[tile.symmetry]:1,pixels=[];
  for(let i=0;i<count;i++){
   const target=await fs.realpath(path.join(imageDir,tile.name+(parsed.unique?' '+i:'')+'.png'));
   const relative=path.relative(imageDir,target);if(relative.startsWith('..')||path.isAbsolute(relative))throw Error('Tile image escapes its directory');
   const image=await readPNG(target,{maxPixels:65536});if(image.width!==image.height||image.width>256||tileSize!==undefined&&image.width!==tileSize)throw Error('Tile PNGs must have the same square dimensions');tileSize=image.width;totalPixels+=image.pixels.length;if(totalPixels>4000000)throw Error('Tile bitmap budget');pixels.push(image.pixels);
  }
  tiles.push({...tile,pixels});
 }
 // Remove excluded neighbors before sending the selected definitions to the core.
 const names=new Set(tiles.map(t=>t.name));
 return {tiles,tileSize,neighbors:parsed.neighbors.filter(([l,r])=>names.has(l.trim().split(/\s+/)[0])&&names.has(r.trim().split(/\s+/)[0]))};
}
