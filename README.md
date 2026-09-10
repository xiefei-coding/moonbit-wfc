# WFC 瓦片生成器

可复现的邻接约束传播、回溯和矛盾报告。本地候选版 0.3.0，供比较和代码审查；尚未作为完整竞赛作品提交。

## 运行

安装 MoonBit 后在本目录执行：

```sh
moon check
moon test
moon run cmd/main
```

也可在本目录运行 `./verify.ps1` 验证本项目。`pkg.generated.mbti` 是真实工具链生成的公共 API。命名空间 `localreview` 仅用于本地，正式发布前应替换为申请人的账号。

## 本版范围

实现目标：四方向邻接、约束传播、种子、回溯、预设格。

未承诺：从位图学习 overlapping model、权重熵、无限世界。

## 来源与实现方式

规格/算法参考：https://github.com/mxgmn/WaveFunctionCollapse。

当前代码是本地新写的 MoonBit 实现，不声称是上游完整移植；未复制上游源代码、词库或测试集。测试输入为本项目新写。MIT 仅适用于本目录原创代码。将来如移植上游文件，需要另行保存其版权声明并核查许可证，不能直接沿用当前说明。

## 审查

先看 `cmd/main/main.mbt` 的实际使用，再看公共 API 与测试文件。联网兼容性、性能数据或官方验收未执行的部分不得从本地单元测试成功推断。

## 下一阶段与明确限制

增加加权熵、overlapping 图像学习、失败原因定位和更大的非递归搜索器；当前四方向规则必须互为逆向关系，最多 30 瓦片与 256 格。种子 0 归一为 1。

本分装包自带 `web/index.html`（用 `start-review.ps1` 启动）。`cmd/web/main.mbt` 为薄适配层，网页调用编译后的真实 MoonBit 模块。

## 独立分装使用

本文件夹可以单独移动或建立仓库，不依赖其他候选项目。浏览器演示已编译，无须安装 MoonBit 即可试用（需要 Python 3）：

```powershell
./start-review.ps1
```

打开 http://127.0.0.1:8778/web/ 。修改和测试源码需安装 MoonBit 与 Node.js，再运行 `./verify.ps1`。本机尚未将 MoonBit 加入 PATH 时，可传入 `-MoonPath`。独立包不捆绑编译器。

仅含本项目源码和构建产物；没有上传仓库或发布包。`DUPLICATION.md`、`evidence/current-validation.json` 和本次分装清单 提供查重、测试和完整性资料。

## 独立仓库工作流

本目录是该项目后续开发的唯一主仓库，旧批次目录及 ZIP 为历史审查快照。没有 Git remote，没有共享构建目录，没有上级 moon.work。

真实 CLI 支持输入参数、文件和标准输入：

```powershell
node tools/cli.mjs --help
node tools/cli.mjs --file sample.txt --json
```

需要安装 MoonBit 后传 `-MoonPath` 或将 moon 加入 PATH；不依赖工作区之外的私有脚本。详见 [TESTING.md](TESTING.md) 和 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 本轮功能升级

增加解的尺寸、tile、pin 和四方向邻接约束验证。

非完整 overlapping model；没有交互式素材导入与大图性能证明。

[可执行 API 示例](README.mbt.md)会随测试运行；[功能边界](FEATURES.md)和[测试说明](TESTING.md)用于独立审查。网页与 CLI 展示示例入口，新 API 的完整使用见可执行示例。

## 从样本生成：重叠模型（0.3.0）

```powershell
node tools/overlap.mjs overlap-example.json
```

任务 JSON 包含字符网格 sample、图案尺寸 size、输出 width/height、seed、periodic（输出环绕）和 symmetry（八种旋转镜像）。
每个 Unicode 字符表示一种符号；样本行必须等宽，不含末尾空行。修改 example 文件即可使用自己的样本。
MoonBit API `learn_overlap(sample, width, height, size, periodic_input?, symmetry?)` 接受整数颜色/瓦片数组，
返回去重图案、频率和自动推导的四方向兼容规则；`OverlapModel.generate` 返回精确尺寸的符号数组或 None。
非周期输出会重建右侧和下侧边缘，周期输出约束首尾接缝。
现有 `solve` 新增 weights 与 periodic 参数，按 Shannon 熵选择单元、按权重选择图案，保留回溯与工作预算。
`Solution.validate` 可用 periodic=true 检查环绕边。

本轮 JS 目标 10 项项目测试通过，涵盖全部输出 2×2 图案归属、频率统计、D4 对称、偶数环绕可解/奇数矛盾、
单单元自邻接、权重偏好及资源拒绝；编译后的示例入口也已实际运行。没有重复运行其他 19 个项目。

### 仍有的差距

受现有位掩码求解器限制，最多 30 种图案、256 个求解单元，超限明确报错，不会静默截断；
图案尺寸为 1..8，输入最大 256×256。非周期输出的求解单元为 (width-size+1)×(height-size+1)。
不是大型纹理生产工具；尚缺大量图案的数据结构、PNG 素材导入、上游瓦片 XML/对称描述兼容与大图性能证据。
权重引导选择不保证单张结果的精确频率，也不保证与上游相同随机种子产生相同图案。
算法依据 [WaveFunctionCollapse 官方说明](https://github.com/mxgmn/WaveFunctionCollapse)，本地重写，未复制素材。
