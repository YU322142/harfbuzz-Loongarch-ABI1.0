# HarfBuzzSharp LoongArch old-world ABI1.0

中文说明见 [../README.zh-CN.md](../README.zh-CN.md).

This fork carries a reproducible build path for `libHarfBuzzSharp.so` targeting LoongArch old-world ABI1.0 (`linux-loongarch64`, LP64, glibc 2.28 compatible).

Important: the ClassIsland runtime needs `libHarfBuzzSharp.so`, not a generic upstream `libharfbuzz.so`. The build script therefore checks out `mono/SkiaSharp` and builds the `HarfBuzzSharp` GN target with the matching version script and SONAME.

The default GitHub Actions build downloads the `loong64/cross-tools` `baseline` toolchain and uses the sysroot bundled in that toolchain. A separate sysroot upload is not required for the normal build.

## Build

```bash
bash loongarch-oldworld/build-harfbuzzsharp.sh
```

Useful overrides:

- `SKIASHARP_REF=v3.119.4` selects the SkiaSharp source tag used for the HarfBuzzSharp native target.
- `TOOLCHAIN_URL=...` selects a different cross-tools archive.
- `TOOLCHAIN_SHA256=...` enforces the toolchain archive hash.
- `SYSROOT_URL=...` optionally replaces the cross-tools bundled sysroot.
- `SYSROOT_SHA256=...` enforces the external sysroot archive hash.
- `MAX_GLIBC=2.28` controls the ABI gate.

## Output

The script writes:

- `artifacts/loongarch-oldworld/out/libHarfBuzzSharp.so`
- `artifacts/loongarch-oldworld/out/libHarfBuzzSharp.so.0.60831.0`
- `artifacts/loongarch-oldworld/out/native-build-manifest.txt`

The committed `prebuilt/linux-loongarch64/oldworld/libHarfBuzzSharp.so` is the locally verified build used for ClassIsland testing.

The CI gate fails if the output is not LoongArch LP64 or if any required GLIBC symbol version is newer than `GLIBC_2.28`.
