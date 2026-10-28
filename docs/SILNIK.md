# Silnik gry: Godot 4

**Status: [DECYZJA AUTORA — warunkowa], 27 października 2026 r.** Welesza powstaje na silniku **Godot 4**, jeżeli istniejące assety i założenia świata zadziałają w prototypie. Warunki są niżej; dopóki wszystkie nie są spełnione, decyzja może zostać zmieniona.

Grafika pozostaje prerenderem z Blendera według [kontraktu renderu](https://github.com/DawidWrona92/RPG-OldSchool/blob/main/docs/art/KONTRAKT-RENDERU.md). Godot wyświetla gotowe sprite'y 2D; nie renderuje modeli 3D w czasie gry.

## Ustalenia

| Element | Ustalenie |
|---|---|
| Wersja | **Godot 4.7.2-stable** (przypięta; zmiana wersji tylko po teście i decyzji autora) |
| Język | GDScript, bez C#/.NET |
| Gra | 2D: sprite'y z atlasów, sortowanie po Y według kotwicy, osobna warstwa cieni |
| Rzut | 60 px/m; podłoże 60 × 30 px na metr (kamera 30° z kontraktu) |
| Format wejściowy | atlas PNG + JSON z kontraktu renderu, wczytywany własnym importerem — bez przeróbek assetów |
| Pliki projektu | na gałęziach roboczych (np. `vibe/godot-test-silnika`); na `main` tylko dokumentacja (zob. [AGENTS.md](https://github.com/DawidWrona92/RPG-OldSchool/blob/main/AGENTS.md)) |

## Warunki decyzji

| # | Warunek | Stan |
|---|---|---|
| 1 | Bohater chodzi w 8 kierunkach z poprawną kotwicą, czasem klatek i cieniem | **spełniony** — test na gałęzi `vibe/godot-test-silnika` |
| 2 | Obiekt otoczenia sortuje się z bohaterem (przed i za) | **spełniony** dla głazu; duże obiekty (dom, drzewo) do sprawdzenia |
| 3 | Zmierzony budżet pamięci tekstur dla pełnego zestawu postaci i potworów, z kompresją i przycięciem klatek | do sprawdzenia; scena testowa: 71,4 MiB bez kompresji |
| 4 | Przejście między dwoma fragmentami świata bez przerwy i ekranu ładowania ([STREAMING.md](world/STREAMING.md)) | do sprawdzenia |
| 5 | Okna walki z `events` odtwarzane w czasie gry powtarzalnie ([walka i trafienia](walka-i-trafienia.md)) | do sprawdzenia |

## Wynik pierwszego testu

Scena: podłoże z biblioteki tekstur, głaz z gałęzi terenu, ośmiu stojących bohaterów i dwóch chodzących wokół głazu. Godot 4.7.2, renderer GL Compatibility.

- Kotwica z JSON zgadza się z rzutem kamery co do ułamka piksela.
- Osiem kierunków, czas klatek i zmiana kierunku bez resetu kroku działają bez zmian w atlasie.
- Alfa atlasów jest nieprzemnożona, więc domyślne mieszanie Godota nie daje obwódek.
- 13 wywołań rysowania na klatkę; 71,4 MiB tekstur bez kompresji.

Szczegóły, nagranie i instrukcja uruchomienia: `prototype/godot/README.md` na gałęzi `vibe/godot-test-silnika`.

## Znane ryzyka

1. **Pamięć tekstur** — klatka 192×192 jest w większości pusta; potrzebne przycięcie, kompresja i cienie jako sama alfa.
2. **Świat bez ekranów ładowania** — Godot nie ma gotowego strumieniowania świata 2D; doczytywanie fragmentów w tle trzeba napisać.
3. **Duże obiekty** — przenikanie koron i dachów wymaga shadera; sortowanie po jednym punkcie kotwicy nie wystarczy dla budynków.
4. **Okna walki** — zdarzenia z JSON powinien odtwarzać własny węzeł sterowany czasem gry, nie sam sygnał zmiany klatki.
5. **Światło lokalne** — pochodnie zostają osobnymi renderami według kontraktu; światła 2D Godota bez map normalnych wyglądają płasko.

Powiązane: [kontrakt renderu](https://github.com/DawidWrona92/RPG-OldSchool/blob/main/docs/art/KONTRAKT-RENDERU.md) · [bezszwowy świat](world/STREAMING.md) · [przed prototypem](przed-prototypem.md).
