# Validation and reproduction · 0.4.0

## Routine checks

Use MoonBit 0.1.20260904 / moonc 0.10.12, Node 24.11.0 and Python 3.14.4 with Pillow 12.3.0 (the versions tested on Windows). Install only the locked Node dependencies:

```powershell
npm ci --ignore-scripts
python -m pip install Pillow==12.3.0
./verify.ps1 -MoonPath /absolute/path/to/moon.exe
```

The script runs fmt/info, warning-free check, explicit Wasm-GC and JS tests, rebuilds the actual browser engine, then checks legacy CLI/demo, official model replay, independent generation, capacity, PNG/XML/Worker/CLI, 307 malformed inputs and the small legacy benchmark. CI is prepared, not remotely executed.

- Both backends: 17 groups, including 266 official model goldens, exhaustive two-tile cases, pins, periodic seams, rollback and invalid inputs.
- `test-generation.mjs`: 384 three-tile models independently enumerated by Python; 6 successful backtracking cases. Twelve generated images are checked by all local windows and pixel pins; 16384 weighted draws check broad expected proportions (not exact output frequencies).
- `test-capacity.mjs`: 4096 unique patterns verified with a source-coordinate oracle, 65536 output cells and 65536 iterative search decisions, rejected excessive patterns/states and dominant-weight removal. This is not an upstream >256-color compatibility claim.
- `test-runtime.mjs`: 9 groups. PNG CRC/bounds, independent Pillow RGB/RGBA/palette/1-bit/gray/16-bit imports, Unicode palette, XML/subset/file checks, workers/cancel/timeout, actual CLI, error statuses and atomic no-overwrite output.
- `browser-validation.json`: 8 actual UI groups. Saved PNG was found on disk and all 2304 pixels matched the engine; the browser download-event hook itself timed out. Initial malformed HTML was fixed before acceptance actions. Desktop/390px layout, local import, cancel/recovery, unsat and JSON errors were checked.

## Independent official comparison

Reference commit: `de7d22e705e816b62b4d613199d0463820fcaef3`, from mxgmn/WaveFunctionCollapse. Production MoonBit code never loads this reference. Original test harnesses use unchanged Model.cs, OverlappingModel.cs, SimpleTiledModel.cs and Helper.cs; source hashes are archived. The upstream project targets .NET 10; this Windows reproduction compiles its unchanged core against .NET 9.0.13 using Roslyn 4.12 and ImageSharp 3.1.12. Runtime adaptation is explicit.

```powershell
./tools/build-reference.ps1 -Directory C:/temp/wfc-reference
python tools/reference-fixtures.py C:/temp/wfc-reference
node tools/compare-reference.mjs C:/temp/wfc-reference
node tools/benchmark-reference.mjs C:/temp/wfc-reference
```

The build script requires Windows .NET Framework and .NET 9.0.13 runtime. It downloads fixed official source/package URLs and checks archived SHA256 for the four source files and both NuGet packages. Reference dependencies and their licenses remain outside the production repo. The fixture generator uses Pillow and creates original images/XML, not upstream assets.

266/266 model comparisons match: 121 overlapping cases (different sample shapes, N, symmetry and periodic input), 145 tiled cases (all symmetry pairs/orientations plus unique direction bitmaps). Compared values are exact patterns, weights, adjacency, labels and oriented pixels. 1264 zero-neighbor warnings from intentionally sparse official tiled fixtures remain in the capture; they are not evidence those graphs generate solvable images.

`check-reference.mjs` replays captured official expectations offline. `generate-goldens.py` uses reference output only, not the local actual field. Regenerate with `python tools/generate-goldens.py`, then `moon fmt`; rerunning both must be byte-idempotent. `exhaustive-oracle.py` regenerates the independent small-model satisfiability cases.

## Representative same-host timing

`reference-performance.json` records 2 warmups and 7 measured runs for each of four original sample/size combinations. Every successful local and official image is checked against the official pattern set. All 28 measured outputs from each implementation solved. Measured median milliseconds:

| Case | Patterns | Output | Local JS | Reference C# |
|---|---:|---:|---:|---:|
| Archipelago N=3 | 246 | 64×64 | 436.87 | 377.66 |
| Archipelago N=4 | 609 | 48×48 | 556.05 | 479.74 |
| Unique-color N=2 | 64 | 128×128 | 466.25 | 353.49 |
| Island N=3 | 25 | 128×128 | 183.53 | 112.16 |

Same i7-14700HX Windows host, sequential processes. Local timing includes JSON, learning, solving and pixel rendering; C# timing includes constructor/Run but excludes PNG save and reflection. RNG, backtracking and boundary-wave representation differ. This is useful workload evidence, not identical-work, memory, cross-platform or full performance parity proof. The older `benchmark.json` is only a tiny legacy example.

## Provenance and preservation

`scalable-upgrade.json` binds current source/API/engine and evidence to Git blob hashes; after committing, `python tools/check-proof.py` verifies them. The manifest excludes itself to avoid a hash cycle. The baseline and older evidence remain historical snapshots, not current all-feature acceptance. Archives, sibling projects and remote CI are not updated by these checks.
