#!/usr/bin/env python3
"""Monte Carlo economy simulator.

Usage: python3 economy_sim.py <economy.json> [--runs N] [--seed S] [--json]

Input:
  {
    "horizon_hours": 40,
    "tick_hours": 0.1,                         # optional
    "currencies": ["CUR-gold"],
    "sources": [{"id": "...", "currency": "CUR-gold", "attempts_per_hour": 60,
                 "chance": 0.8, "amount": [3, 7]}],       # amount: number or [lo, hi]
    "sinks":   [{"id": "...", "currency": "CUR-gold", "per_hour": 80}],
    "goals":   [{"id": "ITM-x", "currency": "CUR-gold", "cost": 500}],
    "max_goal_gap_hours": 4,
    "max_inflation_ratio": 3.0,
    "start_balance": {"CUR-gold": 0}
  }

Model: each tick, every source attempts (attempts_per_hour * tick) times
(Poisson-style rounding), each attempt succeeds with `chance` and pays `amount`.
Sinks drain `per_hour * tick` (balance floors at zero; the unmet part is counted
as unmet_sink). Goals are bought in listed order once affordable.

Flags:
  NO_SOURCE        currency has no source
  NO_SINK          currency has no sink and no goal spends it
  INFLATION        total income / total spend above max_inflation_ratio
  GOAL_UNREACHED   goal not bought within the horizon in more than half the runs
  GRIND_WALL       gap between consecutive goals above max_goal_gap_hours (median)
  DOMINANT_SOURCE  one source provides over 70% of income in a currency
  UNMET_SINKS      mandatory sinks could not be paid in more than 25% of ticks

Exit code is 0 unless input is invalid (2).
"""
import json
import math
import random
import statistics
import sys
from pathlib import Path


def _amount(rng, spec):
    if isinstance(spec, list):
        return rng.uniform(spec[0], spec[1])
    return float(spec)


def _events(rng, mean):
    """Integer number of attempts with the right expectation."""
    base = int(math.floor(mean))
    frac = mean - base
    return base + (1 if rng.random() < frac else 0)


def run_once(data, seed):
    rng = random.Random(seed)
    tick = data.get("tick_hours", 0.1)
    horizon = data["horizon_hours"]
    steps = int(round(horizon / tick))
    balance = {c: float(data.get("start_balance", {}).get(c, 0)) for c in data["currencies"]}
    income = {c: 0.0 for c in data["currencies"]}
    income_by_source = {}
    spent = {c: 0.0 for c in data["currencies"]}
    unmet_ticks = 0
    goal_idx = 0
    goal_times = {}
    goals = data.get("goals", [])
    checkpoints = {}
    cp_hours = sorted({max(1, int(horizon * f)) for f in (0.1, 0.25, 0.5, 0.75, 1.0)})

    for step in range(1, steps + 1):
        t = step * tick
        for s in data.get("sources", []):
            attempts = _events(rng, s["attempts_per_hour"] * tick)
            for _ in range(attempts):
                if rng.random() < s.get("chance", 1.0):
                    amt = _amount(rng, s["amount"])
                    balance[s["currency"]] += amt
                    income[s["currency"]] += amt
                    income_by_source[(s["currency"], s["id"])] = income_by_source.get(
                        (s["currency"], s["id"]), 0.0
                    ) + amt
        unmet = False
        for k in data.get("sinks", []):
            due = k["per_hour"] * tick
            paid = min(due, balance[k["currency"]])
            balance[k["currency"]] -= paid
            spent[k["currency"]] += paid
            if paid < due - 1e-9:
                unmet = True
        if unmet:
            unmet_ticks += 1
        while goal_idx < len(goals) and balance[goals[goal_idx]["currency"]] >= goals[goal_idx]["cost"]:
            g = goals[goal_idx]
            balance[g["currency"]] -= g["cost"]
            spent[g["currency"]] += g["cost"]
            goal_times[g["id"]] = t
            goal_idx += 1
        for h in cp_hours:
            if abs(t - h) < tick / 2:
                checkpoints[h] = dict(balance)

    return {
        "balance": balance,
        "income": income,
        "spent": spent,
        "income_by_source": income_by_source,
        "goal_times": goal_times,
        "unmet_ratio": unmet_ticks / steps,
        "checkpoints": checkpoints,
    }


def pct(values, p):
    if not values:
        return None
    values = sorted(values)
    k = (len(values) - 1) * p
    lo, hi = int(math.floor(k)), int(math.ceil(k))
    if lo == hi:
        return values[lo]
    return values[lo] + (values[hi] - values[lo]) * (k - lo)


def analyze(data, runs, seed):
    results = [run_once(data, seed + i) for i in range(runs)]
    currencies = data["currencies"]
    flags = []
    source_currencies = {s["currency"] for s in data.get("sources", [])}
    sink_currencies = {k["currency"] for k in data.get("sinks", [])} | {
        g["currency"] for g in data.get("goals", [])
    }
    for c in currencies:
        if c not in source_currencies:
            flags.append(("NO_SOURCE", c, "no source produces this currency"))
        if c not in sink_currencies:
            flags.append(("NO_SINK", c, "nothing spends this currency"))

    summary = {"currencies": {}, "goals": [], "runs": runs, "seed": seed}
    max_infl = data.get("max_inflation_ratio", 3.0)
    for c in currencies:
        inc = [r["income"][c] for r in results]
        sp = [r["spent"][c] for r in results]
        bal = [r["balance"][c] for r in results]
        med_inc, med_sp = statistics.median(inc), statistics.median(sp)
        ratio = (med_inc / med_sp) if med_sp > 0 else float("inf")
        summary["currencies"][c] = {
            "income_median": med_inc,
            "spent_median": med_sp,
            "final_balance_median": statistics.median(bal),
            "final_balance_p10": pct(bal, 0.1),
            "final_balance_p90": pct(bal, 0.9),
            "income_to_spend": ratio,
        }
        if c in source_currencies and ratio > max_infl:
            flags.append(("INFLATION", c, f"income/spend {ratio:.2f} exceeds {max_infl}"))
        shares = {}
        for r in results:
            for (cc, sid), amt in r["income_by_source"].items():
                if cc == c:
                    shares[sid] = shares.get(sid, 0.0) + amt
        total = sum(shares.values())
        if total > 0 and len(shares) > 1:
            top_id, top_amt = max(shares.items(), key=lambda kv: kv[1])
            if top_amt / total > 0.7:
                flags.append(("DOMINANT_SOURCE", c, f"{top_id} provides {top_amt / total:.0%} of income"))

    goals = data.get("goals", [])
    gap_limit = data.get("max_goal_gap_hours", 4)
    prev_median = 0.0
    for g in goals:
        times = [r["goal_times"][g["id"]] for r in results if g["id"] in r["goal_times"]]
        reached = len(times) / runs
        entry = {
            "id": g["id"], "cost": g["cost"], "reached": reached,
            "p10": pct(times, 0.1), "median": pct(times, 0.5), "p90": pct(times, 0.9),
        }
        summary["goals"].append(entry)
        if reached < 0.5:
            flags.append(("GOAL_UNREACHED", g["id"], f"bought in only {reached:.0%} of runs within the horizon"))
        elif entry["median"] is not None:
            gap = entry["median"] - prev_median
            if gap > gap_limit:
                flags.append(("GRIND_WALL", g["id"], f"{gap:.1f}h after the previous goal (limit {gap_limit}h)"))
            prev_median = entry["median"]

    unmet = statistics.median([r["unmet_ratio"] for r in results])
    summary["unmet_sink_ratio_median"] = unmet
    if unmet > 0.25:
        flags.append(("UNMET_SINKS", "*", f"mandatory sinks unpaid in {unmet:.0%} of ticks"))
    return summary, flags


def render(summary, flags):
    out = [f"Economy simulation: {summary['runs']} runs, seed {summary['seed']}", ""]
    out.append("Currencies")
    for c, s in summary["currencies"].items():
        ratio = "inf" if s["income_to_spend"] == float("inf") else f"{s['income_to_spend']:.2f}"
        out.append(
            f"  {c}: income {s['income_median']:.0f}, spent {s['spent_median']:.0f}, "
            f"final balance {s['final_balance_median']:.0f} "
            f"(p10 {s['final_balance_p10']:.0f}, p90 {s['final_balance_p90']:.0f}), income/spend {ratio}"
        )
    out.append("")
    out.append("Goals (hours to afford)")
    for g in summary["goals"]:
        if g["median"] is None:
            out.append(f"  {g['id']} (cost {g['cost']}): not reached")
        else:
            out.append(
                f"  {g['id']} (cost {g['cost']}): median {g['median']:.1f}h "
                f"(p10 {g['p10']:.1f}, p90 {g['p90']:.1f}), reached {g['reached']:.0%}"
            )
    out.append("")
    if flags:
        out.append("Flags")
        for kind, subject, msg in flags:
            out.append(f"  {kind:<16} {subject}: {msg}")
    else:
        out.append("Flags: none")
    return "\n".join(out)


def main(argv):
    runs, seed = 200, 1
    args, i = [], 1
    while i < len(argv):
        a = argv[i]
        if a == "--runs":
            runs = int(argv[i + 1]); i += 2
        elif a == "--seed":
            seed = int(argv[i + 1]); i += 2
        elif a.startswith("--"):
            i += 1
        else:
            args.append(a); i += 1
    if len(args) != 1:
        print(__doc__)
        return 2
    try:
        data = json.loads(Path(args[0]).read_text(encoding="utf-8"))
        summary, flags = analyze(data, runs, seed)
    except (OSError, json.JSONDecodeError, KeyError, TypeError, ValueError, IndexError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    if "--json" in argv:
        print(json.dumps({"summary": summary, "flags": [
            {"kind": k, "subject": s, "message": m} for k, s, m in flags
        ]}, indent=2, default=lambda v: None if v == float("inf") else v))
    else:
        print(render(summary, flags))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
