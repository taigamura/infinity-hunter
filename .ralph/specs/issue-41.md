# Carryover: dens/forage/cache/landmark + per-zone palette tint + section names

> GitHub issue #41 | Labels: ready-for-agent, P1 | https://github.com/taigamura/infinity-hunter/issues/41

## Parent

#36 — PRD: Concentric Sections overworld

## What to build

Re-home the carryover content onto the section map so a zone still feels like itself.
`PoiLayout` (dens, forage, cache, landmark) is retained and placed within the section
layout; dens continue to multiply the local `gauge_rate` via the existing den-bias path.
Sections are tinted from the active zone's palette, and each section is given a generated
name (repurposing the zone's band-name content) that the on-enter banner surfaces.

## Acceptance criteria

- [ ] Dens/forage/cache/landmark POIs are placed on the section map and rendered as today.
- [ ] Standing on/adjacent to a den still boosts the local encounter rate.
- [ ] Sections are tinted using the active zone's palette (fallback palette when absent).
- [ ] Each section has an evocative generated name derived from the zone's band-name content,
      shown in the on-enter banner.
- [ ] `./scripts/test.sh` passes (POI placement + naming covered in the pure-module tests).

## Blocked by

- #39

