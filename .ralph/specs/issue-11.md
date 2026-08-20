# Meta progression: essence + permanent upgrades

> GitHub issue #11 | Labels: ready-for-agent, P1 | https://github.com/taigamura/infinity-hunter/issues/11

## What to build
`MetaProgression` (`src/systems/`): essence earned = f(peak level reached that run), banked only on a successful (non-death) run end; spendable on a fixed set of MODEST global upgrades (starting level, XP multiplier, hunt count, crit chance, drop rate, capture chance, companion effectiveness). Upgrades must not dominate gear (bounded magnitudes).

## Acceptance criteria
- [ ] Essence award scales with peak level; forfeited on death, banked on retreat/completion
- [ ] Each upgrade purchasable with essence and applies its bounded effect to the next run
- [ ] Upgrade magnitudes are modest (documented caps) so gear remains primary
- [ ] Unit tests: essence formula, bank-vs-forfeit, upgrade purchase + effect, persistence via #5

## Blocked by
- #4
- #5

## Definition of done
- All acceptance criteria met; `./scripts/test.sh` exits 0 (headless gate green); one commit; revert-and-report if you cannot finish cleanly. Follow `.ralph/AGENT.md` conventions (GDScript, `Big` type, data-driven JSON, single logic test seam).

