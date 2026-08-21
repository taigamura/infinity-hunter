# Overworld: per-zone tier tables + band identity (Cinder Dunes, Frostpeak Ridge)

> Staged (GitHub unreachable at authoring time). Labels: ready-for-agent, P1 | Implements ADR-0001

## Parent / decision

ADR-0001 — Overworld map: the Deepening Trail. **Blocked by #A** (depth-banded foundation).

## What to build

Make the three zones read as distinct places. Today only `data/tiers/verdant_fields.json`
exists, so Cinder Dunes and Frostpeak fall back to a single flat tier. Author their tier tables
and give each zone named terrain bands + a palette, so the Deepening Trail looks different per zone.

**Tier tables for the two missing zones.** Add `data/tiers/cinder_dunes.json` and
`data/tiers/frostpeak_ridge.json` in the same shape as `verdant_fields.json` (tiers `0/1/2`
with `level_min/level_max/gauge_rate/weight/loot_boost`). Level bands must sit inside each
zone's `min_level..max_level` (Cinder 8–25, Frostpeak 25–60). Deeper zones may fill their gauge
a touch faster (higher `gauge_rate`) to reinforce escalating pressure. Load-time validation must
still pass.

**Band names + palette per zone.** Extend the zone data (or a small zone-presentation table) with
per-tier **band names** and a **3-stop palette** so each zone's Deepening Trail reads distinctly:
- Verdant Fields: Meadow → Thicket → Bramble → Thornwall (green → olive → deep red, current).
- Cinder Dunes: e.g. Dunes → Ashflats → Emberfield → Magma Rim (sand → ember → magma).
- Frostpeak Ridge: e.g. Snowfield → Ice Shelf → Glacier → Summit (pale blue → cyan → white-hot).

`OverworldTileset` reads the zone's palette instead of the hardcoded SAFE/MID/HOT constants; the
hot-region warning strip can surface the current band name.

## Acceptance criteria

- [ ] `data/tiers/cinder_dunes.json` and `frostpeak_ridge.json` exist, validate, and their level
      bands fall within each zone's level range
- [ ] Each zone defines per-tier band names + a 3-stop palette; `OverworldTileset` colours from the
      zone palette (not hardcoded constants), keeping jitter + inset border
- [ ] Entering each zone shows its own palette + band naming (verify via `scripts/screenshot.sh`
      renders per zone; human-review, not asserted)
- [ ] Data-loader validation covers the new tier tables + palette fields; bad data fails loudly
- [ ] `./scripts/test.sh` exits 0

## Notes

- Palettes are the identity lever until bespoke tilesets land; keep them readable (safe clearly
  cooler/greener-or-paler than the hot band).
- Depends on #A so the band → depth mapping is in place before per-zone naming is wired to it.
