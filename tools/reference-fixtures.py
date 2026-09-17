"""Original image/XML inputs for independent reference comparison. Requires Pillow."""
import json,sys
from pathlib import Path
from PIL import Image
dest=Path(sys.argv[1]).resolve();dest.mkdir(parents=True,exist_ok=True)
(dest/'samples').mkdir(exist_ok=True);(dest/'tilesets').mkdir(exist_ok=True)
cases=[]
def bitmap(path,rows,palette):
    image=Image.new('RGBA',(len(rows[0]),len(rows)))
    image.putdata([palette[x] for row in rows for x in row]);image.save(path)
palette=[(29,57,69,255),(220,193,125,255),(113,159,109,255),(74,107,70,255)]
samples={
 'checker':[[0,1,0,1],[1,0,1,0],[0,1,0,1],[1,0,1,0]],
 'stripes':[[0,0,1,1],[0,0,1,1],[0,0,1,1],[0,0,1,1]],
 'island':[[0,0,0,0,0],[0,1,1,1,0],[0,1,2,1,0],[0,1,1,1,0],[0,0,0,0,0]],
 'asymmetric':[[0,1,2],[3,1,0],[2,3,3]],
 'frequency':[[0,0,0,1],[0,0,0,1],[0,0,1,1],[0,1,1,1]],
}
for name,rows in samples.items():
    bitmap(dest/'samples'/f'{name}.png',rows,palette)
    for size in [1,2,3]:
      for periodic in [False,True]:
       for symmetry in [1,2,4,8]:
        cases.append({'name':f'{name}-{size}-{periodic}-{symmetry}','reference':{'kind':'overlap','name':name,'size':size,'periodicInput':periodic,'periodic':False,'symmetry':symmetry,'width':8,'height':8},'job':{'mode':'learn','png':f'samples/{name}.png','size':size,'periodicInput':periodic,'symmetry':symmetry}})
# More than 30 learned patterns and three hundred colors are independent cases.
unique=[[(x+y*8) for x in range(8)]for y in range(8)]
colors=[(i*3,255-i*3,i*2,255)for i in range(64)];bitmap(dest/'samples/unique64.png',unique,colors)
cases.append({'name':'unique64','reference':{'kind':'overlap','name':'unique64','size':2,'periodicInput':True,'periodic':True,'symmetry':1,'width':16,'height':16,'seed':13},'job':{'mode':'learn','png':'samples/unique64.png','size':2,'periodicInput':True,'symmetry':1}})
syms=['X','I','\\','L','T','F']
for ia,sa in enumerate(syms):
 for ib,sb in enumerate(syms):
  for orientation in [0,1,4,7]:
   name=f'tiles-{ia}-{ib}-{orientation}';folder=dest/'tilesets'/name;folder.mkdir(exist_ok=True)
   bitmap(folder/'a.png',[[0,1],[2,3]],palette);bitmap(folder/'b.png',[[3,2],[1,0]],palette)
   xml=f'<set><tiles><tile name="a" symmetry="{sa}" weight="1.5"/><tile name="b" symmetry="{sb}" weight="3"/></tiles><neighbors><neighbor left="a {orientation}" right="b 1"/><neighbor left="b 2" right="a 0"/></neighbors><subsets><subset name="all"><tile name="a"/><tile name="b"/></subset></subsets></set>'
   (dest/'tilesets'/f'{name}.xml').write_text(xml,encoding='utf8')
   cases.append({'name':name,'reference':{'kind':'tiled','name':name,'periodic':False,'width':4,'height':4,'subset':'all'},'job':{'mode':'expand','xml':f'tilesets/{name}.xml','subset':'all'}})
name='unique-orientations';folder=dest/'tilesets'/name;folder.mkdir(exist_ok=True)
for i in range(8):bitmap(folder/f'piece {i}.png',[[i%4,(i+1)%4],[(i+2)%4,(i+3)%4]],palette)
(dest/'tilesets'/f'{name}.xml').write_text('<set unique="true"><tiles><tile name="piece" symmetry="F"/></tiles><neighbors><neighbor left="piece" right="piece 1"/></neighbors></set>')
cases.append({'name':name,'reference':{'kind':'tiled','name':name,'periodic':False,'width':4,'height':4},'job':{'mode':'expand','xml':f'tilesets/{name}.xml'}})
(dest/'cases.json').write_text(json.dumps(cases,indent=2)+'\n')
print(len(cases),'original reference cases')
