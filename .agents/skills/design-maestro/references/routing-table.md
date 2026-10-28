# Routing table

Each chain lists specialists in order. "D" = Design mode, "R" = Review mode. Steps joined by `+` can run in parallel.

## Content workflows

| Request | Chain |
|---|---|
| **New dungeon / level** | level-designer D → encounter-director D + puzzle-crafter D → character-concept D (boss, if any) → quest-designer D (if tied) → economy-designer D (rewards) → R: level-designer, encounter-director, playtest-simulator, ux-onboarding, scope-feasibility |
| **New enemy** | character-concept D → combat-balancer D → encounter-director D (placement) → audio-visual-direction D → R: combat-balancer, audio-visual-direction, accessibility |
| **New boss** | character-concept D → encounter-director D → combat-balancer D → narrative-director D (if story-relevant) → economy-designer D (drops) → R: encounter-director, combat-balancer, playtest-simulator |
| **New quest or quest line** | narrative-director D (if arc-level) → quest-designer D → dialogue-voice D → level-designer D (if new space) → economy-designer D (rewards) → R: quest-designer, dialogue-voice, playtest-simulator |
| **New puzzle** | puzzle-crafter D → ux-onboarding D (hint and feedback) → R: puzzle-crafter, playtest-simulator, accessibility |
| **New character (NPC)** | character-concept D → dialogue-voice D → audio-visual-direction D → R: character-concept, dialogue-voice |
| **New mechanic** | core-loop-mechanics D → ux-onboarding D → combat-balancer D or economy-designer D (if numbers) → R: core-loop-mechanics, ux-onboarding, playtest-simulator, scope-feasibility |
| **Story or world bible** | narrative-director D → character-concept D → dialogue-voice D (tone samples) → R: narrative-director |
| **First 10 minutes / tutorial** | ux-onboarding D → level-designer D → puzzle-crafter D (if teaching puzzles) → R: ux-onboarding, playtest-simulator, accessibility |

## Systems workflows

| Request | Chain |
|---|---|
| **Rebalance weapons or abilities** | combat-balancer D → R: combat-balancer, playtest-simulator |
| **Build or tune the economy** | economy-designer D → progression-difficulty D → R: economy-designer, progression-difficulty, monetization-retention (if F2P) |
| **XP curve and unlocks** | progression-difficulty D → R: progression-difficulty, ux-onboarding |
| **Difficulty tuning** | progression-difficulty D + combat-balancer D → R: playtest-simulator, accessibility |
| **Monetization plan** | monetization-retention D → economy-designer D → R: monetization-retention, economy-designer, accessibility |

## Audit workflows (Review only)

| Request | Chain |
|---|---|
| **Audit this level** | R: level-designer, encounter-director, puzzle-crafter, playtest-simulator, ux-onboarding, accessibility |
| **Audit the economy** | R: economy-designer, progression-difficulty, monetization-retention |
| **Audit combat** | R: combat-balancer, encounter-director, playtest-simulator |
| **Audit the narrative** | R: narrative-director, quest-designer, dialogue-voice, character-concept |
| **Pre-release audit** | R: every specialist on its GDD file, then consolidate by severity |
| **Is this feasible?** | R: scope-feasibility |

## Direct routes (skip the loop)

For narrow single-skill requests, route straight to the specialist in the requested mode. Still use the proposal and finding formats. Still send results through gdd-owner if canon changes.

## Rules

- Always add `playtest-simulator` R for content a player walks through.
- Always add `accessibility` R when a change affects input, color, audio, or timing.
- If the registry does not contain something the chain needs (for example no zone for a quest), add the creator to the chain or ask the user.
