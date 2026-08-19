# Ralph Agent Configuration — Infinity Hunter

Godot 4.7 (GDScript) offline pixel hunting RPG. See `docs/PRD.md` for the full design
and `.ralph/fix_plan.md` for the task queue.

## Prerequisites

- `godot` (4.7+) is on PATH (installed at `~/.local/bin/godot`). Verify: `godot --headless --version`.

## Test Instructions (THE GATE)

```bash
./scripts/test.sh
```

- Exit code **0 = all tests pass**, non-zero = failures (this is the loop's pass/fail gate).
- It (1) rebuilds Godot's global class cache via `--headless --import`, then (2) runs the
  headless suite `res://tests/run_tests.gd`.
- **Every loop that changes code MUST run this and see exit 0 before committing.**

### Writing tests (no external addon)

- Put unit tests in `tests/unit/test_*.gd`.
- Each test file: `extends "res://tests/test_case.gd"` (extend BY PATH — do NOT rely on a
  global `class_name`, the headless runner parses before the class cache is guaranteed).
- Add methods named `test_*`; use the `assert_*` helpers (`assert_eq`, `assert_almost_eq`,
  `assert_true`, ...). The runner auto-discovers them.
- Reference other game classes in tests via `preload("res://…")` when in doubt.

## Build / Import Check

```bash
godot --headless --import        # imports assets, builds class cache; must produce no SCRIPT ERROR
```

## Run Instructions (desktop dev)

```bash
godot --path .                   # opens the project (desktop) for manual play
godot --headless --path . --script res://tests/run_tests.gd   # headless logic run
```

- iOS export is DEFERRED to a dedicated feature-complete milestone (Godot → Xcode → Mac build
  server → TestFlight). Do NOT attempt iOS export during normal loops.

## Project Conventions (read before coding)

- **Language:** GDScript only. No C#.
- **Numbers:** ALL game quantities (HP, XP, damage, level, essence, ...) use the `Big` type
  (`src/core/big.gd`), never raw int/float. It is float-backed for now, swappable to a real
  bignum later without touching call sites.
- **Data-driven:** monsters/weapons/armor/zones/companions are per-entity JSON under `data/`,
  loaded into typed def classes with load-time validation. Do NOT hardcode content in scripts.
- **Layout:** `src/core` (primitives), `src/models` (typed defs), `src/systems` (combat, xp,
  run, save, crafting, capture, meta), `src/data` (loaders/validation), `src/ui` (scenes/scripts).
- **Test-first where practical**; keep game logic in plain classes decoupled from scenes so it
  is headless-testable (the single test seam). Reflex/feel and rendering are NOT unit-tested.

## Notes

- Protected: `.ralph/`, `.ralphrc` (never modify/delete).
- One task per loop; commit working changes; update `.ralph/fix_plan.md` progress.
