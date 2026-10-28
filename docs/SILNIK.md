# Silnik gry: Godot 4

**Status: [DECYZJA AUTORA — warunkowa].** Welesza powstaje na silniku **Godot 4**, jeżeli założenia świata zadziałają w prototypie. Dopóki warunki poniżej nie są spełnione, decyzja może zostać zmieniona.

## Ustalenia

| Element | Ustalenie |
|---|---|
| Wersja | **Godot 4.7.2-stable** (przypięta; zmiana wersji tylko po teście i decyzji autora) |
| Język | GDScript, bez C#/.NET |
| Gra | 2D, Dark Painterly ([kierunek artystyczny](art/WELESZA_DARK_PAINTERLY_2D_KIERUNEK_ARTYSTYCZNY_v1.pdf)); wersja 3D porzucona — decyzja autora, 28.10.2026 |

## Warunki decyzji

| # | Warunek | Stan |
|---|---|---|
| 1 | Postać porusza się płynnie i reaguje na sterowanie myszą | do sprawdzenia |
| 2 | Postać może przechodzić przed i za obiektami otoczenia, także dużymi | do sprawdzenia |
| 3 | Zmierzony budżet pamięci dla pełnego zestawu zasobów | do sprawdzenia |
| 4 | Przejście między dwoma fragmentami świata bez przerwy i ekranu ładowania ([STREAMING.md](world/STREAMING.md)) | do sprawdzenia |
| 5 | Okna walki z `events` odtwarzane w czasie gry powtarzalnie ([walka i trafienia](walka.md)) | do sprawdzenia |

## Znane ryzyka

1. **Pamięć** — pełny zestaw zasobów gry może przekroczyć budżet; wymaga pomiaru.
2. **Świat bez ekranów ładowania** — Godot nie ma gotowego strumieniowania świata 2D; doczytywanie fragmentów w tle trzeba napisać.
3. **Duże obiekty** — odsłanianie postaci za koronami drzew i dachami wymaga osobnego rozwiązania.
4. **Animacje malowane w 2D** — klatki bohatera mnożą się przez kierunki, animacje, warianty pancerza i rodzaje broni (z tarczą osobne zestawy); trzeba utrzymać tę samą twarz, skalę i punkt kotwicy. Propozycja: bohater składany z warstw (głowa, korpus z pancerzem, broń). Sprawdzić na jednej postaci przed produkcją.

Powiązane: [bezszwowy świat](world/STREAMING.md) · [przed prototypem](mechaniki.md).
