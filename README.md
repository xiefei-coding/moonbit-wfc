# 带约束的 WFC 瓦片与 PNG 资产生成

**本项目仓库：[https://github.com/xiefei-coding/moonbit-wfc](https://github.com/xiefei-coding/moonbit-wfc)**

模块 `xiefei-coding/wfc`，本地版本 **0.5.1**，MIT。当前评审状态：**保留候选**。本文件是当前入口，旧轮次说明与详细用法保存在 [历史/完整使用说明](README-BEFORE-VALUE-REWORK.md)。


## 0.5.1：模型容量与重复固定点修复

修复合法512×512输入、八种变换产生的频次被生成阶段拒绝的问题；学习频次原样保留，求解器和XML入口接受的正权重上限统一为2147483647。重复固定点按格子合并，冲突仍返回无解，非法坐标仍拒绝，避免重复扫描同一域。独立穷举/图案与容量检查继续通过；修复前后及本机计时见 [MODEL-LIMITS](MODEL-LIMITS.md)。

## 0.5.0：公开素材与约束结果契约

[Kenney Tiny Dungeon 1.0](https://kenney.nl/assets/tiny-dungeon) 的四块未改动 CC0 瓦片用于生成 32×24 房间地面图。素材来自 Kenney；边界、两个入口及细节不相邻规则由本例自行定义。MoonBit 核心完成求解和渲染，Node 只处理文件/PNG。公开素材不是客户采用，房间地面图也不是完整地牢或游戏玩法验收。

新增 JSON `restrictions: [[cell, [allowedTileIds]]]` 与解校验接口；重复限制取交集，输入数量有上限。`BudgetExhausted` / `status: "budget-exhausted"` 明确区别于无解；二者均不返回半成品。预算是核心工作计数，不是时间保证。限制按格子排序，因此跨旧版本种子输出不承诺一致。

```sh
node examples/kenney-room.mjs NEW_DIRECTORY
python tools/verify-kenney-room.py NEW_DIRECTORY --evidence receipt.json
node tools/test-kenney-room.mjs
```

独立 Python/Pillow 逐像素核对 196608 像素，检查 768 格、边界和两个入口，并用 BFS 验证 662 个可行走格连通。规则本身没有承诺自动保证任意图连通；本例的连通性单独验证。来源、许可、种子、容量和命令见 [PUBLIC-ASSET.md](PUBLIC-ASSET.md)，实际回执见 [evidence/room-20260927](evidence/room-20260927)。

## 解决什么任务

从输入 PNG 学习图案或从 XML 读瓦片邻接，在 pins/周期边界等约束下生成实际游戏资产，区分无解、预算耗尽与取消。

需要从 PNG/瓦片输入在 pins 等约束下生成并导出资产时评估；核心是传播/回溯与明确结果状态。

## 直接复现

安装 MoonBit 和 Node.js 24，在本仓库根目录运行：

```sh
npm ci --ignore-scripts
moon build --target js
node -e "require('node:fs').copyFileSync('_build/js/debug/build/cmd/web/web.js','web/engine.mjs')"
node examples/run-use-case.mjs
```

流程：**从样例 PNG 生成新瓦片图**。运行器创建新的系统临时目录，保留每一步的 stdout/stderr、产物及 `report.json`，打印实际目录；重复运行不会覆盖之前产物。它只执行仓库内的本地样例，不连接公网或发送消息。`report.json` 的 `expected` 是应观察的结果，实际结果在各步输出中；成功退出不替代内容核对。

输入性质：原创合成输入 PNG，使用固定种子；输出为可打开的实际 PNG。

应观察：求解成功并输出新的 PNG；无解/预算耗尽的含义与成功不同。

具体命令和输入路径见 [使用任务](USE-CASE.md) 与 [机器可读流程](examples/use-case.json)。只把这个脚本当复现入口，不把通用运行器计作核心技术贡献。

PNG/XML 文件适配使用锁定版本的 pngjs 7.0.0 与 @xmldom/xmldom 0.9.12，首次运行需要上面的 npm 安装步骤；这些不是 MoonBit 核心求解器的原创实现。

## 实现与已有项目的关系

MoonBit 实现模型、传播、熵选择、回溯及解验证；Node/浏览器提供 PNG/XML 文件、工作线程和取消入口。

算法源于 mxgmn/WaveFunctionCollapse，本轮未找到同范围 MoonBit 库。贡献是 MoonBit 求解接口和输入—约束—导出工作流，不是算法发明。

同类项目和检索边界见 [DUPLICATION](DUPLICATION.md)。查重用于避免错误的首创表述；关键词零结果不能证明生态空白，Node 宿主能力也不计为 MoonBit 原生 I/O。

库使用从 [公共 API](pkg.generated.mbti) 和根包源码开始；可在本 checkout 的消费包中导入 `"xiefei-coding/wfc"`。源码中的网络/文件宿主入口及完整参数仍见 [完整使用说明](README-BEFORE-VALUE-REWORK.md)。是否已发布到 Mooncakes 需另核实，本文不把 `moon add` 的下载成功作为已完成事项。

## 验证与边界

历史合成输入验证仍保留；本轮另增加上述公开 Kenney 素材工作流。

[上一轮工程验证](evidence/innovation-review-20260922/results.json) 与 [本轮最小任务回执](evidence/value-rework-20260922/use-case.json) 分开。历史参考版本、golden 重放、本机 peer、真实第三方服务端和本次样例是不同证据，不能合并成“全部生产验证”。

常规核心检查可运行 `moon check --target js`、`moon test --target js`、`moon test --target wasm-gc`。专项命令：

```sh
node tools/test-runtime.mjs
```

专项所需的参考环境和历史版本见原使用说明及 TESTING 文档；本轮回执只记录实际执行项，不声称上面所有参考服务在任意环境即装即跑。

性能和预算有限，无全部上游 samples.xml/所有输入变体兼容，也没有承诺任何约束都一定有解。

## 复审材料状态

算法非原创，不保证任意约束有解，也不把玩具输入当生产游戏资产验收。

2026-09-22 匿名新克隆成功；默认分支 `main`，核验公开提交 `755890a019a774940241ce112d2839ab8f9b0d8a`。本轮源码修订仅在本地，尚未推送；此记录不证明当时报名表中的地址正确，也不证明新修订已上线。

[申报草稿](PROPOSAL.md) 已压缩为 30 行以内，并单独标明本项目仓库；[复核说明](REVIEW-RESPONSE.md) 区分材料错误、功能变化及尚未解决的问题。没有编造用户、设备接入、生产部署或评审认可。

CI固定的编译器与标准库版本见 [TOOLCHAIN.md](TOOLCHAIN.md)；升级时需同时核对生成产物。

## 本地验收与公开交付（2026-09-28）

核心实现使用 MoonBit；[固定编译器](.moonbit-version)为 `moonc 0.10.14+7d59c7ec9`。先按本文安装宿主依赖、运行 `moon update`，再从仓库根目录执行以下与 [CI](.github/workflows/ci.yml) 对齐的检查；可运行任务和适用边界见本文前面的示例与说明。

```sh
moon check --deny-warn
moon test --target wasm-gc --deny-warn
moon test --target js --deny-warn
moon build --target js --deny-warn
moon package
```

跨平台复核（2026-09-28，本地 Ubuntu-D 26.04 WSL2）：从当时的源码归档全新解包，固定 `moonc 0.10.14+7d59c7ec9` 下通过 `moon update`、`moon fmt --check`、`moon info`、严格检查、JS/Wasm-GC 测试及 JS release 构建；Node 24.21.0 跑通本仓一条宿主入口。本次补记仅修改文档，代码与 CI 未变；复核日志在本地交接包中，公开提交后的 GitHub Actions 仍须单独核对。

专项复核：固定 Kenney 素材生成的 32×24 房间为 512×384 PNG；Pillow 12.3.0 对 768 个瓦片逐块像素核对，独立脚本验证边界、入口和连通性。

本地核验：JS/Wasm-GC 各 22 项测试、浏览器/CLI 示例、266 个参考向量及公开素材验证通过。 `moon package` 已完成离线打包预检，它不等于已发布到 Mooncakes。

公开交付（2026-09-28 核对）：当日 [https://github.com/xiefei-coding/moonbit-wfc](https://github.com/xiefei-coding/moonbit-wfc) 可匿名读取 Git HEAD，Mooncakes 在线版本为 `0.4.0`；此处源码版本 `0.5.1` 仍需由申报人同步到公开仓库，检查新提交的 GitHub Actions，再由对应账号发布 Mooncakes 新版。相关远端 CI 与赛事结果仍需以实际记录核对。项目许可见 [LICENSE](LICENSE)；如使用第三方材料，其来源和许可见仓内相应说明。
