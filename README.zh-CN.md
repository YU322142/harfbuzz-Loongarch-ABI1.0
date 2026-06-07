# HarfBuzzSharp 龙芯旧世界 ABI1.0 构建说明

本 fork 用于在线构建并保存 ClassIsland 龙芯旧世界 ABI1.0 适配需要的 `libHarfBuzzSharp.so`。

详细构建说明见 [loongarch-oldworld/README.md](loongarch-oldworld/README.md)。

## 当前目标

- 平台：`linux-loongarch64`
- ABI：LoongArch old-world ABI1.0，LP64
- GLIBC 上限：`GLIBC_2.28`
- 源码基线：`mono/SkiaSharp` `v3.119.4` 中的 `HarfBuzzSharp` GN target
- 默认工具链：`loong64/cross-tools` `baseline`
- 默认 sysroot：cross-tools 内置 sysroot

## 为什么不是普通 libharfbuzz.so

ClassIsland 的 .NET 运行时依赖 `HarfBuzzSharp.NativeAssets.Linux` 对应的 `libHarfBuzzSharp.so`，它有自己的 SONAME 和导出符号规则。因此这里从 SkiaSharp 的 `HarfBuzzSharp` 原生目标构建，而不是直接使用上游 harfbuzz 的 meson 产物替换。

## 已提交产物

预编译产物位于：

```text
prebuilt/linux-loongarch64/oldworld/libHarfBuzzSharp.so
```

该产物已在 Loongnix 20 旧世界 ABI1.0 X11 虚拟机中随 ClassIsland 测试通过，覆盖渲染、托盘和声音相关流程。

## 在线构建

推送到 `main` 或手动运行 GitHub Actions `Build LoongArch old-world ABI1.0` 即可构建。

正常情况下不需要单独上传 sysroot。如果后续需要固定某个 Loongnix sysroot，可在 workflow dispatch 时提供 `sysrootUrl`，或通过环境变量 `SYSROOT_URL` / `SYSROOT_SHA256` 覆盖。
