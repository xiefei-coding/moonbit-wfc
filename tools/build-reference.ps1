param([Parameter(Mandatory=$true)][string]$Directory)
$ErrorActionPreference='Stop'
$target=[IO.Path]::GetFullPath($Directory)
$repo=Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Path $target -Force | Out-Null
$commit='de7d22e705e816b62b4d613199d0463820fcaef3'
$capture=Get-Content (Join-Path $repo 'evidence/upstream-comparison.json') -Raw | ConvertFrom-Json
foreach($name in @('Model.cs','OverlappingModel.cs','SimpleTiledModel.cs','Helper.cs','LICENSE','WaveFunctionCollapse.csproj')) {
  $file=Join-Path $target $name
  if (-not (Test-Path -LiteralPath $file)) { Invoke-WebRequest "https://raw.githubusercontent.com/mxgmn/WaveFunctionCollapse/$commit/$name" -OutFile $file }
  $expected=$capture.sourceSHA256.$name
  if ($expected -and (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) {throw "Reference source hash mismatch: $name"}
}
Set-Content (Join-Path $target 'commit.txt') $commit -Encoding utf8
$packages=@(
  @{Name='microsoft.net.compilers.toolset';Version='4.12.0';Hash='fe24ef31a6ffcb7c49383d2fd362763dee291ad9b9d98cc0c19ef80203b99ebc'},
  @{Name='sixlabors.imagesharp';Version='3.1.12';Hash='151f2fef8c383ffd4065d5b90115b4cbcce00ea2edbe1c5098bd422afebcc51d'}
)
foreach($package in $packages) {
  $file=Join-Path $target ($package.Name+'.nupkg')
  $url="https://api.nuget.org/v3-flatcontainer/$($package.Name)/$($package.Version)/$($package.Name).$($package.Version).nupkg"
  if (-not (Test-Path -LiteralPath $file)) {Invoke-WebRequest $url -OutFile $file}
  if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $package.Hash) {throw "Package hash mismatch: $($package.Name)"}
  $unpacked=Join-Path $target $package.Name
  if (-not (Test-Path -LiteralPath $unpacked)) {[IO.Compression.ZipFile]::ExtractToDirectory($file,$unpacked)}
  @{version=$package.Version;url=$url;sha256=$package.Hash} | ConvertTo-Json | Set-Content (Join-Path $target ($package.Name+'.json')) -Encoding utf8
}
$runtime=Join-Path $env:ProgramFiles 'dotnet/shared/Microsoft.NETCore.App/9.0.13'
if (-not (Test-Path -LiteralPath $runtime)) {throw 'This reproduction requires Windows .NET runtime 9.0.13 and .NET Framework for Roslyn csc.exe.'}
$imageDll=Join-Path $target 'sixlabors.imagesharp/lib/net6.0/SixLabors.ImageSharp.dll'
Copy-Item -LiteralPath $imageDll -Destination (Join-Path $target 'SixLabors.ImageSharp.dll') -Force
$references=@()
foreach($file in Get-ChildItem -LiteralPath $runtime -Filter '*.dll' -File) {
  try { $null=[Reflection.AssemblyName]::GetAssemblyName($file.FullName);$references+=('-r:"'+$file.FullName+'"') } catch [System.BadImageFormatException] {}
}
foreach($item in @(@{Name='oracle';Source='ReferenceOracle.cs'},@{Name='reference-benchmark';Source='ReferenceBenchmark.cs'})) {
  $harness=if ($item.Name -eq 'oracle') {'Oracle.cs'} else {'ReferenceBenchmark.cs'}
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot $item.Source) -Destination (Join-Path $target $harness) -Force
  $lines=@('-nostdlib+','-nologo','-unsafe','-target:exe',('-out:"'+(Join-Path $target ($item.Name+'.dll'))+'"'))+$references+@('-r:"'+$imageDll+'"')
  foreach($source in @('Model.cs','OverlappingModel.cs','SimpleTiledModel.cs','Helper.cs',$harness)) {$lines+='"'+(Join-Path $target $source)+'"'}
  $response=Join-Path $target ($item.Name+'.rsp')
  $lines | Set-Content -LiteralPath $response -Encoding utf8
  & (Join-Path $target 'microsoft.net.compilers.toolset/tasks/net472/csc.exe') /noconfig "@$response"
  if ($LASTEXITCODE -ne 0) {throw 'Reference harness compilation failed'}
  '{"runtimeOptions":{"tfm":"net9.0","framework":{"name":"Microsoft.NETCore.App","version":"9.0.13"}}}' | Set-Content (Join-Path $target ($item.Name+'.runtimeconfig.json')) -Encoding utf8
}
Write-Host "Built unchanged upstream models with local harnesses in $target"
