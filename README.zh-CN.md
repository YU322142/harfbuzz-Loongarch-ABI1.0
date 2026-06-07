# HarfBuzzSharp 龙芯旧世界 ABI1.0 构建说明

本 fork 用于在线构建并保存 ClassIsland 龙芯旧世界 ABI1.0 适配需要的 `libHarfBuzzSharp.so`。

详细构建说明见 [loongarch-oldworld/README.md](loongarch-oldworld/README.md)。

## 当前目标

- 平台：`linux-loongarch64`
- ABI：LoongArch old-world ABI1.0，LP64
- GLIBC 上限：`GLIBC_2.28`
- 源码基线：`mono/SkiaSharp` `v3.119.4` 中的 `HarfBuzzSharp` GN target
- 默认工具链：`loong64/cross-tools` `legacy`（2025-05-07）
- 默认 sysroot：`YU322142/loongarch-oldworld-sysroot` 发布的完整旧世界开发 sysroot

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

Actions 默认使用 `loong64/cross-tools` 2025-05-07 的 `legacy` 工具链，并下载 `YU322142/loongarch-oldworld-sysroot` release 中的完整旧世界开发 sysroot。构建时会直接把 `--sysroot` 指向该 sysroot，不再使用 cross-tools 自带 sysroot 参与链接。该 sysroot 来自本地旧世界开发环境，用于补齐在线构建需要的开发头文件和库。

默认工具链：

```text
https://github.com/loong64/cross-tools/releases/download/20250507/x86_64-cross-tools-loongarch64-unknown-linux-gnu-legacy.tar.xz
SHA256: 3EDD0C1A612ED9E01B45D65CAED210F775738EF6FEB9173896E565B38C676A55
```

默认 sysroot：

```text
https://github.com/YU322142/loongarch-oldworld-sysroot/releases/download/oldworld-dev-sysroot-20260607/loongarch64-oldworld-dev-sysroot-20260607.tar.xz
SHA256: 5D442178DB80F8C1BC599B5C0E5963071BBBB33270DE05747959ADC65E7BC086
```

如果后续需要固定其他 Loongnix 开发 sysroot，可在 workflow dispatch 时提供 `sysrootUrl`，或通过环境变量 `SYSROOT_URL` / `SYSROOT_SHA256` 覆盖。若明确设为空值，脚本才会退回使用工具链自带 sysroot。
