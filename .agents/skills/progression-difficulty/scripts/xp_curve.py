#!/usr/bin/env python3
"""XP curve generator with pacing analysis.

Usage:
  python3 xp_curve.py --levels 1-30 --kind exp --base 100 --growth 1.15 \
      --xp-per-hour 3000 --xp-rate-growth 1.12 --session-min 45 [--target-hours 40] [--json]

Options:
  --levels A-B          level range (default 1-30); XP shown is cost to go from L to L+1
  --kind linear|poly|exp
  --base N              XP cost at the first level (default 100)
  --growth G            exp: cost(L) = base * G^(L-first)   (default 1.15)
  --power P             poly: cost(L) = base * (L-first+1)^P (default 2.0)
  --step S              linear: cost(L) = base + S*(L-first) (default base)
  --xp-per-hour R       XP earned per hour of play at the first level (default 3000)
  --xp-rate-growth G2   per-level multiplier on XP earned per hour (default 1.0)
  --session-min M       session length in minutes (default 45)
  --target-hours H      desired total hours to reach the last level
  --json                machine-readable output

Flags:
  WALL      level takes more than 2x as long as the previous level
  TRIVIAL   level takes under 2 minutes (skipping past it feels free)
  SESSION   a single level takes more than 3 sessions
  TARGET    total time misses --target-hours by more than 15%
"""
import json
import sys


def parse_args(argv):
    opts = {
        "levels": "1-30", "kind": "exp", "base": 100.0, "growth": 1.15, "power": 2.0,
        "step": None, "xp_per_hour": 3000.0, "xp_rate_growth": 1.0, "session_min": 45.0,
        "target_hours": None, "json": False,
    }
    i = 1
    while i < len(argv):
        a = argv[i]
        if a == "--json":
            opts["json"] = True
            i += 1
            continue
        if not a.startswith("--"):
            raise ValueError(f"unexpected argument {a}")
        key = a[2:].replace("-", "_")
        if key not in opts or i + 1 >= len(argv):
            raise ValueError(f"unknown or incomplete option {a}")
        val = argv[i + 1]
        opts[key] = val if key in ("levels", "kind") else float(val)
        i += 2
    return opts


def cost(opts, level, first):
    n = level - first
    if opts["kind"] == "exp":
        return opts["base"] * opts["growth"] ** n
    if opts["kind"] == "poly":
        return opts["base"] * (n + 1) ** opts["power"]
    if opts["kind"] == "linear":
        step = opts["step"] if opts["step"] is not None else opts["base"]
        return opts["base"] + step * n
    raise ValueError("kind must be linear, poly or exp")


def build(opts):
    first, last = (int(x) for x in opts["levels"].split("-"))
    if last <= first:
        raise ValueError("level range must have at least two levels")
    rows, cum, total_hours = [], 0.0, 0.0
    prev_hours = None
    flags = []
    for lvl in range(first, last):
        xp = cost(opts, lvl, first)
        rate = opts["xp_per_hour"] * opts["xp_rate_growth"] ** (lvl - first)
        hours = xp / rate
        cum += xp
        total_hours += hours
        minutes = hours * 60
        rows.append({
            "level": lvl, "xp_to_next": xp, "cumulative_xp": cum,
            "hours": hours, "minutes": minutes, "sessions": minutes / opts["session_min"],
            "cumulative_hours": total_hours,
        })
        if prev_hours and hours > 2 * prev_hours:
            flags.append(("WALL", lvl, f"{hours:.2f}h is {hours / prev_hours:.1f}x the previous level"))
        if minutes < 2:
            flags.append(("TRIVIAL", lvl, f"{minutes:.1f} minutes"))
        if minutes / opts["session_min"] > 3:
            flags.append(("SESSION", lvl, f"{minutes / opts['session_min']:.1f} sessions for one level"))
        prev_hours = hours
    th = opts["target_hours"]
    if th:
        miss = (total_hours - th) / th
        if abs(miss) > 0.15:
            flags.append(("TARGET", "*", f"total {total_hours:.1f}h vs target {th:.1f}h ({miss:+.0%})"))
    return rows, flags, total_hours


def render(rows, flags, total_hours):
    out = [f"{'Lvl':>4} {'XP to next':>12} {'Cumulative':>12} {'Hours':>8} {'Sessions':>9}"]
    for r in rows:
        out.append(
            f"{r['level']:>4} {r['xp_to_next']:>12,.0f} {r['cumulative_xp']:>12,.0f} "
            f"{r['hours']:>8.2f} {r['sessions']:>9.2f}"
        )
    out.append("")
    out.append(f"Total time to final level: {total_hours:.1f} hours")
    out.append("")
    if flags:
        out.append("Flags")
        for kind, lvl, msg in flags:
            out.append(f"  {kind:<8} level {lvl}: {msg}")
    else:
        out.append("Flags: none")
    return "\n".join(out)


def main(argv):
    try:
        opts = parse_args(argv)
        rows, flags, total = build(opts)
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        print(__doc__)
        return 2
    if opts["json"]:
        print(json.dumps({
            "rows": rows, "total_hours": total,
            "flags": [{"kind": k, "level": l, "message": m} for k, l, m in flags],
        }, indent=2))
    else:
        print(render(rows, flags, total))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
