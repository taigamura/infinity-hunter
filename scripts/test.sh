#!/usr/bin/env bash
# Canonical test gate for Infinity Hunter.
#
# 1. Rebuild Godot's global class cache (needed whenever new `class_name`
#    scripts are added). `--import` occasionally does not self-exit, so it is
#    wrapped in `timeout` and its exit code is deliberately ignored.
# 2. Run the headless test suite. ITS exit code determines whether the
#    second stage runs.
# 3. Run the pixel-invariant visual gate (scripts/verify_visual.sh, issue
#    #32). It is infra-safe (skips with exit 0 if no frame can be rendered)
#    so it only fails the overall gate on an actual rendered violation.
#
# Usage:  ./scripts/test.sh
# Requires `godot` (4.7+) on PATH.
set -uo pipefail

cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"

# Step 1: build class cache (tolerate non-zero / timeout).
timeout 120 "$GODOT" --headless --import >/dev/null 2>&1 || true

# Step 2: run tests; the script quits 0 (pass) or 1 (fail).
timeout 180 "$GODOT" --headless --path . --script res://tests/run_tests.gd
unit_status=$?
if [[ $unit_status -ne 0 ]]; then
	exit $unit_status
fi

# Step 3: visual gate.
"$(dirname "$0")/verify_visual.sh"
exit $?
