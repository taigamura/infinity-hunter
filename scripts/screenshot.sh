#!/usr/bin/env bash
# Out-of-band visual review harness for Infinity Hunter (issue #28).
#
# Renders every screen scene to a PNG via xvfb-run on the gl_compatibility
# renderer, since a real (virtual) display is required to rasterize a
# viewport -- plain --headless cannot produce pixels. This is NOT part of
# the test gate (./scripts/test.sh); aesthetics are reviewed by a human
# looking at the PNGs, never asserted in code.
#
# Usage:  ./scripts/screenshot.sh [output_dir]
# Requires `godot` (4.7+) and `xvfb-run` on PATH.
set -uo pipefail

cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
OUT_DIR="${1:-.ralph_scratch/screenshots}"
mkdir -p "$OUT_DIR"

# Rebuild class cache (tolerate non-zero / timeout), same as test.sh.
timeout 120 "$GODOT" --headless --import >/dev/null 2>&1 || true

# scene_path|output_name|needs_run  (combat/overworld need a minimal RunState)
SCENES=(
	"res://src/ui/launch/launch_screen.tscn|launch|0"
	"res://src/ui/overworld/overworld_screen.tscn|overworld|1"
	"res://src/ui/combat/combat_screen.tscn|combat|1"
	"res://src/ui/inventory/inventory_screen.tscn|inventory|0"
	"res://src/ui/bestiary/bestiary_screen.tscn|bestiary|0"
	"res://src/ui/meta/meta_screen.tscn|meta|0"
)

status=0
for entry in "${SCENES[@]}"; do
	IFS='|' read -r scene name needs_run <<< "$entry"
	out_path="$(pwd)/$OUT_DIR/${name}.png"
	echo "Rendering $name -> $out_path"
	if ! xvfb-run -a "$GODOT" --path . --rendering-method gl_compatibility \
		--script res://scripts/_screenshot_runner.gd -- "$scene" "$out_path" "$needs_run"; then
		echo "FAILED: $name" >&2
		status=1
	fi
done

exit $status
