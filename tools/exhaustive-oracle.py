"""Independent exhaustive CSP enumerator; never calls either WFC implementation."""
import random,itertools,json
from pathlib import Path
rng=random.Random(20260917);cases=[]
for index in range(384):
 n=3;width=2;height=2 if index<320 else 3;periodic=index%3==0
 east=rng.randrange(512);south=rng.randrange(512)
 allowed=[[[b for b in range(n)if east>>(a*n+b)&1],[b for b in range(n)if south>>(a*n+b)&1],[b for b in range(n)if east>>(b*n+a)&1],[b for b in range(n)if south>>(b*n+a)&1]]for a in range(n)]
 pins=[[0,index%n]]if index%2 else []
 found=None
 for tiles in itertools.product(range(n),repeat=width*height):
  if any(tiles[c]!=t for c,t in pins):continue
  good=True
  for y in range(height):
   for x in range(width):
    a=tiles[y*width+x]
    if x+1<width or periodic:
     if not east>>(a*n+tiles[y*width+(x+1)%width])&1:good=False
    if y+1<height or periodic:
     if not south>>(a*n+tiles[(y+1)%height*width+x])&1:good=False
  if good:found=list(tiles);break
 cases.append({'mode':'rules','model':{'labels':['0','1','2'],'weights':[1,2.5,4],'neighbors':allowed},'width':width,'height':height,'seed':index+1,'periodic':periodic,'pins':pins,'expectedSatisfiable':found is not None,'oracleWitness':found})
root=Path(__file__).resolve().parents[1]
(root/'tools/exhaustive-cases.json').write_text(json.dumps(cases,indent=2)+'\n',encoding='utf8',newline='\n')
print(len(cases),'independent three-tile exhaustive cases')
