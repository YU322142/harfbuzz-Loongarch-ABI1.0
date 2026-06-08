# HarfBuzzSharp LoongArch old-world ABI1.0

中文说明见 [../README.zh-CN.md](../README.zh-CN.md).

This fork carries a reproducible build path for `libHarfBuzzSharp.so` targeting LoongArch old-world ABI1.0 (`linux-loongarch64`, LP64, glibc 2.28 compatible).

## Current target

- Platform: `linux-loongarch64`
- ABI: LoongArch old-world ABI1.0, LP64
- GLIBC ceiling: `GLIBC_2.28`
- Source baseline: `mono/SkiaSharp` `v3.119.4`, HarfBuzzSharp native GN target
- Default toolchain: Linux x64 old-world GCC 14 toolchain from `YU322142/loongarch-oldworld-sysroot`
- Default sysroot: full old-world development sysroot from `YU322142/loongarch-oldworld-sysroot`

## Why this is not generic `libharfbuzz.so`

Important: the ClassIsland runtime needs `libHarfBuzzSharp.so`, not a generic upstream `libharfbuzz.so`. The build script therefore checks out `mono/SkiaSharp` and builds the `HarfBuzzSharp` GN target with the matching version script and SONAME.

## Online build

The default GitHub Actions build downloads the matching Linux x64 old-world GCC 14 toolchain and full old-world development sysroot published by `YU322142/loongarch-oldworld-sysroot`. The build passes `--sysroot` directly to that downloaded sysroot, so public cross-tools bundled sysroots are not used for normal linking.

The toolchain is not a compiler written by this fork. It is a pinned/repacked third-party LoongArch old-world cross-toolchain aggregate for reproducible Actions builds. The sysroot is a development sysroot collected from an old-world Loongnix/LoongArch environment. Source notes, SHA256 values, and licensing boundaries are documented in [`YU322142/loongarch-oldworld-sysroot`](https://github.com/YU322142/loongarch-oldworld-sysroot).

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

## Local build

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

## Submitted output

The script writes:

- `artifacts/loongarch-oldworld/out/libHarfBuzzSharp.so`
- `artifacts/loongarch-oldworld/out/libHarfBuzzSharp.so.0.60831.0`
- `artifacts/loongarch-oldworld/out/native-build-manifest.txt`

`libHarfBuzzSharp.so.0.60831.0` is the SONAME/versioned filename for the same native HarfBuzzSharp shared library. The `0.60831.0` suffix comes from the native ABI naming used by the current `HarfBuzzSharp.NativeAssets.Linux` 8.3.1.3 package line. `libHarfBuzzSharp.so` is the stable loader name used by .NET P/Invoke and NuGet native assets; the versioned filename is kept so the release can also be inspected and reused like a normal Linux shared library artifact.

The committed `prebuilt/linux-loongarch64/oldworld/libHarfBuzzSharp.so` is the locally verified build used for ClassIsland testing.

The release artifact also includes `libHarfBuzzSharp.so.0.60831.0`, the versioned filename described above.

The CI gate fails if the output is not LoongArch LP64 or if any required GLIBC symbol version is newer than `GLIBC_2.28`.
