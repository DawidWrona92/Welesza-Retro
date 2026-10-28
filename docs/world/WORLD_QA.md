# Welesza — statyczna kontrola mapy v0.2

**Wykonano rzeczywiście** kontrolę danych `docs/world/world-layout.v0.2.json` i testy regresyjne kodu `tools/world/validate_world.py` (obecnie na **`main`**). Interpretacja: kontrola **planistycznego grafu i prostokątów**, nie grywalnej geometrii ani wydajności silnika.

## Komendy do powtórzenia

```sh
python3 tools/world/validate_world.py docs/world/world-layout.v0.2.json
python3 tools/world/validate_world.py docs/world/world-layout.v0.2.json --json
python3 -m unittest discover -s tests -p 'test_world_layout.py' -v
```

Python 3.9+, bez pakietów zewnętrznych. Na `main` znajdują się JSON, dokumentacja, kod walidatora i testy; polecenia uruchomisz bez przełączania branchy.

## Wyniki uruchomienia

| Kontrola | Rzeczywisty wynik |
|---|---|
| Poprawność JSON / format struktur i unikalność ID | **PASS** |
| 28 węzłów, 30 dróg, 12 sektorów | **PASS** |
| Pełna, jednoznaczna siatka sektorów 24×18 | **PASS — 432 pola** |
| Kotwice 28 punktów i ich sektory, granice mapy | **PASS** |
| Przypisanie początku drogi i sektory przecięte przez 30 polilinii | **PASS; 11 tras międzysektorowych** |
| Końce dróg pokrywają się z geometrią punktów | **PASS** |
| Flagi zadań i wymagane blokady przejść | **PASS** |
| Bez odblokowań osiągalne z bramy | **24/28**; zamknięte: komora, dawny trakt, Stróż, suchy szlak |
| Po pokonaniu Dźwigacza | **25/28**; dostęp do komory, nadal bez traktu |
| Po zapaleniu latarni | **27/28**; dostęp do Stróża, wciąż bez suchego szlaku |
| Wszystkie wymagane flagi | **28/28** osiągalnych |
| Testy regresyjne + wstrzyknięte błędy | **16/16 PASS** (`unittest`) |
| Błędy i ostrzeżenia walidatora dla v0.2 | **0 errors / 0 warnings** |

Przykłady negatywne: fałszywy właściciel słupa, fałszywe przecięcie trasy, duplikat ID, nieznany endpoint, nieznana flaga, droga lub punkt poza mapą, zła geometria końca i zdjęta bramka latarni — **są wykrywane**.

## Kontrola wszystkich sektorów / rozbieżności

- **S11:** `pillar_whole` (11.4, 11.3), dojście od S12. Poprawiono błędne przypisanie do S12 w opisie.
- **S12:** `pillar_fallen` (14.9,11.5), `pillar_broken` (15.1,9.3). Poprawiono błędne przypisanie do S22.
- **S13:** `dry_road` (22.7,10.4). Poprawiono błędne przypisanie do S23; S23 jest tłem.
- **S00, S03, S20, S23:** brak punktów i dróg; oznaczone jako obszary graniczne/tło.
- **Pozostałe 24 punkty:** owner_sector zgodny z kotwicą; pełna tabela w SECTORS.md.
- **11 tras przecina granice sektorów:** wymagana koordynacja (listy w JSON i SECTORS.md). Uwaga otwarta: skrót `camp__crossroads` przechodzi także przez S01 — sprawdzić widoczność i brak wrażenia dodatkowej bramy Niemiru.
- **Położenia wozu, rozstaju i mostu** zgodne z funkcjonalnym schematem `docs/plac-przy-wozie.md`: nie ma obowiązku kopiowania jego narysowanych kierunków. Obejścia po obu stronach wozu są detalem lokalnej geometrii, nie potwierdza ich graficzny punkt JSON.

## Zgodność SVG↔PNG

`WORLD_MAP.svg` jest źródłem, a `WORLD_MAP.png` został **wygenerowany ponownie z tego samego SVG** przez CairoSVG. Dotyczą tych samych 28 kotwic i 30 tras, z podpisami sektorów S11/S12/S13 przy czterech spornych punktach; mechanizm pętli oznaczony jako wariant A, nie kanon.

## Czego walidator NIE sprawdza

- Geometrycznej szerokości dróg i dwóch przejść przy wozie, kolizji i pathfindingu ani przebiegu 3D / wysokości komory.
- Długości i czasu spaceru, rzeczywistych metrów, pola widzenia kamery, przesłaniania przez koronę czy dach.
- Odczucia nadprzyrodzonej anomalii; B wymaga osobnego eksperymentu, którego nie obejmuje płaski JSON.
- Obsługi walki podczas przełączania warstw, zapisów po cofnięciu, ani braku ekranów ładowania w uruchomionej grze.
- FPS, zacięć, RAM/VRAM i czasu doczytywania. **Żadnych testów w silniku nie uruchomiono**.

## Następny etap

Wykonać [`GREYBOX.md`](GREYBOX.md): brama → rozstaj → wóz → podejście do zerwanego mostu, razem z testami Psa, uników i obu obejść wozu. Warianty A/B i L1/L2/L3 wymagają świadomej decyzji po prototypie.
