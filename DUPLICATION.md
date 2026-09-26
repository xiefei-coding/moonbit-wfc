
## 0.5.0：公开素材与约束结果契约

[Kenney Tiny Dungeon 1.0](https://kenney.nl/assets/tiny-dungeon) 的四块未改动 CC0 瓦片用于生成 32×24 房间地面图。素材来自 Kenney；边界、两个入口及细节不相邻规则由本例自行定义。MoonBit 核心完成求解和渲染，Node 只处理文件/PNG。公开素材不是客户采用，房间地面图也不是完整地牢或游戏玩法验收。

新增 JSON `restrictions: [[cell, [allowedTileIds]]]` 与解校验接口；重复限制取交集，输入数量有上限。`BudgetExhausted` / `status: "budget-exhausted"` 明确区别于无解；二者均不返回半成品。预算是核心工作计数，不是时间保证。限制按格子排序，因此跨旧版本种子输出不承诺一致。

```sh
node examples/kenney-room.mjs NEW_DIRECTORY
python tools/verify-kenney-room.py NEW_DIRECTORY --evidence receipt.json
node tools/test-kenney-room.mjs
```

独立 Python/Pillow 逐像素核对 196608 像素，检查 768 格、边界和两个入口，并用 BFS 验证 662 个可行走格连通。规则本身没有承诺自动保证任意图连通；本例的连通性单独验证。来源、许可、种子、容量和命令见 [PUBLIC-ASSET.md](PUBLIC-ASSET.md)，实际回执见 [evidence/room-20260927](evidence/room-20260927)。

> 2026-09-22 三份初审反馈后的当前判断：**保留候选**。算法非原创，不保证任意约束有解，也不把玩具输入当生产游戏资产验收。 本次差异说明：算法源于 mxgmn/WaveFunctionCollapse，本轮未找到同范围 MoonBit 库。贡献是 MoonBit 求解接口和输入—约束—导出工作流，不是算法发明。 以下保留之前检索的固定提交与来源；此前“补足场景”不能理解为本次已解除价值异议。

# wfc 查重与定位 · 2026-09-22

算法源于 mxgmn/WaveFunctionCollapse，本轮未找到同范围 MoonBit 库。贡献是 MoonBit 求解接口和输入—约束—导出工作流，不是算法发明。 检索原始响应在总交付包的创新性复核目录保存。



本轮材料采用定位：**带约束的 WFC 瓦片与 PNG 资产生成**。

MoonBit 与宿主分工：MoonBit 实现模型、传播、熵选择、回溯及解验证；Node/浏览器提供 PNG/XML 文件、工作线程和取消入口。

本轮证据：本轮实际 PNG/XML、工作线程/文件导出和错误/取消路径通过；examples 中输入输出是原创合成瓦片。 具体输入、脚本、已执行与历史对照分开记录在 [PROPOSAL.md](PROPOSAL.md) 和 evidence/innovation-review-20260922/。

边界：性能和预算有限，无全部上游 samples.xml/所有输入变体兼容，也没有承诺任何约束都一定有解。

检索覆盖 Mooncakes 官方关键词/别名、GitHub 仓库查询、GitLink 公开索引、直接来源文档；没有完整赛事报名表、私有仓库、未公开分支或 GitHub 全代码索引。GitLink 索引也不完整。未找到同范围项目不等于生态空白；已有相关项目不自动等于无独立贡献。完整查询和固定提交快照在总交付目录 innovation-review-20260922/。

初次复核风险为“待补场景”。本次补足差异和可复现工作流，没有自行将重叠归零，也不替评委作创新性认定。最终公开代码与表单附件须使用一致版本。

## 来源直达

[WaveFunctionCollapse 原实现](https://github.com/mxgmn/WaveFunctionCollapse)。这些是既有规范/实现的来源；具体固定版本、适配与运行范围见 [完整说明](README-BEFORE-VALUE-REWORK.md) 和仓库验证记录。链接存在不代表本轮重新运行了对方实现，也不构成赛事无重复证明。
