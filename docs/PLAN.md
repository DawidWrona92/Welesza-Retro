# Plan prac

Prowadzi PM. Status zadań aktualizuje tylko PM; agent zgłasza wynik w PR. Zasady pracy: [AGENTS.md](../AGENTS.md). Technika: [SILNIK.md](SILNIK.md).

## Role

| Rola | Kto | Zakres |
|---|---|---|
| Autor | Dawid Wrona | Decyzje na bramkach, akceptacja PR, playtest |
| PM | Claude | Architektura, rdzeń techniczny, integracja, przeglądy, synchronizacja branchy |
| Grafik | GPT‑6 | Obrazy według kierunku artystycznego, szablonów i kontraktu assetu |
| Agent treści | agent biblii świata (PR #2), agent konceptów (PR #3) | Biblia, opisy przeciwników, dialogi, zadania; skille `.agents/skills/` |
| Programista | agent kodujący pod nadzorem PM | Systemy rozgrywki według specyfikacji z `docs/` |
| Dźwięk | **brak** | Luka: decyzja autora potrzebna przed M4 |

## Kamienie milowe i bramki

| Etap | Cel | Bramka (decyduje autor) |
|---|---|---|
| M0 | Fundament: projekt Godota, CI, kontrakt assetu, pipeline sprite'ów | — |
| M1 | Test grafiki malowanej 2D w kamerze gry | B1: jakość i spójność klatek; metoda animacji potwierdzona |
| M2 | Prototyp walki z prostych brył | B2: walidacja pakietu 01 ([walka](walka.md), część II) |
| M3 | Ciągły świat: brama → rozstaj → wóz → most (WLD-00–02) | B3: warunki 1–5 z [SILNIK.md](SILNIK.md) spełnione, silnik bez warunku |
| M4 | Pionowy wycinek: pierwsza wyprawa z zapisem, dialogami i grafiką | B4: walidacja pakietów 02 ([mechaniki](mechaniki.md)) i 04 ([mapa demo](mapa-demo.md)) |
| M5 | Pełne demo: osiem zadań, przeciwnicy, bossowie, finał | B5: kontrakt demo (czas przejścia, zakres ekwipunku, znaczenie wyborów) |

Kolejność nie jest datowana. M1 i M2 mogą iść równolegle po M0. Treść (T24–T27) idzie równolegle od razu.

## Zadania

| ID | Etap | Zadanie | Wykonawca | Zależy od | Gotowe, gdy | Stan |
|---|---|---|---|---|---|---|
| T01 | M0 | Projekt Godot 4.7.2 w `game/`: ustawienia obrazu, mapa wejścia (LPM, PPM, Shift sprint, Ctrl + LPM atak w miejscu, unik, garda), autoloady | PM | — | Projekt otwiera się w trybie headless bez błędów | zrobione |
| T02 | M0 | CI w GitHub Actions: `gdlint`, import i sprawdzenie skryptów headless, testy headless, walidatory grafów i assetów | PM | T01 | Każdy PR dostaje zielony lub czerwony wynik | zrobione |
| T03 | M0 | Kontrakt assetu: schemat JSON (kotwica, kolizja, linia przesłaniania, warstwa, kierunki, zdarzenia animacji) i walidator | PM | — | Walidator odrzuca asset bez kotwicy lub z błędnymi klatkami | zrobione |
| T04 | M0 | Pipeline sprite'ów (Python): przycięcie, wyrównanie do kotwicy, kontrola spójności, atlas, `SpriteFrames` i `AnimationPlayer` ze zdarzeniami | PM | T03 | Z surowych PNG powstaje grywalna animacja w Godocie jednym poleceniem | zrobione |
| T05 | M0 | Szablony dla grafika: arkusz 8 kierunków z linią ziemi, płaskie szablony póz, lista klatek na animację | PM | T03 | Grafik ma komplet wejść do T06–T07 | zrobione |
| T06 | M1 | Pies: 5 kierunków + odbicia; chód, skok, trafienie | Grafik | T05 | Klatki przechodzą walidator T03 | zlecone |
| T07 | M1 | Bohater: pancerz skórzany i miecz, 8 kierunków; bezczynność, chód, cios; warstwy korpus, głowa, broń | Grafik | T05 | Jak T06; ta sama twarz i skala we wszystkich kierunkach | zlecone |
| T08 | M1 | Teren testowy: kafle podłoża (błoto, ściółka), wóz, drzewo liściaste z koroną na osobnej warstwie, kamień | Grafik | T05 | Assety z kontraktem JSON | zlecone |
| T09 | M1 | Scena testowa w kamerze gry z T06–T08 i raport spójności klatek | PM | T04, T06–T08 | Autor ocenia nagranie na bramce B1 |  |
| T10 | M2 | Ruch myszą, sprint i wytrzymałość, kamera, sortowanie po Y | Programista | T01 | Ruch w 8 kierunkach, sprint zużywa wytrzymałość | zrobione |
| T11 | M2 | Rdzeń walki: atak na kliknięcie, wiązanki z oknami ze zdarzeń animacji, unik, garda i parada, przerwania | PM | T10 | Scenariusze testów z [walki](walka.md) przechodzą jako testy headless | zrobione |
| T12 | M2 | AI: Pies i Drwal z zapowiedziami i priorytetami z [przeciwników](przeciwnicy.md) | Programista | T11 | Obie walki da się wygrać podstawowym zestawem | zlecone |
| T13 | M2 | Leczenie (opatrunek, nalewka), śmierć i wczytanie w wersji minimalnej | Programista | T11 | Zgodnie z [mechaniki](mechaniki.md), część II B i D |  |
| T14 | M2 | Pomiar D, B, U, A, V i wpis do [mapy świata](world/README.md) | PM | T11, T12 | Wartości w dokumentach zamiast symboli |  |
| T15 | M3 | Greybox WLD-00–02, doczytywanie fragmentów w tle, trwały stan obiektów (`world_id`) | PM | T14 | Przejście tam i z powrotem bez pauzy, bez podwójnych obiektów |  |
| T16 | M3 | Zanikanie koron i dachów, przesłanianie postaci | Programista | T15 | Bohater i zapowiedź ataku zawsze widoczne |  |
| T17 | M3 | Mapa bohatera i prototyp anomalii B | PM | T15 | Testerzy odbierają rozjazd mapy jako tajemnicę, nie błąd |  |
| T18 | M3 | Profilowanie pamięci i czasu klatek | PM | T15 | Pomiary do warunków 3 i 4 z [SILNIK.md](SILNIK.md) |  |
| T19 | M4 | Systemy: zapis i wczytanie, dziennik, interakcje, dialogi | Programista, PM (zapis) | T13, T15 | Zapis atomowy według [mechaniki](mechaniki.md), część II D |  |
| T20 | M4 | Treść: dialogi Żegoty, Miłki i Czcibora; zadanie „Miejsce przy ogniu” | Agent treści | T26 | Dialogi i stany zadania w formacie z [SILNIK.md](SILNIK.md) |  |
| T21 | M4 | Grafika wycinka: brama, fragment Niemiru, plac przy wozie, wóz z koniem, Żegota, Miłka, Czcibor, Powrotnik | Grafik | B1 | Assety przechodzą walidator |  |
| T22 | M4 | Playtest pierwszej wyprawy według [mapy demo](mapa-demo.md), część II §7 | Autor, PM | T19–T21 | Raport z nagraniem i listą poprawek |  |
| T23 | M5 | Sektory WLD-03–08, pozostali przeciwnicy i bossowie, zadania, latarnia, finał | Wszyscy, plan szczegółowy po B4 | B4 | Kontrakt demo spełniony |  |
| T24 | treść | Biblia świata: scalenie do dwóch plików według wskazówek w PR #2 | Agent treści | — | PR #2 gotowy do merge'u | zlecone |
| T25 | treść | Wygląd przeciwników w kartach [przeciwników](przeciwnicy.md) na podstawie konceptów (PR #3) | Agent treści | — | Karty zgodne z konceptami | zrobione |
| T26 | treść | Wewnętrzna logika tajemnicy: słup, zamknięcie boru, latarnia, Stróż (reguły dla twórców, nie dla gracza) | Autor, PM | — | Zapis w [fabule](fabula.md) przed T20 |  |
| T27 | treść | Pełna karta wilka | Agent treści | — | Karta w [przeciwnikach](przeciwnicy.md) |  |

## Decyzje autora potrzebne po drodze

| Kiedy | Decyzja |
|---|---|
| Przed M4 | Źródło dźwięku i muzyki |
| Przed T20 | Wewnętrzna logika tajemnicy (T26) |
| Przed T23 | Wariant odsłonięcia traktu latarnią (L1–L3, [warianty](world/VARIANTS.md)) i jej dramatyczny finał |
| B5 | Kontrakt demo: czas przejścia, zakres ekwipunku, znaczenie wyborów |

## Praca agentów

- Jedno zadanie to jeden branch i jeden PR z ID zadania w tytule, np. `T06: Pies, 8 kierunków`.
- PR zawiera tylko zakres zadania. Zmiany w `docs/` zapisuje się w dokumencie, którego dotyczą.
- PM przegląda każdy PR przed autorem i synchronizuje branche z `main`.
