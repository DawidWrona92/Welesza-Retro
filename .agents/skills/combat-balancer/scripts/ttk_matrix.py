#!/usr/bin/env python3
"""Time-to-kill matrix across weapons and enemies, with balance flags.

Usage: python3 ttk_matrix.py <combat.json> [--json]

Input:
  {
    "target_ttk": [2.0, 8.0],            # seconds, acceptable band
    "min_damage_fraction": 0.1,          # armor never reduces a hit below this
    "dominance_margin": 0.05,            # how close to best counts as competitive
    "weapons": [{"id": "...", "damage": 12, "shots_per_sec": 2.0,
                 "accuracy": 0.9, "crit_chance": 0.1, "crit_mult": 1.5}],
    "enemies": [{"id": "...", "hp": 120, "armor": 4}]
  }

Model (expected values, no randomness):
  per_hit = max(damage - armor, damage * min_damage_fraction)
  expected_per_hit = per_hit * (1 + crit_chance * (crit_mult - 1))
  dps = expected_per_hit * shots_per_sec * accuracy
  ttk = hp / dps

Flags:
  OUT_OF_BAND  ttk outside target_ttk
  DOMINANT     weapon has the lowest TTK in every matchup
  DEAD         weapon is never within dominance_margin of the best TTK
  ZERO_DAMAGE  dps is 0 against an enemy (immunity by accident)

Exit code is 0 unless input is invalid (2). Flags are reported, not failures,
because some may be intentional.
"""
import json
import sys
from pathlib import Path


def per_hit_damage(weapon, enemy, min_frac):
    dmg = weapon["damage"]
    return max(dmg - enemy.get("armor", 0), dmg * min_frac)


def dps(weapon, enemy, min_frac):
    hit = per_hit_damage(weapon, enemy, min_frac)
    crit_chance = weapon.get("crit_chance", 0.0)
    crit_mult = weapon.get("crit_mult", 1.0)
    expected = hit * (1 + crit_chance * (crit_mult - 1))
    return expected * weapon["shots_per_sec"] * weapon.get("accuracy", 1.0)


def analyze(data):
    weapons = data["weapons"]
    enemies = data["enemies"]
    lo, hi = data.get("target_ttk", [0, float("inf")])
    min_frac = data.get("min_damage_fraction", 0.1)
    margin = data.get("dominance_margin", 0.05)

    matrix = {}
    for w in weapons:
        for e in enemies:
            d = dps(w, e, min_frac)
            matrix[(w["id"], e["id"])] = {
                "dps": d,
                "ttk": (e["hp"] / d) if d > 0 else float("inf"),
            }

    flags = []
    best_per_enemy = {}
    for e in enemies:
        best_per_enemy[e["id"]] = min(matrix[(w["id"], e["id"])]["ttk"] for w in weapons)

    for (wid, eid), cell in matrix.items():
        if cell["dps"] <= 0:
            flags.append(("ZERO_DAMAGE", wid, eid, "weapon cannot hurt this enemy"))
        elif not (lo <= cell["ttk"] <= hi):
            flags.append(("OUT_OF_BAND", wid, eid, f"ttk {cell['ttk']:.2f}s outside [{lo}, {hi}]"))

    if len(weapons) > 1:
        for w in weapons:
            wins_all = all(
                matrix[(w["id"], e["id"])]["ttk"] <= best_per_enemy[e["id"]] + 1e-9
                and all(
                    matrix[(w["id"], e["id"])]["ttk"] < matrix[(o["id"], e["id"])]["ttk"] - 1e-9
                    for o in weapons if o["id"] != w["id"]
                )
                for e in enemies
            )
            if wins_all:
                flags.append(("DOMINANT", w["id"], "*", "lowest TTK against every enemy"))
            competitive = any(
                matrix[(w["id"], e["id"])]["ttk"] <= best_per_enemy[e["id"]] * (1 + margin)
                for e in enemies
            )
            if not competitive:
                flags.append(("DEAD", w["id"], "*", f"never within {margin:.0%} of the best TTK"))
    return matrix, flags


def render(data, matrix, flags):
    weapons = [w["id"] for w in data["weapons"]]
    enemies = [e["id"] for e in data["enemies"]]
    width = max([len(w) for w in weapons] + [8]) + 2
    col = max([len(e) for e in enemies] + [8]) + 2
    lines = ["TTK matrix (seconds)", ""]
    lines.append("".ljust(width) + "".join(e.ljust(col) for e in enemies))
    for w in weapons:
        row = w.ljust(width)
        for e in enemies:
            ttk = matrix[(w, e)]["ttk"]
            row += ("inf" if ttk == float("inf") else f"{ttk:.2f}").ljust(col)
        lines.append(row)
    lines.append("")
    if flags:
        lines.append("Flags")
        for kind, w, e, msg in flags:
            lines.append(f"  {kind:<12} {w} vs {e}: {msg}")
    else:
        lines.append("Flags: none")
    return "\n".join(lines)


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    as_json = "--json" in argv
    if len(args) != 1:
        print(__doc__)
        return 2
    path = Path(args[0])
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        matrix, flags = analyze(data)
    except (OSError, json.JSONDecodeError, KeyError, TypeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    if as_json:
        out = {
            "matrix": {f"{w}|{e}": c for (w, e), c in matrix.items()},
            "flags": [{"kind": k, "weapon": w, "enemy": e, "message": m} for k, w, e, m in flags],
        }
        print(json.dumps(out, indent=2, default=lambda v: None if v == float("inf") else v))
    else:
        print(render(data, matrix, flags))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
