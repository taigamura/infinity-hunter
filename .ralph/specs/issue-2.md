# Data loader + typed defs + validation

> GitHub issue #2 | Labels: ready-for-agent, P0 | https://github.com/taigamura/infinity-hunter/issues/2

## What to build
JSON content pipeline: per-entity JSON under `data/` loaded into typed def classes (`MonsterDef`, `WeaponDef`, `ArmorDef`, `ZoneDef`, `CompanionDef`, `MaterialDef`) via a loader in `src/data/`, with load-time validation that fails loudly on malformed/missing fields. Foundational prefactor for all content-driven systems.

## Acceptance criteria
- [ ] A loader reads a JSON file into the matching typed def object
- [ ] Each def class has typed fields matching the PRD schemas (all quantities as `Big`/float)
- [ ] Validation rejects missing/mistyped required fields with a clear error naming the file+field
- [ ] Loading a directory returns all defs; duplicate ids are rejected
- [ ] Unit tests cover: valid load, missing-field rejection, bad-type rejection, duplicate-id rejection

## Blocked by
- None - can start immediately

## Definition of done
- All acceptance criteria met; `./scripts/test.sh` exits 0 (headless gate green); one commit; revert-and-report if you cannot finish cleanly. Follow `.ralph/AGENT.md` conventions (GDScript, `Big` type, data-driven JSON, single logic test seam).

