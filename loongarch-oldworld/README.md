# HarfBuzzSharp LoongArch old-world ABI1.0

中文说明见 [../README.zh-CN.md](../README.zh-CN.md).

This fork carries a reproducible build path for `libHarfBuzzSharp.so` targeting LoongArch old-world ABI1.0 (`linux-loongarch64`, LP64, glibc 2.28 compatible).

Important: the ClassIsland runtime needs `libHarfBuzzSharp.so`, not a generic upstream `libharfbuzz.so`. The build script therefore checks out `mono/SkiaSharp` and builds the `HarfBuzzSharp` GN target with the matching version script and SONAME.

The default GitHub Actions build downloads the `loong64/cross-tools` `baseline` toolchain, uses the sysroot bundled in that toolchain as the base, then layers an old-world development sysroot overlay on top of it. The overlay keeps the development files needed by the SkiaSharp HarfBuzzSharp GN target available during online builds.

Default overlay:

```text
https://github.com/YU322142/harfbuzz-Loongarch-ABI1.0/releases/download/oldworld-dev-sysroot-20260607/loongarch64-oldworld-dev-sysroot-overlay-20260607.tar.xz
SHA256: AD9DD4DB6C74D085279FF017AB4F743DB2CBA9013A1739BE3C62E56B84CA2F30
```

## Build

```bash
bash loongarch-oldworld/build-harfbuzzsharp.sh
```

Useful overrides:

- `SKIASHARP_REF=v3.119.4` selects the SkiaSharp source tag used for the HarfBuzzSharp native target.
- `TOOLCHAIN_URL=...` selects a different cross-tools archive.
- `TOOLCHAIN_SHA256=...` enforces the toolchain archive hash.
- `SYSROOT_URL=...` selects a development sysroot overlay to layer on top of the cross-tools bundled sysroot.
- `SYSROOT_SHA256=...` enforces the overlay archive hash.
- `MAX_GLIBC=2.28` controls the ABI gate.

## Output

The script writes:

- `artifacts/loongarch-oldworld/out/libHarfBuzzSharp.so`
- `artifacts/loongarch-oldworld/out/libHarfBuzzSharp.so.0.60831.0`
- `artifacts/loongarch-oldworld/out/native-build-manifest.txt`

The committed `prebuilt/linux-loongarch64/oldworld/libHarfBuzzSharp.so` is the locally verified build used for ClassIsland testing.

The CI gate fails if the output is not LoongArch LP64 or if any required GLIBC symbol version is newer than `GLIBC_2.28`.
