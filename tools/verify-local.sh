#!/bin/sh
# LAPISAN VERIFIKASI LOKAL (WORKING-AGREEMENT §1 & §3).
# WAJIB HIJAU sebelum push apa pun. Memakai engine headless build lokal
# (tools/godot-headless, Godot 4.7.2-stable custom, x11/wayland/vulkan off).
# Alasan lahir: export Godot TIDAK meng-compile GDScript — bug parse hanya
# kelihatan di device (insiden UAT #3/#4).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/tools/godot-headless"
[ -x "$BIN" ] || { echo "FATAL: tools/godot-headless tidak ada"; exit 2; }
T="$ROOT/.cache/projtest"
rm -rf "$T" && mkdir -p "$T"
cp -r "$ROOT/project.godot" "$ROOT/export_presets.cfg" "$ROOT/scenes" "$ROOT/scripts" "$T/"
cp "$BIN" "$T/"
cd "$T" || exit 2
FAIL=0
for s in main player_controller camera_follow hud floating_joystick ui_button arena_spawner; do
  OUT=$(timeout 60 "$BIN" --headless --check-only --script "res://scripts/$s.gd" 2>&1 | grep -E "SCRIPT ERROR|Parse Error" | head -2)
  if [ -n "$OUT" ]; then echo "PARSE GAGAL: $s"; echo "$OUT"; FAIL=1; else echo "parse OK: $s"; fi
done
BOOT=$(timeout 120 "$BIN" --headless --quit-after 40 2>&1 | grep -E "SCRIPT ERROR" | head -5)
if [ -n "$BOOT" ]; then echo "BOOT GAGAL:"; echo "$BOOT"; FAIL=1; else echo "boot OK: 40 frame tanpa SCRIPT ERROR"; fi
[ "$FAIL" = "0" ] && echo "VERIFIKASI LOKAL: HIJAU" || echo "VERIFIKASI LOKAL: MERAH"
exit "$FAIL"
