# 带约束的 WFC 瓦片与 PNG 资产生成

**本项目仓库：[https://github.com/xiefei-coding/moonbit-wfc](https://github.com/xiefei-coding/moonbit-wfc)**

模块 `xiefei-coding/wfc`，本地版本 **0.4.0**，MIT。当前评审状态：**保留候选**。本文件是当前入口，旧轮次说明与详细用法保存在 [历史/完整使用说明](README-BEFORE-VALUE-REWORK.md)。

## 解决什么任务

从输入 PNG 学习图案或从 XML 读瓦片邻接，在 pins/周期边界等约束下生成实际游戏资产，区分无解、预算耗尽与取消。

需要从 PNG/瓦片输入在 pins 等约束下生成并导出资产时评估；核心是传播/回溯与明确结果状态。

## 直接复现

安装 MoonBit 和 Node.js 24，在本仓库根目录运行：

```sh
moon build --target js
node -e "require('node:fs').copyFileSync('_build/js/debug/build/cmd/web/web.js','web/engine.mjs')"
node examples/run-use-case.mjs
```

流程：**从样例 PNG 生成新瓦片图**。运行器创建新的系统临时目录，保留每一步的 stdout/stderr、产物及 `report.json`，打印实际目录；重复运行不会覆盖之前产物。它只执行仓库内的本地样例，不连接公网或发送消息。`report.json` 的 `expected` 是应观察的结果，实际结果在各步输出中；成功退出不替代内容核对。

输入性质：原创合成输入 PNG，使用固定种子；输出为可打开的实际 PNG。

应观察：求解成功并输出新的 PNG；无解/预算耗尽的含义与成功不同。

具体命令和输入路径见 [使用任务](USE-CASE.md) 与 [机器可读流程](examples/use-case.json)。只把这个脚本当复现入口，不把通用运行器计作核心技术贡献。

## 实现与已有项目的关系

MoonBit 实现模型、传播、熵选择、回溯及解验证；Node/浏览器提供 PNG/XML 文件、工作线程和取消入口。

算法源于 mxgmn/WaveFunctionCollapse，本轮未找到同范围 MoonBit 库。贡献是 MoonBit 求解接口和输入—约束—导出工作流，不是算法发明。

同类项目和检索边界见 [DUPLICATION](DUPLICATION.md)。查重用于避免错误的首创表述；关键词零结果不能证明生态空白，Node 宿主能力也不计为 MoonBit 原生 I/O。

库使用从 [公共 API](pkg.generated.mbti) 和根包源码开始；可在本 checkout 的消费包中导入 `"xiefei-coding/wfc"`。源码中的网络/文件宿主入口及完整参数仍见 [完整使用说明](README-BEFORE-VALUE-REWORK.md)。是否已发布到 Mooncakes 需另核实，本文不把 `moon add` 的下载成功作为已完成事项。

## 验证与边界

前一轮工程验证实际 PNG/XML、工作线程/文件导出和错误/取消路径通过；examples 中输入输出是原创合成瓦片。

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
