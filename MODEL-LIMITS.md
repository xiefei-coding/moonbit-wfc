# 0.5.1：学习到求解的容量一致性

512×512单色输入、size=1、symmetry=8在公开输入上限内，精确频次为262144×8=2097152。旧版learn成功，但solve的1000000权重上限拒绝此模型，所以无法生成最简单的单色图。现统一核心与XML的正权重上限为2147483647，保留原始频次；4096项之和及weight*log(weight)仍是有限Double。

旧版还逐条扫描重复pin的全部瓦片。4096瓦片、65536个同格同值pin会进行约2.68亿次扫描。现先线性汇总pin，再对每个不同格扫描一次；同值重复保持结果，矛盾形成空域，非法坐标在操作波状态前拒绝。预算仍按已声明的核心工作计数，不是墙钟保证。

修复前后运行记录在[evidence/model-limits-20260927](evidence/model-limits-20260927)。一次本机探针中重复pin从2679.8毫秒降到63.9毫秒；后续独立运行约92毫秒。它们仅是本机观察，不是跨机器速度承诺或CI时间阈值。

三个新MoonBit测试组覆盖最大合法频次、不同频次与像素pin、正Int权重边界，以及重复/冲突/非法pin和集合限制。JS/Wasm-GC分别22组通过；384个独立三瓦片穷举、12个局部图案检查、16384个加权抽样，以及4096图案/65536格容量检查通过。已有输出统计不变。

复现：`moon test --target js`、`moon test --target wasm-gc`，按README刷新web/engine.mjs后运行`node tools/test-model-limits.mjs`。持续检查已接入CI配置，远端尚未运行。`test-generation.mjs`与`test-capacity.mjs`现在支持`--evidence FILE`，允许新运行保留历史回执。
