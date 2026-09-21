# MoonBit WFC 图案生成库 · 项目申报书

## 一、项目名称

MoonBit WFC 图案生成库

## 二、项目说明

MoonBit 实现重叠图案学习、瓦片对称/邻接、加权熵、传播与有界回溯；Node 和浏览器提供 PNG/XML 输入及取消。随机求解不保证所有合法大任务均在预算内完成。

## 三、方向与通用性

算法与图案生成工具。用于游戏地图、像素素材和约束教学；同版本同输入种子可复现，不承诺与上游相同种子逐像素相同。

## 四、应用场景

任务文件驱动 generate 输出 PNG；XML 定义定向邻接和权重；pins 固定部分像素或瓦片；网页导入样图、调参并导出结果。

## 五、功能与验证边界

记录有 266 个独立官方模型向量、穷举及周期约束比较；无解与预算耗尽分开返回。完整 samples.xml、所有启发式及生产内存/性能仍未完成；已披露的计时不证明上游性能追平。

## 六、原创性与参考材料

原创代码和示例素材 MIT。算法/对称参考 mxgmn/WaveFunctionCollapse（MIT，https://github.com/mxgmn/WaveFunctionCollapse），固定提交 de7d22e；原版 C# 核心在仓库外作独立对照，不捆绑源码或素材。PNG/XML 依赖保留各自许可证。

## 七、仓库链接

https://github.com/xiefei-coding/moonbit-wfc
