# 公开素材任务与证据

版本 0.5.0；本地修订。算法参考 mxgmn/WaveFunctionCollapse，素材 Kenney Tiny Dungeon 1.0（CC0），本例规则原创；不宣称算法发明或生态空白。

## 复现

先按 README 构建引擎。安装 Pillow 12.3.0 后运行：

```sh
node examples/kenney-room.mjs /path/to/new-room
python tools/verify-kenney-room.py /path/to/new-room --evidence /path/to/receipt.json
node tools/test-kenney-room.mjs
```

输出目录必须尚未存在；只有 manifest.json 的 complete=true 才表示全部输出写完。素材及 License.txt 均未改动，散列见 examples/kenney-room/SOURCE.json；原包 SHA256 c109438ab06f65fd80f9b2686a4cf9c7c11dc64444b47333ec71d602f8bb5fc7。

## 核心契约

rules/tiled 接口接受 restrictions: [[cell, [tileId,...]]]，同一格的限制取交集；pins 是单瓦片限制。overlap/learn 不接受非空 restrictions，它们有不同的像素 pins 语义。最多 65536 pins/限制项，限制候选总数最多 2000000。容量上限是输入防线，不表示所有极限输入都有足够内存/时间。

solve_rules 返回 None 为搜索证明无解；抛出 BudgetExhausted 仅表示预算不够，不能推导无解。JSON 对应 status=unsat 与 status=budget-exhausted；无部分图。validate_rules 同时核对邻接、pins 和限制集合。固定种子只承诺同版本/相同输入输出一致；本版合并并排序限制可能改变旧版输出。

## 已核验的具体结果

固定种子 20260927，预算 2000000，32×24 格、512×384 像素。431 次决策、0 回溯；墙106格、主地面543格、两种细节55/64格。入口位于384/415；662个可行走格全部连通。Python 独立 BFS、邻接/边界规则和 Pillow 原图逐像素重组通过；见 evidence/room-20260927/public-reference.json。

这证明公开输入经过 MoonBit 核心生成可消费的 PNG 和格子数据。它不证明完整地牢生成、任意模型连通、玩法质量或生产采用。预算计数不覆盖文件解码和全部初始化工作；宿主取消/超时另由工作线程控制。
