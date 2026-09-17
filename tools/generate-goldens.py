import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
report=json.loads((root/'evidence/upstream-comparison.json').read_text(encoding='utf8'))
assert report['mismatches']==0
lines=['// Generated from unmodified upstream C# model results.','///|','test "official overlapping and tiled model golden vectors" {','  let cases : Array[(String, String)] = [']
for row in report['cases']:
    ref=row['reference'];job=row['job'];n=len(ref['weights'])
    rules={'labels':[str(i)for i in range(n)]if row['kind']=='overlap' else ref['labels'],'neighbors':[[ref['propagator'][d][t]for d in [2,1,0,3]]for t in range(n)],'weights':ref['weights']}
    model={'size':job['size'],'patterns':ref['patterns'],'rules':rules}if row['kind']=='overlap' else {'rules':rules,'tiles':ref['tiles'],'tile_size':job['tileSize']}
    lines.append('    ('+json.dumps(json.dumps(job,separators=(',',':')))+', '+json.dumps(json.dumps({'ok':True,'model':model},separators=(',',':')))+'),')
lines.extend(['  ]','  for fixture in cases {','    let actual = @json.parse(@wfc.evaluate_json(fixture.0))','    assert_eq(actual, @json.parse(fixture.1))','  }','}'])
(root/'reference_golden_test.mbt').write_text('\n'.join(lines)+'\n',encoding='utf8',newline='\n')
print(len(report['cases']),'official model golden vectors')
