#!/usr/bin/env bash
# Canonical test gate for Infinity Hunter.
#
# 1. Rebuild Godot's global class cache (needed whenever new `class_name`
#    scripts are added). `--import` occasionally does not self-exit, so it is
#    wrapped in `timeout` and its exit code is deliberately ignored.
# 2. Run the headless test suite. ITS exit code is the gate:
#       0 = all tests passed,  non-0 = failures (or a crash/hang killed by timeout).
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
exit $?
