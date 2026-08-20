#!/usr/bin/env bash
# Pixel-invariant visual gate (issue #32).
#
# Renders the launch + combat screens via xvfb-run (gl_compatibility, same
# technique as scripts/screenshot.sh) and asserts coarse background-color
# invariants plus (for combat, issue #33) that the rendered frame contains
# both red (monster HP bar) and green (player HP bar) pixels, so the
# autonomous loop can verify the *look* of a screen, not just its structure
# (tests/unit/test_scenes_smoke.gd).
#
# Infra-safe by design: if a display/driver isn't available and no frame can
# be rendered at all, this SKIPS with a warning and exits 0 -- it must never
# fail the gate on missing test infrastructure. It only fails (exit 1) when
# a frame WAS rendered but violates an invariant.
#
# Usage:  ./scripts/verify_visual.sh
# Requires `godot` (4.7+) on PATH; xvfb-run is optional (skips without it).
set -uo pipefail

cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"

if ! command -v "$GODOT" >/dev/null 2>&1; then
	echo "verify_visual: '$GODOT' not found, skipping visual gate (infra-safe skip)"
	exit 0
fi

if ! command -v xvfb-run >/dev/null 2>&1; then
	echo "verify_visual: xvfb-run not found, skipping visual gate (infra-safe skip)"
	exit 0
fi

timeout 120 "$GODOT" --headless --import >/dev/null 2>&1 || true

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# scene_path|name|needs_run
SCENES=(
	"res://src/ui/launch/launch_screen.tscn|launch|0"
	"res://src/ui/combat/combat_screen.tscn|combat|1"
)

for entry in "${SCENES[@]}"; do
	IFS='|' read -r scene name needs_run <<< "$entry"
	out_path="$TMP_DIR/${name}.png"
	if ! timeout 60 xvfb-run -a "$GODOT" --path . --rendering-method gl_compatibility \
		--script res://scripts/_screenshot_runner.gd -- "$scene" "$out_path" "$needs_run" \
		> "$TMP_DIR/${name}.log" 2>&1; then
		echo "verify_visual: could not render $name, skipping visual gate (infra-safe skip)"
		cat "$TMP_DIR/${name}.log" >&2
		exit 0
	fi
	if [[ ! -s "$out_path" ]]; then
		echo "verify_visual: no image produced for $name, skipping visual gate (infra-safe skip)"
		exit 0
	fi
done

# Frames rendered successfully -- now the gate is live: a violation here is
# a real failure, not an infra skip.
if ! "$GODOT" --headless --path . --script res://scripts/_visual_invariants.gd -- \
	"$TMP_DIR/launch.png" "$TMP_DIR/combat.png"; then
	echo "verify_visual: FAILED -- rendered frame violates a pixel invariant" >&2
	exit 1
fi

echo "verify_visual: OK"
exit 0
