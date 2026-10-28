# Welesza — projekt gry (bez grafiki)

Dark fantasy ARPG: przypadkowy podróżnik trafia do Niemiru, osady ukrytej w groźnym lesie. PC, single player, kamera i sterowanie inspirowane Diablo 2; wymagająca walka z niewieloma groźnymi przeciwnikami. Silnik: **Godot 4** ([decyzja warunkowa](docs/SILNIK.md)).

To repozytorium zawiera **wszystko poza grafiką**: fabułę, postacie (w tym bohatera), bestiariusz, mechaniki, walkę, mapę świata, grafy poziomów, walidator mapy i skille projektowe.
Grafika (kontrakt renderu, modele, tekstury, koncepty, art direction Niemiru, skille graficzne) została w [RPG-OldSchool](https://github.com/DawidWrona92/RPG-OldSchool). Linki do tych materiałów w dokumentach prowadzą tam.

Pełny spis: [docs/INDEX.md](docs/INDEX.md).

## Walidacja mapy świata

```bash
python3 tools/world/validate_world.py docs/world/world-layout.v0.2.json
python3 -m unittest discover -s tests -p 'test_world_layout.py'
```
