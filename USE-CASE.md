
## 0.5.0：公开素材与约束结果契约

[Kenney Tiny Dungeon 1.0](https://kenney.nl/assets/tiny-dungeon) 的四块未改动 CC0 瓦片用于生成 32×24 房间地面图。素材来自 Kenney；边界、两个入口及细节不相邻规则由本例自行定义。MoonBit 核心完成求解和渲染，Node 只处理文件/PNG。公开素材不是客户采用，房间地面图也不是完整地牢或游戏玩法验收。

新增 JSON `restrictions: [[cell, [allowedTileIds]]]` 与解校验接口；重复限制取交集，输入数量有上限。`BudgetExhausted` / `status: "budget-exhausted"` 明确区别于无解；二者均不返回半成品。预算是核心工作计数，不是时间保证。限制按格子排序，因此跨旧版本种子输出不承诺一致。

```sh
node examples/kenney-room.mjs NEW_DIRECTORY
python tools/verify-kenney-room.py NEW_DIRECTORY --evidence receipt.json
node tools/test-kenney-room.mjs
```

独立 Python/Pillow 逐像素核对 196608 像素，检查 768 格、边界和两个入口，并用 BFS 验证 662 个可行走格连通。规则本身没有承诺自动保证任意图连通；本例的连通性单独验证。来源、许可、种子、容量和命令见 [PUBLIC-ASSET.md](PUBLIC-ASSET.md)，实际回执见 [evidence/room-20260927](evidence/room-20260927)。

# 从样例 PNG 生成新瓦片图

从输入 PNG 学习图案或从 XML 读瓦片邻接，在 pins/周期边界等约束下生成实际游戏资产，区分无解、预算耗尽与取消。

## 输入、操作、输出

原创合成输入 PNG，使用固定种子；输出为可打开的实际 PNG。

最简运行：先用 `npm ci --ignore-scripts` 安装锁定的 PNG/XML 文件适配依赖，再按 README 构建，然后 `node examples/run-use-case.mjs`。它自动创建输出目录并执行下面命令。下列 `{out}` 是运行器替换的实际目录，不是直接输入 shell 的变量；stdin 文件由运行器传递，以避免 Windows 与 POSIX 重定向差异。

```text
node tools/generate.mjs --job examples/islands.json --out {out}/islands.png
```

观察：求解成功并输出新的 PNG；无解/预算耗尽的含义与成功不同。

每一步输出见实际目录下 `step-N.stdout.txt` / `step-N.stderr.txt`；本轮已保存回执见 `evidence/value-rework-20260922/use-case.json`。

## 为什么保留这个实现

需要从 PNG/瓦片输入在 pins 等约束下生成并导出资产时评估；核心是传播/回溯与明确结果状态。

算法源于 mxgmn/WaveFunctionCollapse，本轮未找到同范围 MoonBit 库。贡献是 MoonBit 求解接口和输入—约束—导出工作流，不是算法发明。

## 不能由样例推出的结论

性能和预算有限，无全部上游 samples.xml/所有输入变体兼容，也没有承诺任何约束都一定有解。

该样例是可修改的使用入口，不能证明存在真实用户、全部兼容或性能领先。继续投入的依据应是明确的输入或接入需求；若对接任务用既有成熟库即可完成，应优先复用而不是为保留参赛数量扩张本项目。
