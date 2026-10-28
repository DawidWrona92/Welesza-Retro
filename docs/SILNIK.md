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
| 1 | Bohater porusza się płynnie w 8 kierunkach i reaguje na sterowanie myszą | do sprawdzenia |
| 2 | Postać przechodzi przed i za obiektami otoczenia, także dużymi (sortowanie po Y od punktu kotwicy, zanikanie koron i dachów) | do sprawdzenia |
| 3 | Zmierzony budżet pamięci dla pełnego zestawu zasobów | do sprawdzenia |
| 4 | Przejście między dwoma fragmentami świata bez przerwy i ekranu ładowania ([STREAMING.md](world/STREAMING.md)) | do sprawdzenia |
| 5 | Okna trafień i zapowiedzi zapisane jako zdarzenia animacji (`events`) odtwarzają się w grze powtarzalnie ([walka](walka.md)) | do sprawdzenia |

## Grafika 2D — rozwiązanie techniczne (propozycja)

Całość jest malowana w 2D; w produkcji nie ma modeli ani renderów 3D.

**Kamera.** Stała izometria 2:1 (jak Diablo 2), bez obrotu. `Camera2D` z wygładzaniem ruchu, niewielki zakres przybliżenia. Rozdzielczość odniesienia 1920×1080, tryb skalowania `canvas_items`; grafika malowana w 2× i skalowana w dół, filtr liniowy z mipmapami (to nie pixel art). Bohater ma około 160 px wysokości przy 1080p.

**Świat.** Logika działa w płaskich współrzędnych ekranu, jak w izometrycznej `TileMapLayer`; ruch w pionie jest skracany o połowę, żeby odpowiadał perspektywie. Teren to malowane kafle podłoża (wielokrotnego użytku, oszczędne dla pamięci) z malowanymi naklejkami: błoto, kałuże, ścieżki. Rekwizyty i budynki to osobne malowane PNG z przezroczystością.

**Kontrakt assetu.** Każdy obraz ma plik JSON z punktem kotwicy (miejsce styku z ziemią), obrysem kolizji, linią przesłaniania i warstwą. Duże obiekty dzielimy na podstawę sortowaną po Y oraz koronę albo dach na górnej warstwie, która półprzezroczyście zanika, gdy bohater jest za nią. Na tej podstawie skrypt buduje sceny Godota: `y_sort_enabled`, `CollisionPolygon2D`, `NavigationRegion2D`.

**Światło.** `CanvasModulate` przyciemnia całą scenę, a `PointLight2D` daje ogień, okna i latarnie, z cieniami od `LightOccluder2D`. Opcjonalnie mapy normalnych generowane osobnym przebiegiem z malowanego obrazu. Mgła i deszcz to cząsteczki 2D i nakładka z shaderem.

**Postacie.** Arkusze klatek w 8 kierunkach; bohatera malujemy we wszystkich 8, bo broń w prawej ręce wyklucza odbicie lustrzane. Przeciwników bez asymetrii można malować w 5 kierunkach i odbijać pozostałe. Bohater składa się z warstw o wspólnej kotwicy i czasie klatek: korpus z pancerzem, głowa, broń, tarcza. Kolejność warstw zależy od kierunku (broń za ciałem przy widoku od tyłu). Animacja w 12 kl./s, np. chód 8, cios wiązanki 6–8, unik 6, trafienie 3, śmierć 8 klatek. Duzi przeciwnicy (Korzeniec, Stróż) mogą zamiast klatek używać animacji wycinankowej `Skeleton2D` z malowanych części.

**Proces z GPT‑6.**
1. Arkusz obrotu postaci w 8 kierunkach w kamerze gry, na siatce z zaznaczoną linią ziemi.
2. Pozy kluczowe każdej animacji według płaskiego szablonu pozy (rysowany szkielet 2D, nie model 3D), podawanego razem z arkuszem postaci.
3. Klatki pośrednie: generowane lub interpolowane.
4. Skrypty agenta (Python, Pillow): przycięcie, wyrównanie do kotwicy, kontrola spójności (wysokość sylwetki, rozkład kolorów), pakowanie atlasu, generowanie `SpriteFrames` oraz `AnimationPlayer` ze zdarzeniami trafień z metadanych.

Pierwszy test: Pies w 8 kierunkach (chód, skok, trafienie) i bohater w jednym pancerzu z mieczem.

## Znane ryzyka

1. **Pamięć** — pełny zestaw zasobów gry może przekroczyć budżet; wymaga pomiaru.
2. **Świat bez ekranów ładowania** — Godot nie ma gotowego strumieniowania świata 2D; doczytywanie fragmentów w tle trzeba napisać.
3. **Duże obiekty** — odsłanianie postaci za koronami drzew i dachami wymaga osobnego rozwiązania.
4. **Animacje malowane w 2D** — klatki bohatera mnożą się przez kierunki, animacje, warianty pancerza i rodzaje broni (z tarczą osobne zestawy); trzeba utrzymać tę samą twarz, skalę i punkt kotwicy. Rozwiązanie: warstwy i proces opisane wyżej; sprawdzić na pierwszym teście.

Powiązane: [bezszwowy świat](world/STREAMING.md) · [mechaniki](mechaniki.md).
