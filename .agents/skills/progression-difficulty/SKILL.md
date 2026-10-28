---
name: progression-difficulty
description: Designs and audits progression and difficulty: XP curves, level caps, unlock pacing, power spikes, difficulty ramps and flow state. Use when setting XP requirements, time to level, unlock schedules or difficulty options, or when checking for walls, power spikes, pacing flatness and unfair difficulty swings. Computes curves with a script.
---

# Progression & Difficulty

You keep the player in the flow state: challenge rising just ahead of skill, with rewards and unlocks arriving at a steady, readable rhythm.

## Required context

- `design/gdd/07-progression.md`
- `design/gdd/00-overview.md` (session length, audience)
- `design/gdd/05-combat.md`, `06-economy.md`
- Registry: `SKL`, `ITM`, `ZON`

Ask if missing: level cap, target time to cap, average session length, expected income of XP per hour at level 1.

## Rule: compute curves with the script

```bash
python3 scripts/xp_curve.py --levels 1-30 --kind exp --base 1000 --growth 1.15 \
  --xp-per-hour 3000 --xp-rate-growth 1.13 --session-min 45
```

Options:

- `--kind linear|poly|exp` with `--base`, `--growth` (exp), `--power` (poly)
- `--xp-per-hour`: XP earned per hour at level 1
- `--xp-rate-growth`: how much faster the player earns XP per level (enemies and quests give more)
- `--session-min`: session length, to report sessions per level
- `--target-hours`: desired total hours to cap; the script reports the miss

The script prints XP per level, cumulative XP, hours per level, sessions per level, and flags walls (a level taking much longer than the last), trivial levels (under two minutes), and the miss against the target.

## Design mode

1. **Set targets.** Hours to cap, level time at start, middle and end, number of levels.
2. **Choose a curve.** Linear for short games, polynomial for steady growth, exponential when income also scales. Justify the choice against pacing.
3. **Model the income.** XP per hour grows with level. Without this, exponential curves become walls.
4. **Run the script** and tune until flagged levels are intentional.
5. **Unlock schedule.** Schedule a new verb, ability or area every N minutes. Each unlock needs a teaching moment. The unlock rhythm should be steadier than the XP curve.
6. **Power spikes and gates.** Mark where power jumps (new weapon tier) and where hard gates exist (boss, story). Smooth spikes with intermediate rewards.
7. **Difficulty curve.** For each stage: intended challenge, expected player power, expected failures per encounter. Overlay power and challenge; they should track each other with challenge slightly ahead.
8. **Difficulty options.** Presets (Story, Normal, Hard) with explicit modifiers, plus adaptive systems if any (and a way to opt out). Never lock rewards or story behind a difficulty.
9. **Recovery.** After a hard section, a breather; after repeated failure, an assist.

Emit proposals updating `07-progression.md` with curve inputs and outputs.

## Review mode

| ID | Check | Default severity |
|---|---|---|
| PRG-R01 | A script run exists and matches the proposed numbers | Blocker |
| PRG-R02 | Total time to cap matches the target | Major |
| PRG-R03 | No level takes more than twice as long as the previous without a reason | Major |
| PRG-R04 | No trivial levels (under two minutes) in the middle of the curve | Minor |
| PRG-R05 | Each unlock is taught before it is tested | Major |
| PRG-R06 | Unlock rhythm is steady; no long droughts | Major |
| PRG-R07 | Power spikes are intentional and signposted | Major |
| PRG-R08 | Challenge tracks power: the player is neither overpowered nor walled for long | Major |
| PRG-R09 | Difficulty options change numbers, not content or rewards | Major |
| PRG-R10 | A player who dies repeatedly gets help | Minor |
| PRG-R11 | Over-leveling by farming cannot trivialize the game | Major |
| PRG-R12 | Under-leveling by skipping content does not make the game unfinishable | Major |
| PRG-R13 | Sessions end at natural stopping points | Minor |

## Failure modes

- **The grind wall:** exponential curve with flat income.
- **The cliff:** a boss that demands a level the player has not reached.
- **Over-leveling:** farming makes challenge disappear.
- **Flat curve:** every level feels the same.
- **Punishing hard mode:** hard mode is only bigger numbers.

Probe with the **completionist** (does everything, becomes overpowered) and the **speedrunner** (skips, becomes underpowered).

## Handoff

- Emits: curve proposals, unlock schedules, findings `PRG-R*`.
- Consumed by: combat-balancer, economy-designer, level-designer, ux-onboarding, playtest-simulator.

## Don'ts

- Don't write to `design/`.
- Don't estimate curves by hand. Run the script.
- Don't gate story or rewards behind difficulty.
- Don't add unlocks without a teaching moment.
