"""Independent PNG pixels, explicit adjacency/pins and entrance BFS validation."""
import argparse
from pathlib import Path
from collections import deque,Counter
import json,hashlib
from PIL import Image

parser=argparse.ArgumentParser();parser.add_argument('directory');parser.add_argument('--evidence',default='evidence/kenney-reference.json');args=parser.parse_args()
root=Path(__file__).resolve().parents[1];directory=Path(args.directory)
data=json.loads((directory/'map.json').read_text(encoding='utf-8'));w,h=data['width'],data['height'];tiles=data['tiles']
assert (w,h)==(32,24) and len(tiles)==w*h
entrances={12*w,12*w+w-1}
for y in range(h):
 for x in range(w):
  cell=y*w+x;t=tiles[cell];assert t in range(4)
  if cell in entrances:assert t==1
  elif x in (0,w-1) or y in (0,h-1):assert t==0
  else:assert t in (1,2,3)
  for dx,dy in [(1,0),(0,1)]:
   if x+dx<w and y+dy<h:assert not(t>=2 and tiles[(y+dy)*w+x+dx]>=2)
start=min(entrances);seen={start};queue=deque([start])
while queue:
 cell=queue.popleft();x,y=cell%w,cell//w
 for dx,dy in [(1,0),(-1,0),(0,1),(0,-1)]:
  nx,ny=x+dx,y+dy
  if 0<=nx<w and 0<=ny<h:
   n=ny*w+nx
   if tiles[n]!=0 and n not in seen:seen.add(n);queue.append(n)
assert seen=={i for i,t in enumerate(tiles) if t!=0} and entrances<=seen
image=Image.open(directory/'room.png').convert('RGBA');assert image.size==(w*16,h*16)
sprites=[Image.open(root/'examples/kenney-room'/name).convert('RGBA') for name in data['tileFiles']]
for i,t in enumerate(tiles):
 x,y=i%w*16,i//w*16
 assert image.crop((x,y,x+16,y+16)).tobytes()==sprites[t].tobytes(),i
receipt=dict(grid=[w,h],image=list(image.size),tiles=len(tiles),pixels=w*h*256,counts=dict(Counter(tiles)),walkableConnected=len(seen),entrances=sorted(entrances),pngSha256=hashlib.sha256((directory/'room.png').read_bytes()).hexdigest(),oracle='Python/Pillow exact sprite reconstruction; explicit edge rules and independent BFS',limits=['room floor example, not gameplay validation','original adjacency rules, Kenney supplies art only'])
out=Path(args.evidence);out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8');print(json.dumps(receipt,indent=2))
