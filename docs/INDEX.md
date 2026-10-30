# Welesza — indeks dokumentacji

**Konwencja statusu.** Wszystko w dokumentach jest propozycją do walidacji, chyba że oznaczono to jako decyzję autora (tabele „Decyzje autora”, „Ustalenia autora” albo znacznik **[DECYZJA AUTORA]**). Żaden projekt nie był jeszcze testowany w silniku, a liczby są robocze do etapu balansu. Dokumenty nie powtarzają tych zastrzeżeń. Nie zmieniaj statusu decyzji bez potwierdzenia autora.

| Dokument | Zawartość |
|---|---|
| [Plan prac](PLAN.md) | Kamienie milowe, zadania agentów, bramki decyzji |
| [Fabuła](fabula.md) | Koncepcja demo: Niemir, zadania, postacie |
| [Mechaniki](mechaniki.md) | Podstawy, wyprawa, leczenie, porażka i zapis (pakiet 02) |
| [Walka](walka.md) | Ustalenia autora, wiązanki, trafienia i pakiet 01 |
| [Przeciwnicy](przeciwnicy.md) | Bestiariusz, spotkania, bossowie i przegląd scenariuszowy (pakiet 03) |
| [Mapa demo](mapa-demo.md) | Niemir, początek gry, plac przy wozie, przegląd (pakiet 04) |
| [Mapa świata v0.2](world/README.md) | Cała dolina: obszary lasu, odnogi, droga główna, [sektory](world/SECTORS.md), [streaming](world/STREAMING.md), [warianty](world/VARIANTS.md), [greybox](world/GREYBOX.md) |
| [Silnik](SILNIK.md) | Godot 4 i GDScript — decyzja warunkowa |
| [Kierunek artystyczny (PDF)](art/WELESZA_DARK_PAINTERLY_2D_KIERUNEK_ARTYSTYCZNY_v1.pdf) | Dark Painterly 2D, zatwierdzony. Doprecyzowania autora z 28.10.2026 (Dźwigacz z hakiem lub sierpem, Stróż ze zwykłą latarnią) są w [przeciwnikach](przeciwnicy.md). Las to gęsty słowiański bór, głównie liściasty, nie świerkowy (PDF s. 7) |
| [Przyroda boru](art/przyroda/) | Arkusze [B](art/przyroda/arkusz-przyrody-b.png) (paleta, detale) i [D](art/przyroda/arkusz-przyrody-d.png) (skarpy, zbocza): wzór rekwizytów i krawędzi terenu boru [DECYZJA AUTORA, 28.10.2026]. Z drzew bierzemy liściaste i martwe; sosny i świerki pomijamy |
| [Tekstury modern pixel-art](../art-src/_tekstury/) | 15 przekonwertowanych map 1024×1024 (podłoże, skały, kora): modern pixel-art v3 (kora 128×128 / piksel 8×8 / do 12 barw; podłoże i skały 64×64 / piksel 16×16 / do 10 barw; wyostrzone kontury, pięć pasm tonalnych, scalanie klastrów, brak ditheringu, wyrównane granice kafli). Testy proceduralne kontrolują strukturę i powtarzalność. [Podgląd](art/modern-pixelart-textures-preview.png), [generator](../tools/modern_pixelart_textures.py), [oryginały](../art-src/_tekstury-source/). Nie są jeszcze podłączone do gry; igliwie i kora sosny pozostają materiałami opcjonalnymi, poza głównym borem liściastym |
| [Grafy](graphs/) | Grafy poziomów i bossów — dane projektowe, nie implementacja |

Skille projektowe: [`.agents/skills/`](../.agents/skills/) — zacznij od design-maestro.
