#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SKIASHARP_REPO="${SKIASHARP_REPO:-https://github.com/mono/SkiaSharp.git}"
SKIASHARP_REF="${SKIASHARP_REF:-v3.119.4}"
TOOLCHAIN_URL="${TOOLCHAIN_URL:-https://github.com/YU322142/loongarch-oldworld-sysroot/releases/download/oldworld-dev-sysroot-20260607/linux-x64-cross-tools-loongarch64-oldworld-gcc14-20260607.tar.xz}"
TOOLCHAIN_SHA256="${TOOLCHAIN_SHA256:-78335E5FCE4FDD6505B23734C539304547753FA1887CC199F5EA0C7554ED0185}"
SYSROOT_URL="${SYSROOT_URL:-https://github.com/YU322142/loongarch-oldworld-sysroot/releases/download/oldworld-dev-sysroot-20260607/loongarch64-oldworld-dev-sysroot-20260607.tar.xz}"
SYSROOT_SHA256="${SYSROOT_SHA256:-5D442178DB80F8C1BC599B5C0E5963071BBBB33270DE05747959ADC65E7BC086}"
MAX_GLIBC="${MAX_GLIBC:-2.28}"
JOBS="${JOBS:-$(nproc)}"

WORK_DIR="${WORK_DIR:-$REPO_ROOT/artifacts/loongarch-oldworld/work}"
OUT_DIR="${OUT_DIR:-$REPO_ROOT/artifacts/loongarch-oldworld/out}"
CACHE_DIR="${CACHE_DIR:-$REPO_ROOT/artifacts/loongarch-oldworld/cache}"
SRC_DIR="${SRC_DIR:-$WORK_DIR/SkiaSharp}"

mkdir -p "$WORK_DIR" "$OUT_DIR" "$CACHE_DIR"

log() {
  printf '[loongarch-oldworld] %s\n' "$*"
}

download() {
  local url="$1"
  local dest="$2"
  if [ -s "$dest" ]; then
    return
  fi
  log "Downloading $url"
  curl -fL --retry 8 --retry-all-errors --connect-timeout 30 --max-time 900 \
    -o "$dest.part" "$url"
  mv "$dest.part" "$dest"
}

verify_sha256() {
  local path="$1"
  local expected="$2"
  if [ -z "$expected" ]; then
    return
  fi
  local actual
  actual="$(sha256sum "$path" | awk '{print toupper($1)}')"
  expected="$(printf '%s' "$expected" | tr '[:lower:]' '[:upper:]')"
  if [ "$actual" != "$expected" ]; then
    printf 'SHA256 mismatch for %s\nexpected: %s\nactual:   %s\n' "$path" "$expected" "$actual" >&2
    exit 1
  fi
}

to_gn_path() {
  python3 -c 'import os, sys; print(os.path.abspath(sys.argv[1]).replace("\\", "/"))' "$1"
}

prepare_skiasharp_source() {
  if [ ! -d "$SRC_DIR/.git" ]; then
    rm -rf "$SRC_DIR"
    log "Cloning SkiaSharp $SKIASHARP_REF"
    git clone --depth 1 --branch "$SKIASHARP_REF" "$SKIASHARP_REPO" "$SRC_DIR"
  fi

  git -C "$SRC_DIR" submodule update --init externals/skia externals/depot_tools

  local skia="$SRC_DIR/externals/skia"
  log "Syncing Skia dependencies"
  (cd "$skia" && python3 tools/git-sync-deps)
  (cd "$skia" && python3 bin/fetch-gn && python3 bin/fetch-ninja)
}

prepare_toolchain() {
  if [ -z "${TOOLCHAIN_ROOT:-}" ]; then
    local archive="$CACHE_DIR/$(basename "$TOOLCHAIN_URL")"
    local extract_dir="$WORK_DIR/toolchain"
    download "$TOOLCHAIN_URL" "$archive"
    verify_sha256 "$archive" "$TOOLCHAIN_SHA256"
    if ! find "$extract_dir" -type f -name loongarch64-unknown-linux-gnu-gcc 2>/dev/null | grep -q .; then
      rm -rf "$extract_dir"
      mkdir -p "$extract_dir"
      tar -xf "$archive" -C "$extract_dir"
    fi
    TOOLCHAIN_ROOT="$extract_dir"
  fi

  chmod -R a+rX "$TOOLCHAIN_ROOT" 2>/dev/null || true
  find "$TOOLCHAIN_ROOT" -type f \( -path '*/bin/*' -o -path '*/libexec/*' \) -exec chmod a+x {} + 2>/dev/null || true

  CC="$(find "$TOOLCHAIN_ROOT" -type f -name loongarch64-unknown-linux-gnu-gcc | head -n 1)"
  if [ -z "$CC" ]; then
    printf 'Could not find loongarch64-unknown-linux-gnu-gcc under %s\n' "$TOOLCHAIN_ROOT" >&2
    exit 1
  fi
  BIN_DIR="$(dirname "$CC")"
  CXX="$BIN_DIR/loongarch64-unknown-linux-gnu-g++"
  AR="$BIN_DIR/loongarch64-unknown-linux-gnu-ar"
  READELF="$BIN_DIR/loongarch64-unknown-linux-gnu-readelf"

  if [ -z "${SYSROOT:-}" ]; then
    if [ -n "$SYSROOT_URL" ]; then
      local sysroot_archive="$CACHE_DIR/$(basename "$SYSROOT_URL")"
      local sysroot_extract="$WORK_DIR/sysroot"
      local sysroot_root
      download "$SYSROOT_URL" "$sysroot_archive"
      verify_sha256 "$sysroot_archive" "$SYSROOT_SHA256"
      rm -rf "$sysroot_extract"
      mkdir -p "$sysroot_extract"
      tar -xf "$sysroot_archive" -C "$sysroot_extract"
      sysroot_root="$sysroot_extract"
      if [ ! -d "$sysroot_root/usr/include" ]; then
        sysroot_root="$(find "$sysroot_extract" -type d -path '*/usr/include' -printf '%h\n' | head -n 1)"
      fi
      if [ -z "$sysroot_root" ] || [ ! -d "$sysroot_root/usr/include" ]; then
        printf 'Could not find usr/include in sysroot archive: %s\n' "$sysroot_archive" >&2
        exit 1
      fi
      SYSROOT="$sysroot_root"
      log "Using old-world development sysroot: $SYSROOT_URL"
    else
      local base
      base="$(cd "$BIN_DIR/.." && pwd)"
      SYSROOT="$base/loongarch64-unknown-linux-gnu/sysroot"
      if [ ! -d "$SYSROOT" ]; then
        SYSROOT="$(find "$base" -type d -name sysroot | head -n 1)"
      fi
    fi
  fi

  for path in "$CXX" "$AR" "$READELF" "$SYSROOT"; do
    if [ ! -e "$path" ]; then
      printf 'Missing required toolchain path: %s\n' "$path" >&2
      exit 1
    fi
  done

  log "Toolchain: $("$CC" --version | head -n 1)"
  log "Sysroot: $SYSROOT"
}

version_gt() {
  local left="$1"
  local right="$2"
  [ "$(printf '%s\n%s\n' "$left" "$right" | sort -V | tail -n 1)" = "$left" ] && [ "$left" != "$right" ]
}

assert_glibc_max() {
  local so="$1"
  local bad=0
  while read -r version; do
    [ -z "$version" ] && continue
    if version_gt "$version" "$MAX_GLIBC"; then
      printf '%s requires GLIBC_%s, above GLIBC_%s\n' "$so" "$version" "$MAX_GLIBC" >&2
      bad=1
    fi
  done < <("$READELF" --version-info "$so" | grep -Eo 'GLIBC_[0-9]+(\.[0-9]+)+' | sed 's/^GLIBC_//' | sort -Vu || true)
  if [ "$bad" -ne 0 ]; then
    exit 1
  fi
}

assert_loongarch_elf() {
  local so="$1"
  local header
  header="$("$READELF" -h "$so")"
  if ! printf '%s\n' "$header" | grep -q 'Class:.*ELF64'; then
    printf '%s is not an ELF64 object\n' "$so" >&2
    printf '%s\n' "$header" >&2
    exit 1
  fi
  if ! printf '%s\n' "$header" | grep -q 'Machine:.*LoongArch'; then
    printf '%s is not a LoongArch object\n' "$so" >&2
    printf '%s\n' "$header" >&2
    exit 1
  fi
  if ! printf '%s\n' "$header" | grep -Eq 'Flags:.*(LP64|OBJ-v1)'; then
    printf '%s does not report old-world LP64-compatible flags\n' "$so" >&2
    printf '%s\n' "$header" >&2
    exit 1
  fi
}

write_gn_args() {
  local out="$1"
  mkdir -p "$out"

  local sysroot_gn cc_gn cxx_gn ar_gn map_gn
  sysroot_gn="$(to_gn_path "$SYSROOT")"
  cc_gn="$(to_gn_path "$CC")"
  cxx_gn="$(to_gn_path "$CXX")"
  ar_gn="$(to_gn_path "$AR")"
  map_gn="$(to_gn_path "$SRC_DIR/native/linux/libHarfBuzzSharp/libHarfBuzzSharp.map")"

  cat > "$out/args.gn" <<EOF
is_official_build=true
skia_enable_tools=false
target_os="linux"
target_cpu="loong64"
visibility_hidden=false
extra_cflags=[ "--sysroot=$sysroot_gn", "-I$sysroot_gn/usr/include" ]
extra_asmflags=[]
extra_ldflags=[ "--sysroot=$sysroot_gn", "-static-libstdc++", "-static-libgcc", "-L$sysroot_gn/usr/lib64", "-L$sysroot_gn/lib64", "-L$sysroot_gn/usr/lib/loongarch64-linux-gnu", "-L$sysroot_gn/lib/loongarch64-linux-gnu", "-Wl,-rpath-link,$sysroot_gn/usr/lib64", "-Wl,-rpath-link,$sysroot_gn/lib64", "-Wl,-rpath-link,$sysroot_gn/usr/lib/loongarch64-linux-gnu", "-Wl,-rpath-link,$sysroot_gn/lib/loongarch64-linux-gnu", "-Wl,--version-script=$map_gn" ]
cc="$cc_gn"
cxx="$cxx_gn"
ar="$ar_gn"
linux_soname_version="0.60831.0"
link_pool_depth=1
EOF
}

build_harfbuzzsharp() {
  local skia="$SRC_DIR/externals/skia"
  local build_name="out/loongarch-oldworld-harfbuzzsharp"
  local build_dir="$skia/$build_name"
  write_gn_args "$build_dir"

  log "Generating GN project"
  (cd "$skia" && bin/gn gen "$build_name")
  log "Building HarfBuzzSharp target"
  (cd "$skia" && third_party/ninja/ninja -C "$build_name" HarfBuzzSharp -j "$JOBS" -k 1)

  local so="$build_dir/libHarfBuzzSharp.so.0.60831.0"
  if [ ! -f "$so" ]; then
    printf 'Missing output: %s\n' "$so" >&2
    exit 1
  fi

  assert_loongarch_elf "$so"
  assert_glibc_max "$so"

  cp -f "$so" "$OUT_DIR/libHarfBuzzSharp.so"
  cp -f "$so" "$OUT_DIR/libHarfBuzzSharp.so.0.60831.0"

  local versions
  versions="$("$READELF" --version-info "$so" | grep -Eo 'GLIBC_[0-9]+(\.[0-9]+)+' | sort -Vu | tr '\n' ' ' || true)"
  cat > "$OUT_DIR/native-build-manifest.txt" <<EOF
HarfBuzzSharp 龙芯旧世界 ABI1.0 原生库构建记录
生成时间: $(date -u '+%Y-%m-%dT%H:%M:%SZ')

源码:
  SkiaSharp 仓库: $SKIASHARP_REPO
  SkiaSharp ref: $SKIASHARP_REF
  SkiaSharp commit: $(git -C "$SRC_DIR" rev-parse HEAD)
  说明: 这是 SkiaSharp 的 HarfBuzzSharp 原生目标，不是普通上游 libharfbuzz.so。

工具链:
  URL: $TOOLCHAIN_URL
  Root: $TOOLCHAIN_ROOT
  GCC: $("$CC" --version | head -n 1)
  Sysroot: $SYSROOT
  Sysroot source: $(if [ -n "$SYSROOT_URL" ]; then printf '%s' "$SYSROOT_URL"; else printf 'toolchain bundled sysroot'; fi)

产物:
  $(sha256sum "$OUT_DIR/libHarfBuzzSharp.so")

ABI 检查:
  ELF=LoongArch LP64
  SONAME=libHarfBuzzSharp.so.0.60831.0
  max GLIBC <= $MAX_GLIBC
  实际 GLIBC 符号版本: $versions
EOF

  log "Output written to $OUT_DIR"
}

prepare_skiasharp_source
prepare_toolchain
build_harfbuzzsharp
