# Path-first section generation + visible optimal path + rate-scaling

> GitHub issue #39 | Labels: ready-for-agent, P0 | https://github.com/taigamura/infinity-hunter/issues/39

## Parent

#36 — PRD: Concentric Sections overworld

## What to build

Upgrade `SectionLayout` from simple rings to the real **path-first, then fill** generator,
and render the visible optimal path. Order of operations: (1) place the center camp;
(2) carve a concentric ramping path outward to the outer-ring portal, assigning path
sections gently-rising recommended levels by ring; (3) partition the remaining space into
**variable-size sections** and roll each one's recommended level (loosely correlated with
ring distance); (4) derive each section's `gauge_rate` from its recommended level so
deadlier sections swarm harder. The path is guaranteed traversable and monotonically
non-decreasing in recommended level by construction. The existing dirt-trail tile renderer
is repurposed to draw the path from center camp to portal. Map stays 30x40, 3-4 rings,
~8-14 sections. Degenerate map sizes never hang (bounded retries, like `PoiLayout`).

## Acceptance criteria

- [ ] Generation is path-first: a traversable path of non-decreasing recommended level
      connects center camp to the outer-ring portal every run.
- [ ] Off-path space is partitioned into ~8-14 variable-size sections with rolled levels.
- [ ] Each section's `gauge_rate` scales with its recommended level (deadlier = more fights).
- [ ] The visible optimal path is rendered (repurposed trail tiles) from camp to portal.
- [ ] Section count/sizes fall in the intended ranges; degenerate sizes never hang.
- [ ] `test_section_layout.gd` asserts path existence, monotonic ramp, bounded counts,
      full-cell coverage, and determinism per seed.
- [ ] `./scripts/test.sh` passes.

## Blocked by

- #37

