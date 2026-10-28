# Welesza — płynne przechodzenie przez świat (v0.2)

**Status:** wymóg gracza zatwierdzony; architektura i limity wydajności są **hipotezami technicznymi**. Silnik: Godot 4 ([decyzja warunkowa](../SILNIK.md)); reprezentacja scen nie jest wybrana.

## A. Twardy kontrakt doświadczenia gracza

> Podczas normalnego przemieszczania się po świecie gracz **nie widzi ekranu ładowania ani przejścia przerywającego podróż**.

1. Wyjście przez bramę Niemiru, marsz do rozstaju, wozu, obozu i ruin, wejście na schody oraz powrót przebiegają bez czarnego ekranu, paska ładowania i odebrania sterowania **z powodu zmiany fragmentu mapy**.
2. Zmiana obszaru nie powoduje teleportu widocznego jako skok pozycji, zniknięcia przeciwnika w pościgu, powielenia lootów ani zaniku pocisku/kolizji.
3. Ruch kamery, widoczność terenu, dźwięku i świateł pozostają spójne także po zawróceniu.
4. Zapis/odczyt, start gry i fabularny nocleg są odrębnymi operacjami; mogą mieć uzasadnione ekrany czy zmianę czasu, ale **nie wolno nimi maskować zwykłego przejścia między lokacjami**.
5. **To nie jest wymaganie „jedna scena w edytorze”.** Możliwe są liczne sceny, zasoby, siatki lub procesy, jeśli wynik dla gracza spełnia powyższy kontrakt.
6. Wyjątkowa anomalia fabularna może zmieniać geometrię odczuwanej przestrzeni. To odrębny wybór autora (VARIANTS.md), nie pretekst do ekranu ładowania.

## B. Hipotezy implementacyjne do prototypu

**Opcja T1 — jedna persistent root scena i dynamiczne podsceny.** Trwałe obiekty pozostają logicznie globalne; sąsiednie lokacje i LOD dodawane lub usuwane w tle. Prosta serializacja, ryzyko skoków instancjonowania i pamięci.

**Opcja T2 — odrębne sceny/obszary silnika, z wizualnie ciągłym przejściem.** Doczytywanie przed wejściem, jednoczesna obecność sąsiednich obszarów, przekazanie kolizji i AI. Większa złożoność szwów, bez widocznego przełączania sceny.

**Opcja T3 — świat przestrzennie jednolity, paginowane zasoby/LOD i nawigacja.** Podobny efekt przy odmiennym modelu pamięci; technologia zależy od wybranego silnika i rozmiaru świata.

Rekomendowane, ale **nie nakazane** praktyki: spójny układ współrzędnych lub bezstratne transformacje sąsiednich scen, stabilne `world_id`, trwały stan fabuły, mechanizm obsługi aktywnych przeciwników przy granicy oraz przewidywanie kierunku ruchu. Jeśli różne sceny używają lokalnych współrzędnych, muszą być przeliczone bez dryfu i zmiany prędkości.

**Makrosektory `S00–S23`**: prostokąty planistyczne 6×6 na siatce 24×18; służą autorstwu i kontroli danych. **Nie są** obowiązkowymi scenami. Komórka 1×1 z wcześniejszego opracowania była przykładem, nie wybranym rozmiarem streamingu. Zawężenia architektury wymagają benchmarku i pomiaru `D/B/U/A/V`.

## C. Wariant cyklu życia zasobów — ilustracja, nie specyfikacja

Możliwy cykl: stan trwały → zasoby przygotowane w tle → aktywna logika i render → odległe LOD → serializowany stan. Nie trzeba stosować dokładnie pięciu warstw ani tej kolejności. W wybranym silniku należy zbadać koszty odczytu, dekompresji, shaderów, kolizji, renderowania, nawigacji i cache.

| Problem do rozwiązania | Cel dla gracza | Kandydat na metodę, nie nakaz |
|---|---|---|
| Gwałtowny sprint/unik przez granicę | Bez pustej ziemi i stopklatki | Bufor prefetch obejmujący kamerę, zapas drogi podczas opóźnienia i `U` |
| Pies przekracza granicę strefy | Nie znika, nie traci logiki ataku | Tymczasowe przypięcie sąsiednich obszarów lub ponadsektorowy właściciel AI |
| Strzał przez granicę | Nie przepuszcza pocisku przez wóz | Ciągła fizyka lub spójne odwzorowanie colliderów między scenami |
| Cofnięcie po podniesieniu pakunku | Nie odradza pakunku | Unikalny `world_id`, zapisane `collected` poza cyklem życia reprezentacji |
| Korytarz do komory latarni | Brak czarnego przejścia | Fizyczne schody, otwierany dach, przygotowany podziemny obszar; może być osobna podscena |
| Kamera i dźwięk w lesie | Brak wyskakujących drzew i urwanego deszczu | LOD, kompozycja dźwięku w obu obszarach, synchronizacja pogody |

## D. Stały stan świata

Persistencja przedmiotu (pakunki/księga), trzech słupów, bossa Dźwigacza, zimnej latarni, zapalenia latarni w Niemirze, skrótu obozowego, Stróża i znalezienia suchej drogi jest niezależna od tego, czy dane miejsce jest aktualnie wczytane.

- Rozliczenie bossa i przedmiotu powinno być transakcyjne; nie nadawaj nagrody wielokrotnie przy ponownym wczytaniu sektora.
- Powtórne przejście obok wozu nie instancjonuje nowego konia, znaku, butów czy wrogów (poza świadomie zaprojektowaną inscenizacją), także w wariancie B anomalii.
- Nie przestawiać AI/gracza w trakcie wyprowadzania ciosu w celu dopasowania do nowej sceny.
- Ładowanie zapisu w stanie walki i zapis bezpieczny przed bossem to niezależne problemy projektowe (patrz `docs/mechaniki.md`).

## E. Zjawiska fabularne (mechanizm OTWARTY)

- **Droga, która wraca:** wariant B (decyzja autora): zmieniona topologia przestrzeni bez widocznej przerwy, odczuwana przez rozjazd mapy bohatera. W grafie v0.2 polilinia A jest tylko makietą; porównanie i ryzyko w [`VARIANTS.md`](VARIANTS.md). Nie wolno przedstawiać A jako zatwierdzonego wyjaśnienia nadprzyrodzonego zjawiska.
- **Latarnia:** po `village_lamp_lit` droga staje się dostępna. L1: ujawniona, L2: znika realna przeszkoda, L3: czytelność orientacji. **Nie ustala się** korzeni, mgły ani skarpy jako obowiązkowej blokady.
- **Skrót obozu:** odblokowanie od strony obozu jest propozycją dotychczasowej mapy; wymaganie płynnej podróży nadal obowiązuje przy nawrocie.

## F. Cele wydajnościowe (DO POMIARU)

Zaproponowany cel użytkowy: płynność wystarczająca do wiarygodnego uniku i precyzyjnego ataku, brak zauważalnych pauz doczytu, poprawne zachowanie podczas szybkiego nawrotu. Ewentualne **60 FPS**, limit opóźnień i budżet pamięci pozostają aspiracjami do zatwierdzenia po wyborze docelowej maszyny i silnika — **brak benchmarku**.

Pomiary: wykres czasów klatek (nie tylko średni FPS), CPU/GPU, zużycie i piki pamięci, czas decode/upload zasobów, koszt tworzenia colliderów, stan fizyki i AI przy przechodzeniu, opóźnienie inputu, ponowne wejście po natychmiastowym zawróceniu oraz niskopamięciowy scenariusz. Każdy pomiar zawiera build, sprzęt, obciążenie i zapis wideo.

## G. Testy akceptacyjne do uruchomienia w prototypie Godota

1. Marsz i sprint: brama → rozstaj → wóz → podejście do mostu → pełen nawrót, bez przerwy; szwy dowolnej organizacji silnika są niewidoczne.
2. Walka i pociski na potencjalnym szwie, również podczas uniku i odwrotu.
3. Powtórny przyjazd: pakunki nie wracają, martwy boss pozostaje martwy, skrót pamięta otwarcie.
4. Gospoda/strażnica i komora: ciągłość ruchu i kamery bez „teleportu w czerni”.
5. Anomalia A/B i ujawnienie latarni: osobne eksperymenty, nie testy zaliczające istniejący renderer.
6. Profilowanie słabszego docelowego PC, długiej sesji i zmiany kierunku.

**Żaden test silnikowy ani cel wydajnościowy nie jest dziś potwierdzony.**
