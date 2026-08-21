#!/usr/bin/env bash
# Files the three ADR-0001 (Deepening Trail) overworld issues to GitHub.
# Run when `gh` has network. Idempotency is on you — running twice files twice.
set -euo pipefail
cd "$(dirname "$0")"

echo "Ensuring labels exist..."
gh label create ready-for-agent --color 0e8a16 2>/dev/null || true
gh label create P0 --color b60205 2>/dev/null || true
gh label create P1 --color d93f0b 2>/dev/null || true

A=$(gh issue create \
  --title "Overworld: Deepening Trail foundation — depth-banded danger, camp spawn, on-trail portal" \
  --label ready-for-agent --label P0 \
  --body-file A-danger-depth-portal-camp.md \
  | grep -oE '[0-9]+$')
echo "Filed foundation as #$A"

# B and C depend on A — note the dependency in their bodies.
{ echo; echo "**Blocked by #$A.**"; } >> B-poi-overlay.md
gh issue create \
  --title "Overworld: points-of-interest overlay — dens, forage, cache, camp, landmark" \
  --label ready-for-agent --label P1 \
  --body-file B-poi-overlay.md
echo "Filed POI overlay (blocked by #$A)"

{ echo; echo "**Blocked by #$A.**"; } >> C-zone-tier-tables-identity.md
gh issue create \
  --title "Overworld: per-zone tier tables + band identity (Cinder Dunes, Frostpeak Ridge)" \
  --label ready-for-agent --label P1 \
  --body-file C-zone-tier-tables-identity.md
echo "Filed zone identity (blocked by #$A)"

echo "Done. Update docs/adr/0001 + CONTEXT.md with the real issue numbers if you like."
