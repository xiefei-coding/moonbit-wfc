# WFC 图案工坊 · 0.4.0

> 2026-09-21 本地构建修复：命令包 import 已同步到当前 moon.mod 模块名；moon info/check、JS 构建、MoonBit 示例和 Node 引擎示例通过。算法未改，本轮未重跑历史全部行为/性能套件。当前提交指纹见 evidence/module-import-fix.json。

独立 MoonBit 实现：从 PNG 学习重叠图案，或从瓦片 XML 读取对称与邻接规则，生成可复现的像素图。支持加权熵、传播、迭代回溯、预设格、周期边界，以及可取消的网页与 Node 任务。当前是本地候选版，尚未完成全部上游兼容或性能追平。

## 直接使用

网页附带实际编译的 MoonBit 引擎，不需要安装编译器或 Node 依赖：

```powershell
./start-review.ps1
```

打开 http://127.0.0.1:8778/web/ ，选择示例或导入 PNG，然后生成、取消或保存结果。图像处理留在本机。窄屏布局与实际 PNG 下载已检查。

Node 24 文件入口需要安装锁定的 PNG/XML 解析依赖：

```sh
npm ci --ignore-scripts
node tools/generate.mjs --job examples/islands.json --out generated-islands.png
node tools/generate.mjs --job examples/paths.json --out generated-paths.png
```

输出文件默认不得已存在；显式 `--force` 才替换。`--timeout 30000` 是默认任务期限，最大 300000 ms。没有 `--job` 时读取 UTF-8 JSON 标准输入。路径相对任务文件；`--out` 相对当前目录。退出码 0 为成功、2 为无解、1 为输入/预算/超时/文件错误。无解和预算耗尽是不同结果。

[群岛输入](examples/islands.png)、[群岛输出](examples/islands-output.png)、[XML 路径瓦片输出](examples/paths-output.png)均为本项目原创示例。

## 任务与公开 API

| 入口 | 用途 |
|---|---|
| `learn_patterns` / JSON `learn` | 学习整数颜色图案、频率和显式邻接 |
| `PatternModel.generate` / `overlap` | 重叠模型生成、像素 pins、周期与 ground |
| `expand_tiles` / `expand` | X、I、\、L、T、F 对称、定向邻接和 unique 位图 |
| `solve_rules` / `rules` | 显式四方向邻接、浮点权重、格子 pins；MoonBit API 还支持候选集合 restrictions |
| `Solution.validate_rules` / `validate` | 核验尺寸、每格瓦片、pins 与全部四方向边 |
| `TiledModel.render` / `tiled` | 按瓦片位图拼接像素结果 |

JSON 参数采用 `sampleWidth`、`sampleHeight`、`periodicInput`、`tileSize` 等 camelCase；生成结果像素为有符号 ARGB32 整数。`symmetry` 是 1..8 的变换数量；旧字符 API 使用 Bool，不能混用。示例任务展示 `png` 和 `xml` 文件形式。数值 `sample` 可直接传像素数组；字符串 `sample` 必须给 `palette`，将每个 Unicode 字符映射到有符号 ARGB32，避免输出透明字符码。

XML 路径默认是 `name.xml` 对应的 `name/` 目录，普通瓦片读取 `tile.png`，`unique="true"` 读取 `tile 0.png` 等方向位图。支持 `weight`、`symmetry`、`neighbors` 和具名 `subset`。文件名、图像尺寸、未知邻接、实体/DTD 等输入会检查。完整批任务 `samples.xml` 尚未支持。

`pins` 是 `[索引,值]` 数组：`overlap` 中索引属于最终输出像素，值为颜色；`rules/tiled` 中索引属于求解格，值为展开后的瓦片 ID。重叠像素 pin 会限制所有覆盖它的图案，包括边缘与周期接缝。

旧 `Model` / `solve` 与 `learn_overlap` / `tools/overlap.mjs` 保留：位掩码模型仍最多 30 瓦片，旧学习器最多 30 图案。新路径使用 `RuleModel` / `learn_patterns`，已移除该限制。种子 0 归一为 1；同一版本、输入、种子可复现，不承诺不同版本或上游种子输出相同。

## 资源边界

- 显式模型最多 4096 瓦片/图案，四方向邻接共 4000000 条；必须互为逆向且没有重复邻居。权重有限、正数且不超过 1000000。
- 求解最多 65536 格，格数 × 瓦片数最多 2000000。4096 图案与最大输出尺寸不能同时取满。
- 学习图案边长 1..8；输入每边最多 1024、总计 262144 像素；变换累计工作最多 32000000 像素单元。
- 重叠输出最多 65536 像素。非周期求解格为 `(width-size+1) × (height-size+1)`，仍重建完整右、下边缘。瓦片渲染最多 4000000 像素，单瓦片边长最多 256。
- PNG 输入最多 16 MiB；XML 最多 2 MiB；CLI JSON 最多 16 MiB（核心字符串入口为 16000000 个 UTF-16 单元）。Node Worker 默认 30 秒且限制旧生代堆；计算预算不是严格墙钟或进程总内存上限。

## 验证与差距

JS/Wasm-GC 各 17 组测试；266 个独立官方模型向量全部一致。另有 384 个三瓦片穷举、512 个二维周期/非周期约束案例、生成图案归属/像素 pins、16384 次加权抽样、4096 图案和 65536 格边界、9 组 PNG/XML/Worker/CLI 集成及 8 组实际网页检查。具体范围和复现步骤见 [TESTING.md](TESTING.md)，指纹见 [evidence/scalable-upgrade.json](evidence/scalable-upgrade.json)。

四组同机计时中，MoonBit JS 中位数约 184–556 ms，C# 约 112–480 ms。随机搜索、边缘表示和计时范围不同；这不能证明性能追平。尚缺完整批任务配置、全部启发式和上游行为、更多真实素材、生产内存/跨平台/长期验证，见 [FEATURES.md](FEATURES.md)。

## 来源和本地工作流

算法与对称约定参考 [mxgmn/WaveFunctionCollapse](https://github.com/mxgmn/WaveFunctionCollapse)，固定参考提交 `de7d22e705e816b62b4d613199d0463820fcaef3`。生产代码是本地 MoonBit 重写；独立测试在仓库外编译未修改的官方 C# 核心，不捆绑其源码、二进制或素材。PNG/XML 依赖有各自许可证，以 `package-lock.json` 和包内声明为准。

安装 MoonBit、Node 24、Python 3/Pillow 后运行 `./verify.ps1`；编译器不在 PATH 可指定 `-MoonPath`。公共 API 由 `moon info` 生成，可执行示例在 [README.mbt.md](README.mbt.md)。本仓库可独立移动与构建，不引用相邻项目。仅本地提交，无 Git remote，未上传、发布或提交比赛；配置 CI 不等于远端已经运行。历史 evidence 保留原有日期与范围，旧 ZIP/bundle 尚未同步本版。
