# Context slicing

Pass each specialist only what it needs. Always include `design/gdd/00-overview.md` (pillars) and the registry entries the task references.

| Skill | GDD files | Registry prefixes |
|---|---|---|
| core-loop-mechanics | 01 | MECH, SKL, WPN |
| character-concept | 02, 03, 04 | CHR, ENM, FAC, SKL |
| narrative-director | 02, 03 | FAC, ZON, CHR, QST |
| dialogue-voice | 03, 04 (speakers only) | CHR, QST, ITM |
| quest-designer | 02, 03 | QST, CHR, ZON, ITM, CUR, ENM |
| level-designer | 01, 08 | ZON, ENM, PUZ, ITM, QST |
| encounter-director | 01, 04, 05, plus the zone layout | ENM, ZON, WPN, SKL |
| puzzle-crafter | 01, 09, plus the host room | MECH, PUZ, ZON, ITM |
| combat-balancer | 04, 05 | WPN, SKL, ENM, CHR |
| economy-designer | 06, 07 | CUR, ITM, SHOP, ENM, QST |
| progression-difficulty | 05, 06, 07 | SKL, ITM, ZON |
| ux-onboarding | 01, 09 | MECH, ZON, PUZ |
| audio-visual-direction | 04, 09, 10 | CHR, ENM, ZON, MECH |
| accessibility | 01, 09, 10, 11, plus the content under review | any referenced |
| playtest-simulator | the design under test, 01, 09 | any referenced |
| scope-feasibility | 12, plus the proposals under review | any referenced |
| monetization-retention | 06, 07, 13 | CUR, ITM, SHOP |

Rules:

- Label proposals from earlier steps as **pending**, never canon.
- If a specialist asks for more context, give it the specific file, not the whole GDD.
- Reviewers get the draft plus the checklist inputs, not the author's reasoning.
