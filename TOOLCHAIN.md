# 可复现的 MoonBit 工具链

CI读取根目录 `.moonbit-version`，通过官方安装器取得 `0.10.14+7d59c7ec9` 的编译器和标准库；不随 latest 漂移。这个发行版的 `moonc` 为 v0.10.14+7d59c7ec9，`moon/moonrun` 为 0.1.20260920（914d7da）。两者版本号不相同是该发行版的正常组成，不应只用 moon 的日期猜下载版本。

Linux/macOS安装：

```sh
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash -s -- "$(cat .moonbit-version)"
moon version --all
moon update
```

Windows安装器支持 `MOONBIT_INSTALL_VERSION`；也可以使用已验证的本地工具链。版本安装方式见 [MoonBit官方说明](https://docs.moonbitlang.com/en/stable/tutorial/tour.html)。本轮在 Windows 上用官方 Windows 发行包及对应 core 验证固定版本；它不等于 GitHub runner 已经执行。

CI先执行 `moon update` 初始化注册表及解析依赖，再进行fmt/info/check；不能依赖开发机已有的registry或.mooncakes缓存。

升级时先修改版本文件，在独立目录执行fmt/info/check和受影响测试，更新生成API与编译引擎，再一起提交。不要通过删除确定性检查掩盖版本引起的差异。Node/Python、操作系统和外部服务仍有各自环境范围；固定MoonBit不意味着所有依赖完全冻结。

本轮只改本地，远端CI状态和Mooncakes发布状态仍需团队同步后确认。
