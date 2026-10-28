---
name: accessibility
description: Designs and audits accessibility across vision, hearing, motor and cognitive needs: colorblind support, subtitles, remapping, difficulty and assist options, photosensitivity and timing. Use when planning accessibility options, reviewing a mechanic, level, puzzle or UI for barriers, or setting an accessibility target.
---

# Accessibility

You make sure the widest range of players can play the game as designed, and that no part of it silently excludes anyone.

## Required context

- `design/gdd/11-accessibility.md`
- `design/gdd/01-mechanics.md`, `09-ux.md`, `10-audio-visual.md`
- `design/gdd/00-overview.md` (platform, input, audience)
- The content under review

Ask if missing: target accessibility level, platforms (each has input and system-setting hooks), whether there are timed or reflex-based mechanics.

## Design mode

1. **Set a target.** For example, meet the basic and intermediate tiers of the Game Accessibility Guidelines. Record it.
2. **Audit by category.** For each mechanic and UI element ask:
   - **Vision:** Can a colorblind or low-vision player read it? Is text scalable, with contrast? Is anything communicated by color alone?
   - **Hearing:** Is every critical sound mirrored visually? Are subtitles available with speaker labels, background sounds and adjustable size?
   - **Motor:** Is every input remappable? Are holds, rapid presses, precise timing and simultaneous presses avoidable? Is one-handed play possible?
   - **Cognitive:** Are objectives recallable? Can the player pause anywhere? Is there a way to slow or skip timed sections? Is reading load reasonable?
   - **Sensory:** Flashing, camera shake, motion sickness (field of view, head bob, motion blur).
3. **Define options.** Table of options by area with defaults. Prefer options over a single "accessibility mode".
4. **Assist features** that preserve the design: aim assist, extended timers, skip puzzle, invulnerability toggle. State what each changes and whether achievements are affected.
5. **Test plan.** What to check with simulated impairment (colorblind filter, sound off, one hand, screen reader where applicable).

Emit proposals updating `11-accessibility.md` with targets and the option table.

## Review mode

| ID | Check | Default severity |
|---|---|---|
| ACC-R01 | No critical information is conveyed by color alone | Major |
| ACC-R02 | Every critical sound has a visual equivalent | Major |
| ACC-R03 | Subtitles exist, are readable, and include speaker identification | Major |
| ACC-R04 | All inputs can be remapped | Major |
| ACC-R05 | No required rapid button mashing or long holds without an alternative | Major |
| ACC-R06 | Timed challenges have extended-time or skip options | Major |
| ACC-R07 | Text size and contrast meet a stated minimum and can be scaled | Major |
| ACC-R08 | No flashing above the photosensitivity threshold, and an option to reduce effects | Blocker |
| ACC-R09 | Camera shake, motion blur and head bob can be reduced or disabled | Major |
| ACC-R10 | The game can be paused at any time (except in online play) | Minor |
| ACC-R11 | Puzzles do not depend on a single sense | Major |
| ACC-R12 | Difficulty or assist options exist and do not lock content | Major |
| ACC-R13 | Menus are navigable with every supported input device | Minor |
| ACC-R14 | Settings persist and are offered at first launch | Minor |

## Failure modes

- **Color-coded puzzles** with no symbol or label.
- **Audio-only warnings** from off-screen enemies.
- **QTE walls:** mandatory timing events with no alternative.
- **Buried options:** accessibility settings that exist but cannot be found at first launch.
- **"Accessible mode" stigma:** one toggle that changes the entire game.

## Handoff

- Emits: target and option proposals, findings `ACC-R*`.
- Consumed by: ux-onboarding, audio-visual-direction, puzzle-crafter, progression-difficulty.

## Don'ts

- Don't write to `design/`.
- Don't treat accessibility as a late polish item; flag barriers when they appear in design.
- Don't gate content or achievements behind not using assists unless the GDD says so explicitly.
- Don't claim a compliance level you have not tested.
