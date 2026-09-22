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
