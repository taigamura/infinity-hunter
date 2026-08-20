# CLAUDE.md

## Orientation (read first)

Before working, read **`CONTEXT.md`** at the repo root: the central design doc
(game identity, architecture, module map, run loop, content, current-state deltas).
It is the fast path to context: prefer it over re-scanning the codebase each session.
When your work makes it stale, update `CONTEXT.md` in the same change.

## Agent skills

### Issue tracker

Issues and PRDs are tracked as GitHub Issues via the `gh` CLI; external PRs are not a triage surface. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
