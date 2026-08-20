# Placeholder sprite pipeline (AnimatedSprite2D)

> GitHub issue #14 | Labels: P2, ready-for-agent | https://github.com/taigamura/infinity-hunter/issues/14

## What to build
Frame-by-frame `AnimatedSprite2D` pipeline with a FIXED sheet spec (frame size, anim names idle/attack/hit, row-major layout) fed placeholder/proxy frames now. Idle plays continuously ('alive even when idle'); attack/hit trigger from combat events. Polished sheets must drop in later with zero code change.

## Acceptance criteria
- [ ] Documented sheet spec (frame size, anim names, layout) in-repo
- [ ] A monster renders with looping idle + triggered attack/hit anims from a proxy sheet
- [ ] Swapping a proxy sheet for a same-spec real sheet needs no code change
- [ ] Manual-verify in the combat scene; no SCRIPT ERROR on import

## Blocked by
- #13

## Definition of done
- All acceptance criteria met; `./scripts/test.sh` exits 0 (headless gate green); one commit; revert-and-report if you cannot finish cleanly. Follow `.ralph/AGENT.md` conventions (GDScript, `Big` type, data-driven JSON, single logic test seam).

