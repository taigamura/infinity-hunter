# Recommended-level UI: on-enter banner + persistent badge + border grace reset

> GitHub issue #38 | Labels: ready-for-agent, P0 | https://github.com/taigamura/infinity-hunter/issues/38

## Parent

#36 — PRD: Concentric Sections overworld

## What to build

The recommended-level UI and fair scouting. When the hunter crosses a section border, an
on-enter **banner** slides in showing the section's name and recommended level, and a
**persistent badge** in a HUD corner shows the current section's recommended level while
the hunter is inside it (reuse the existing hot-strip HUD slot). On every border crossing,
the encounter gauge **resets to 0** so the hunter gets a few safe grace steps to read the
level and retreat before fights can fire. The banner/badge read the section resolved under
the hunter from `SectionLayout`'s cell->section lookup.

## Acceptance criteria

- [ ] Crossing into a new section fires a banner with the section name + recommended level.
- [ ] A persistent HUD badge shows the current section's recommended level while inside it.
- [ ] Crossing a section border resets the encounter gauge to 0 (grace before first fight).
- [ ] Border-crossing detection is driven by `SectionLayout`'s cell->section lookup.
- [ ] The overworld scene smoke test still instantiates headlessly; `./scripts/test.sh` passes.

## Blocked by

- #37

