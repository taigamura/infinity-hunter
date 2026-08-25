# ADR + CONTEXT/glossary update for the Concentric Sections pivot

> GitHub issue #42 | Labels: P2, ready-for-agent | https://github.com/taigamura/infinity-hunter/issues/42

## Parent

#36 — PRD: Concentric Sections overworld

## What to build

Documentation and decision-record cleanup for the pivot. Write a new ADR that records the
move from the Deepening Trail to the Concentric Sections model and marks ADR-0001 as
superseded. Update `CONTEXT.md` (overworld description, module map entry for `SectionLayout`,
current-state deltas) and the glossary to add "section", "recommended level", "apex/spike
section", and "the path", replacing the retired tier/depth-band vocabulary where stale.

## Acceptance criteria

- [ ] A new ADR under `docs/adr/` records the pivot and marks ADR-0001 superseded.
- [ ] `CONTEXT.md` reflects the section model: overworld run-loop text, `SectionLayout` in
      the module map, and the current-state delta section updated.
- [ ] The glossary carries the new terms and drops/annotates retired tier/depth-band terms.
- [ ] `./scripts/test.sh` passes (docs-only, but keep the gate green).

## Blocked by

- #39
- #38

