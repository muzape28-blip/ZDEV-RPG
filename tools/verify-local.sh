#!/usr/bin/env bash
# LAPISAN VERIFIKASI LOKAL (WORKING-AGREEMENT §1 & §3).
#
# Binary custom project ini tidak mendukung --path dan terbukti menggantung pada
# --check-only bahkan di project minimal. Karena itu gate memakai dua harness:
# 1) parse-load setiap script di project ringan tanpa aset;
# 2) boot scene nyata di project runtime dengan aset produksi yang dipakai.
# CI official Godot 4.7.2 tetap menjadi hakim parse strict/deprecated dan export.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/tools/godot-headless"
if [ ! -x "$BIN" ] && [ -f "$ROOT/tools/godot-headless.xz" ]; then
  echo "engine tidak ada — dekompres dari tools/godot-headless.xz ..."
  xz -dc "$ROOT/tools/godot-headless.xz" > "$BIN" && chmod +x "$BIN"
fi
if [ ! -x "$BIN" ] && ls "$ROOT"/tools/parts/gh.* >/dev/null 2>&1; then
  echo "engine tidak ada — rakit dari tools/parts/ ..."
  cat "$ROOT"/tools/parts/gh.* | xz -dc > "$BIN" && chmod +x "$BIN"
fi
[ -x "$BIN" ] || { echo "FATAL: tools/godot-headless tidak ada"; exit 2; }

PARSE="$ROOT/.cache/projtest-parse"
RUN="$ROOT/.cache/projtest-run"
rm -rf "$PARSE" "$RUN"
mkdir -p "$PARSE" "$RUN"
cp "$ROOT/project.godot" "$ROOT/export_presets.cfg" "$PARSE/"
cp -r "$ROOT/scripts" "$PARSE/"
cp "$BIN" "$PARSE/godot-headless"
cd "$PARSE" || exit 2
FAIL=0
for s in main player_controller camera_follow hud floating_joystick ui_button arena_spawner terrain_generator grass proxy_humanoid runtime_smoke; do
  [ -f "$ROOT/scripts/$s.gd" ] || { echo "skip (belum ada): $s"; continue; }
  OUT_FILE="$PARSE/.out-$s"
  timeout 20 ./godot-headless --headless --script "res://scripts/$s.gd" --quit-after 1 >"$OUT_FILE" 2>&1
  RC=$?
  OUT=$(grep -E "SCRIPT ERROR|Parse Error|treated as error" "$OUT_FILE" | head -2 || true)
  if [ "$RC" -eq 124 ]; then
    echo "PARSE TIMEOUT: $s"; FAIL=1
  elif [ -n "$OUT" ]; then
    echo "PARSE GAGAL: $s"; echo "$OUT"; FAIL=1
  else
    echo "script load OK: $s"
  fi
done

cp "$ROOT/project.godot" "$ROOT/export_presets.cfg" "$RUN/"
cp -r "$ROOT/scenes" "$ROOT/scripts" "$ROOT/shaders" "$RUN/"
mkdir -p "$RUN/ASSETS/ARRISA" "$RUN/ASSETS/mixamo"
# Smoke probe dipasang hanya pada harness sementara agar project produksi tidak
# mendapat autoload test. Script tetap berada di scripts/ untuk ikut diverifikasi.
printf '\n[autoload]\nRuntimeSmoke="*res://scripts/runtime_smoke.gd"\n' >> "$RUN/project.godot"
# Hanya aset yang direferensikan loader produksi; video/zip tidak ikut diimpor.
cp "$ROOT"/ASSETS/ARRISA/*.fbx "$RUN/ASSETS/ARRISA/"
cp "$ROOT"/ASSETS/mixamo/* "$RUN/ASSETS/mixamo/"
cp "$BIN" "$RUN/godot-headless"
cd "$RUN" || exit 2
BOOT_FILE="$RUN/.out-boot"
timeout 180 ./godot-headless --headless --quit-after 40 >"$BOOT_FILE" 2>&1
RC=$?
BOOT=$(grep -E "SCRIPT ERROR|Parse Error|treated as error" "$BOOT_FILE" | head -5 || true)
if [ "$RC" -eq 124 ]; then
  echo "BOOT TIMEOUT"; FAIL=1
elif [ -n "$BOOT" ]; then
  echo "BOOT GAGAL:"; echo "$BOOT"; FAIL=1
else
  echo "boot OK: 40 frame tanpa SCRIPT ERROR"
fi

SMOKE_FILE="$RUN/.out-smoke"
ZDEV_RUNTIME_SMOKE=1 timeout 180 ./godot-headless --headless >"$SMOKE_FILE" 2>&1
RC=$?
SMOKE=$(grep -E "smoke FAIL|RUNTIME SMOKE: MERAH|SCRIPT ERROR|Parse Error|treated as error" "$SMOKE_FILE" | head -10 || true)
if [ "$RC" -eq 124 ]; then
  echo "RUNTIME SMOKE TIMEOUT"; FAIL=1
elif [ -n "$SMOKE" ]; then
  echo "RUNTIME SMOKE GAGAL:"; echo "$SMOKE"; FAIL=1
else
  echo "runtime smoke OK"
fi

[ "$FAIL" = "0" ] && echo "VERIFIKASI LOKAL: HIJAU" || echo "VERIFIKASI LOKAL: MERAH"
exit "$FAIL"
