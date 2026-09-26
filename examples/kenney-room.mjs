import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
import {readPNG} from '../tools/images.mjs';
import {execute,writeImage} from '../tools/runtime.mjs';
const source=fileURLToPath(new URL('./kenney-room/',import.meta.url));
export async function roomJob(){
  const provenance=JSON.parse(await fs.readFile(path.join(source,'SOURCE.json'),'utf8'));
  for(const [name,digest] of Object.entries(provenance.files)){
    if(createHash('sha256').update(await fs.readFile(path.join(source,name))).digest('hex')!==digest)throw Error('asset hash mismatch: '+name);
  }
  const definitions=[['wall','tile_0037.png',1],['floor','tile_0048.png',5],['detail-a','tile_0049.png',1],['detail-b','tile_0050.png',1]];
  const tiles=[];
  for(const [name,file,weight] of definitions){const image=await readPNG(path.join(source,file));if(image.width!==16||image.height!==16)throw Error('expected original 16px tiles');tiles.push({name,weight,symmetry:'X',pixels:[image.pixels]});}
  // Original example contract: detail tiles may not touch another detail tile
  // on any cardinal edge. Symmetry X generates reciprocal E/S/W/N constraints.
  const neighbors=[];
  for(let a=0;a<4;a++)for(let b=0;b<4;b++)if(!(a>=2&&b>=2))neighbors.push([tiles[a].name,tiles[b].name]);
  const width=32,height=24,row=12,entrances=[row*width,row*width+width-1],pins=[],restrictions=[];
  for(let y=0;y<height;y++)for(let x=0;x<width;x++){
    const cell=y*width+x;
    if(entrances.includes(cell))pins.push([cell,1]);
    else if(!x||!y||x===width-1||y===height-1)pins.push([cell,0]);
    else restrictions.push([cell,[1,2,3]]);
  }
  return {mode:'tiled',width,height,tileSize:16,tiles,neighbors,pins,restrictions,periodic:false,seed:20260927,budget:2_000_000};
}

export async function generateRoom(output){
  const job=await roomJob(),result=await execute(job);
  if(!result.ok||result.status!=='solved')throw Error('room generation failed: '+JSON.stringify(result));
  await fs.mkdir(output,{recursive:false});
  await writeImage(path.join(output,'room.png'),result);
  const map={width:job.width,height:job.height,tiles:result.solution.tiles,
    tileFiles:['tile_0037.png','tile_0048.png','tile_0049.png','tile_0050.png'],seed:job.seed,
    decisions:result.solution.decisions,backtracks:result.solution.backtracks,
    source:'Kenney Tiny Dungeon 1.0 CC0; original example constraints',
    task:'room floor variation, boundary walls and two entrance gaps; not a full dungeon or gameplay certification'};
  await fs.writeFile(path.join(output,'map.json'),JSON.stringify(map,null,2)+'\n',{flag:'wx'});
  await fs.writeFile(path.join(output,'job.json'),JSON.stringify(job)+'\n',{flag:'wx'});
  const digest=createHash('sha256').update(await fs.readFile(path.join(output,'room.png'))).digest('hex');
  await fs.writeFile(path.join(output,'manifest.json'),JSON.stringify({complete:true,pngSha256:digest,assetSource:'examples/kenney-room/SOURCE.json',seed:job.seed,budget:job.budget},null,2)+'\n',{flag:'wx'});
  return {output,pixels:[result.width,result.height],pngSha256:digest,decisions:result.solution.decisions};
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  if(!process.argv[2])throw Error('Usage: node examples/kenney-room.mjs NEW_DIRECTORY');
  console.log(JSON.stringify(await generateRoom(process.argv[2])));
}
