# Silnik gry: Godot 4

**Status: [DECYZJA AUTORA — warunkowa].** Welesza powstaje na silniku **Godot 4**, jeżeli założenia świata zadziałają w prototypie. Dopóki warunki poniżej nie są spełnione, decyzja może zostać zmieniona.

## Ustalenia

| Element | Ustalenie |
|---|---|
| Wersja | **Godot 4.7.2-stable** (przypięta; zmiana wersji tylko po teście i decyzji autora) |
| Język | GDScript, bez C#/.NET |
| Gra | 2D, sortowanie po Y według punktu kotwicy |

## Warunki decyzji

| # | Warunek | Stan |
|---|---|---|
| 1 | Postać porusza się w 8 kierunkach z poprawną kotwicą i czasem klatek | do sprawdzenia |
| 2 | Obiekt otoczenia sortuje się z postacią (przed i za), także duże obiekty | do sprawdzenia |
| 3 | Zmierzony budżet pamięci dla pełnego zestawu postaci i potworów | do sprawdzenia |
| 4 | Przejście między dwoma fragmentami świata bez przerwy i ekranu ładowania ([STREAMING.md](world/STREAMING.md)) | do sprawdzenia |
| 5 | Okna walki z `events` odtwarzane w czasie gry powtarzalnie ([walka i trafienia](walka-i-trafienia.md)) | do sprawdzenia |

## Znane ryzyka

1. **Pamięć** — pełny zestaw postaci i potworów może przekroczyć budżet; wymaga pomiaru.
2. **Świat bez ekranów ładowania** — Godot nie ma gotowego strumieniowania świata 2D; doczytywanie fragmentów w tle trzeba napisać.
3. **Duże obiekty** — przenikanie koron i dachów wymaga osobnego rozwiązania; sortowanie po jednym punkcie kotwicy nie wystarczy dla budynków.

Powiązane: [bezszwowy świat](world/STREAMING.md) · [przed prototypem](przed-prototypem.md).
