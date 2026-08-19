# Big — the single numeric type for ALL game quantities (HP, XP, damage,
# level thresholds, essence, etc.). Backed by a plain float (double) for the
# MVP, which holds exact integers up to 2^53 (~9.0e15) — comfortably above the
# design's stated ranges (level ~1e10, zone levels ~1e6).
#
# WHY THIS EXISTS: every game-quantity field routes through Big so that if we
# ever need true unbounded scaling (mantissa+exponent), we swap this one type's
# internals without touching call sites. DO NOT use raw int/float for game
# quantities elsewhere — always Big.
#
# For the MVP, Big is a thin static helper over float. Callers store `float`
# values (typed as such) and use these helpers for formatting/scaling. When we
# outgrow float, this becomes a struct and the helpers gain real implementations.
class_name Big
extends RefCounted

# Precision ceiling of the float backing. Above this, integer math loses
# precision and we must migrate to a real bignum. Systems can assert against it.
const SAFE_MAX := 9.0e15

# Format a Big value for UI display with short suffixes (K, M, B, T, ...).
# Large readable damage numbers are a design pillar (design doc §16).
static func fmt(v: float) -> String:
	var neg := v < 0.0
	var a := absf(v)
	var s := ""
	if a < 1000.0:
		# Show integers without decimals, small fractionals with one.
		s = str(int(round(a))) if a == floor(a) else String.num(a, 1)
	else:
		var suffixes := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
		var tier := int(floor(log(a) / log(1000.0)))
		tier = clampi(tier, 0, suffixes.size() - 1)
		var scaled := a / pow(1000.0, tier)
		# Fixed 2 decimals (1.50K, not 1.5K) — reads cleaner in a rolling counter.
		s = "%.2f%s" % [scaled, suffixes[tier]]
	return ("-" + s) if neg else s

# True if a value is still within safe float-integer precision.
static func is_safe(v: float) -> bool:
	return absf(v) <= SAFE_MAX
