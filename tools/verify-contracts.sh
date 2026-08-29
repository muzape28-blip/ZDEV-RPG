#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAIL=0
check() {
  local label="$1"
  local command="$2"
  if eval "$command"; then
    echo "contract OK: $label"
  else
    echo "contract FAIL: $label"
    FAIL=1
  fi
}

check "camera arm node" "grep -q '\[node name=\"CameraArm\" type=\"SpringArm3D\" parent=\"Player/CameraPivot\"\]' '$ROOT/scenes/main.tscn'"
check "camera direct child" "grep -q 'parent=\"Player/CameraPivot/CameraArm\"' '$ROOT/scenes/main.tscn'"
check "camera local yaw" "grep -q 'return rotation.y' '$ROOT/scripts/camera_follow.gd'"
check "camera excludes player" "grep -q 'arm.add_excluded_object' '$ROOT/scripts/camera_follow.gd'"
check "camera pitch look guard" "grep -q 'view_dir.length_squared' '$ROOT/scripts/camera_follow.gd'"
check "camera-relative movement" "grep -q 'fwd \* -move_input.y' '$ROOT/scripts/player_controller.gd'"
check "neutral dodge away from camera" "grep -q 'cam_node.global_position - global_position' '$ROOT/scripts/player_controller.gd'"
check "dodge i-frame guard" "grep -q 'if dash_timer > 0.0' '$ROOT/scripts/player_controller.gd'"
check "dummy non-physical" "grep -q 'collision_layer = 0' '$ROOT/scripts/dummy.gd' && grep -q 'collision_mask = 0' '$ROOT/scripts/dummy.gd'"
check "terrain has relief" "grep -q '@export var amplitude := 2.4' '$ROOT/scripts/terrain_generator.gd'"
check "heightmap collider" "grep -q 'HeightMapShape3D.new' '$ROOT/scripts/terrain_generator.gd'"
check "terrain shader wired" "grep -q 'res://shaders/terrain.gdshader' '$ROOT/scripts/terrain_generator.gd'"
check "trees default off" "grep -q '@export var spawn_trees := false' '$ROOT/scripts/arena_spawner.gd'"
check "no deprecated color enum" "! grep -RIn 'COLOR_8BIT' '$ROOT/scripts' '$ROOT/scenes' '$ROOT/shaders' | grep -vE '#.*COLOR_8BIT'"
check "all shader resources" "test -f '$ROOT/shaders/terrain.gdshader' && test -f '$ROOT/shaders/sky_sun.gdshader'"
check "no diff whitespace error" "cd '$ROOT' && git diff --check"
exit "$FAIL"
