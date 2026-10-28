# Welesza — walidator statycznej mapy

Źródło prawdy o świecie jest na `main` w `docs/world/`. Walidator `tools/world/validate_world.py` i testy regresyjne `tests/test_world_layout.py` są utrzymywane na `main` razem z wersjonowanym modelem mapy. Branch `vibe/world-map-validator-gpt6` był gałęzią wdrożeniową.

**Wymagania:** Python 3.9+ (wyłącznie standardowa biblioteka). Walidacja nie wymaga Godota ani Blendera.

Z katalogu repozytorium:

```sh
python3 tools/world/validate_world.py docs/world/world-layout.v0.2.json
python3 tools/world/validate_world.py docs/world/world-layout.v0.2.json --json
python3 -m unittest discover -s tests -p 'test_world_layout.py' -v
```

Skrypt sprawdza poprawność wczytania JSON, unikalność ID punktów/dróg/sektorów, końce polilinii, flagi, zasięg prostokątów i ścieżek w obrysie mapy, pełne pokrycie siatki sektorami, poprawne owner_sector, sektory przecięte przez polilinie, spójność bramek oraz osiągalność w czterech stanach fabuły. Kończy się kodem 1 przy błędnym modelu, kodem 2 przy niepoprawnym JSON.

Sektory są półotwarte i dzielą **abstrakcyjną siatkę planu**: współrzędne po prawej/dolnej granicy należą do następnego sektora; mapa końcowa zawiera swój zewnętrzny brzeg. Droga może przecinać kilka sektorów bez zmiany właściciela kotwicy obiektu.

**Nie sprawdza:** realnego pathfindingu, promienia kolizji, szerokości obejść wozu, wykrywania linii wzroku, ruchu kamery, odległości w metrach, czasu podróży, działania prawdziwej anomalii ani wydajności streamingu. To wymaga greyboxu i testów w silniku.
