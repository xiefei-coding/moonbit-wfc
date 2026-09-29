# MoonBit WFC：带明确求解状态的瓦片与 PNG 资产生成

项目仓库：https://github.com/xiefei-coding/moonbit-wfc。模块 `xiefei-coding/wfc@0.5.1`；MIT。本项目提供已有 WFC 算法的 MoonBit 求解与资产输入输出流程。

## 使用任务

将一组瓦片邻接或示例 PNG 用于关卡素材生成时，调用方需要固定边界和入口、限制某些位置可用的瓦片，并区分“无解”与“还没有在预算内求出”。本库接收约束、种子和预算，返回有类型的求解状态及可导出的结果，适合接入 MoonBit 游戏工具或浏览器资产编辑器。

## 核心与宿主分工

模型、传播、熵选择、回溯、固定点/允许集合限制及解验证在 MoonBit 中实现；Node/浏览器承担 PNG/XML 文件、工作线程与取消。预算耗尽独立于无解，失败不会冒充成功图片。0.5.1 修正合法学习频次在求解阶段被误拒绝及重复固定点的额外扫描，容量与失败边界见 [MODEL-LIMITS](MODEL-LIMITS.md)。

## 可运行资产任务

按照 README 构建后运行 `node examples/run-use-case.mjs`，从示例 PNG 生成新瓦片图。另提供真实 Kenney CC0 瓦片工作流：生成 32×24 房间地面图，设置边界、入口及允许集合，导出 PNG；用独立 Pillow 逐块核对 768 瓦片、196608 像素与连通性。素材本身不附邻接规则，本例规则由项目定义，详见 [PUBLIC-ASSET](PUBLIC-ASSET.md)。

## 既有工作与独立交付

算法来自 [mxgmn/WaveFunctionCollapse](https://github.com/mxgmn/WaveFunctionCollapse)，不作为原创算法申报。新增交付是可由 MoonBit 程序直接组合的模型/约束/状态 API，以及从已有素材到可检查产物的消费者。AI 能生成一段关卡生成代码，仍需对约束是否满足、求解何时停止和产物是否匹配输入给出确定结果；这些是本库可重复调用的作用。

不保证任意约束都有解，不宣称完整支持所有上游 samples.xml、兼容所有 PNG/XML 变体或更优性能。连通性核对属于该公开示例，不能推导一般求解器保证所有地图可通行。当前没有确认的游戏项目采用；公开素材与真实游戏生产验收分别对待。交付包括 MoonBit 核心、CLI/浏览器入口、可运行例子、参考许可与独立验证回执。

**公开状态（2026-09-29 核对）**：GitHub [公开仓库](https://github.com/xiefei-coding/moonbit-wfc)、[Mooncakes 0.5.1](https://mooncakes.io/docs/xiefei-coding/wfc@0.5.1) 已可访问；[CI 成功记录](https://github.com/xiefei-coding/moonbit-wfc/actions/runs/36436319538) 对应 `30f637973239`。本次材料更新尚未推送；该远端 CI 对应所列公开提交。报名表一致性及赛事审核结果尚未核实。
