# HarfBuzzSharp LoongArch old-world ABI1.0

中文说明见 [../README.zh-CN.md](../README.zh-CN.md).

This fork carries a reproducible build path for `libHarfBuzzSharp.so` targeting LoongArch old-world ABI1.0 (`linux-loongarch64`, LP64, glibc 2.28 compatible).

Important: the ClassIsland runtime needs `libHarfBuzzSharp.so`, not a generic upstream `libharfbuzz.so`. The build script therefore checks out `mono/SkiaSharp` and builds the `HarfBuzzSharp` GN target with the matching version script and SONAME.

The default GitHub Actions build downloads the matching Linux x64 old-world GCC 14 toolchain and full old-world development sysroot published by `YU322142/loongarch-oldworld-sysroot`. The build passes `--sysroot` directly to that downloaded sysroot, so public cross-tools bundled sysroots are not used for normal linking.

Default toolchain:

```text
https://github.com/YU322142/loongarch-oldworld-sysroot/releases/download/oldworld-dev-sysroot-20260607/linux-x64-cross-tools-loongarch64-oldworld-gcc14-20260607.tar.xz
SHA256: 78335E5FCE4FDD6505B23734C539304547753FA1887CC199F5EA0C7554ED0185
```

Default sysroot:

```text
https://github.com/YU322142/loongarch-oldworld-sysroot/releases/download/oldworld-dev-sysroot-20260607/loongarch64-oldworld-dev-sysroot-20260607.tar.xz
SHA256: 5D442178DB80F8C1BC599B5C0E5963071BBBB33270DE05747959ADC65E7BC086
```

## Build

```bash
bash loongarch-oldworld/build-harfbuzzsharp.sh
```

Useful overrides:

- `SKIASHARP_REF=v3.119.4` selects the SkiaSharp source tag used for the HarfBuzzSharp native target.
- `TOOLCHAIN_URL=...` selects a different cross-tools archive.
- `TOOLCHAIN_SHA256=...` enforces the toolchain archive hash.
- `SYSROOT_URL=...` selects the full development sysroot archive.
- `SYSROOT_SHA256=...` enforces the sysroot archive hash.
- `MAX_GLIBC=2.28` controls the ABI gate.

## Output

The script writes:

- `artifacts/loongarch-oldworld/out/libHarfBuzzSharp.so`
- `artifacts/loongarch-oldworld/out/libHarfBuzzSharp.so.0.60831.0`
- `artifacts/loongarch-oldworld/out/native-build-manifest.txt`

The committed `prebuilt/linux-loongarch64/oldworld/libHarfBuzzSharp.so` is the locally verified build used for ClassIsland testing.

The CI gate fails if the output is not LoongArch LP64 or if any required GLIBC symbol version is newer than `GLIBC_2.28`.
