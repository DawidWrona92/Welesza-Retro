# Welesza — mapa ciągłego świata doliny Niemiru (v0.2)

**Status: [DECYZJA AUTORA] ZAAKCEPTOWANA PODSTAWA DO GREYBOXU** (27 października 2026 r.). Metry i ostateczna geometria powstaną w greyboxie; warianty anomalii i latarni pozostają do decyzji ([VARIANTS.md](VARIANTS.md)).
**Zakres:** cała mapa **obecnie opisanego grywalnego świata (demo / pierwszy rozdział)**: Niemir, wszystkie leśne trasy, trzy słupy, obóz węglarzy, leśne ruiny, bossowie, cztery zadania poboczne, wyjście z doliny. Nie projektujemy na siłę dalszych krain pełnej gry, bo nie ma jeszcze zatwierdzonej fabuły poza suchym szlakiem.
**Warunek autorski:** brak ekranów ładowania podczas przemieszczania, także pomiędzy bramą, lasem, ruinami i komorą latarni.

> **v0.2 — korekta po review PM.** Topologia znanego demo zaakceptowana przez autora; bez zatwierdzonych metrów, anomalii ani mechanizmu latarni.
> Pierwszy wóz: **przed zmierzchem**, następnie nocleg i powrót rano.
> Mapa SVG przedstawia jedynie opcję **A** dla anomalii; opis B: [VARIANTS.md](VARIANTS.md).

## 1. Dostarczone materiały

- [Wizualna mapa topologiczno-przestrzenna SVG](WORLD_MAP.svg) oraz [podgląd PNG](WORLD_MAP.png) — czytelny plan obszarów, nie gotowa grafika gry.
- [Dane geograficzne świata, 28 punktów i 30 tras](world-layout.v0.2.json) (kotwice i sektory przecięte).
- [Karty 12 sektorów produkcyjnych](SECTORS.md).
- [Kontrakt techniczny bezszwowego świata i savegame](STREAMING.md).
- [Automatyczna kontrola spójności](WORLD_QA.md) i [odtwarzalny walidator](../../tools/world/README.md) (na `main`).
- [Porównanie pętli A/B i odsłonięcia traktu](VARIANTS.md).
- [Plan pierwszego greyboxu](GREYBOX.md).

**Ważne:** wszystkie pozycje należą do **abstrakcyjnej siatki projektowej**; to nie zatwierdzone metry, rozmiary colliderów, czas dojścia ani skala sprite'ów. Ostateczne proporcje powstaną po próbach kamery, animacji i walki.

## 2. Filozofia przestrzeni

Niemir jest jedynym prawdziwie bezpiecznym schronieniem. Drogi nie tworzą dużego przypadkowego proceduralnego otwartego świata. Las jest gęsty i pamiętny, ale ma logiczną topografię. Główne przejścia łączą niewielkie polany; boczne ścieżki prowadzą do rzeczywistych śladów ludzkiego życia, nie do zbędnych kopii nagród. Gracz stale widzi i rozumie fragment przestrzeni, ale nie dostaje od początku mapy ujawniającej tajemnice.

Podróż gracza jest wizualnie ciągła, **nie przesądzamy jednak liczby scen czy architektury silnika**. Nie ma widocznej „bramy poziomu”. Gdy za zakrętem wczytuje się dalsza część lasu, gra działa normalnie. Nie należy mylić granic `S00–S23` z granicami grywalnej mapy.

## 3. Główne rejony i szlak narracyjny

| Rejon | Stan i charakter | Cel gracza / rola | Ważne wejścia |
|---|---|---|---|
| **Niemir** | Palisada, skała ze źródłem, mały plac, dom gościnny, kuźnia, zielarka, strażnica, domy | Schronienie, przygotowania, sklep, rozmowy i zapalenie lampy | Jedyna brama → rozstaj |
| **Skraj i wóz** | Błotnisty trakt, koń i pakunki, dalszy zerwany most; dwa obejścia wozu | Prolog, pierwsza wyprawa, Pies, Powrotnik, księga przewozowa | Rozstaj → wóz → brzeg |
| **Rozstaj i anomalia** | Charakterystyczne pochylone drzewo, anomalia — wariant A (pętla fizyczna) / B (zmiana połączeń) DO WYBORU | Utrata orientacji, powrót do punktu startowego; boczne cmentarne miejsce | Wóz ↔ rozstaj ↔ kamienie |
| **Kamienne wyjścia** | Trzy różnie zniszczone słupy, Korzeniec, ślady zawracającej drogi | Zadanie „Droga, która wraca”, dowolna kolejność inspekcji | Rozstaj ↔ kamienie ↔ obóz |
| **Obóz węglarzy** | Zimne palenisko, narzędzia, Drwal i Łucznik, leśne schronienie | Podejście do strażnicy, opcjonalne zadania; odblokowanie skrótu | Kamienie ↔ obóz ↔ Dźwigacz |
| **Leśna strażnica** | Niskie kamienne ruiny i zimny piec, Dźwigacz, schody do komory | Boss, zdobycie zgaszonej latarni, powrót do osady | Obóz → arena → komora |
| **Odsłonięty trakt** | Dawne słupy i nieprzebyta wcześniej droga | Dostęp dopiero po zapaleniu lampy w Niemirze | Kamienie → trakt → Stróż |
| **Finał** | Arena Stróża, następnie kawałek suchej drogi | Pokonanie strażnika, potwierdzenie wyjścia, powrót do osady | Stróż ↔ suchy szlak |
| **Odnogi poboczne** | Buty, sidła, jama Zbieracza, schronienie, pieśń, narzędzia | Cztery zadania poboczne i jedno spotkanie obserwacyjne | Od węzłów R, K i obozu |

**Start fabuły:** **przed zmierzchem** przy porzuconym wozie, bez wymuszonej walki. Bohater kieruje się światłem ku bramie. Następnego ranka wraca do wozu i zaczyna pierwszą wyprawę bojową.

## 4. Mapa na jednym płótnie

[Otwórz mapę SVG](WORLD_MAP.svg) — wszystkie 28 punktów oznaczono numerami w legendzie. Kotwice przypisane do sektorów są w JSON i [kartach sektorów](SECTORS.md). Północ na górze, wschód po prawej: **umowne**, do zatwierdzenia po greyboxie. Plansza ma 24×18 abstrakcyjnych komórek. Proponowane makrosektory grupują po 6×6, co daje **4 kolumny × 3 rzędy**. Puste fragmenty mapy są naturalnymi skarpami, zbiornikami wody lub zamkniętym lasem, a nie miejscem do automatycznego generowania setek przeciwników.

Ruch odbywa się płynnie przez każdy zwornik. Możliwość obejścia obiektu i wycofania się do osady ważniejsza jest od symetrycznych ścieżek na papierze.

## 5. Stan fabuły i bramki — rozwiązanie wizualne otwarte

| Warunek | Co odblokowuje | Jak zachować ciągłość |
|---|---|---|
| Pokonanie Dźwigacza | Schody/komorę z latarnią | Odsunięty zawalony element / dostępne schody w tej samej bryle ruin |
| Latarnia wyniesiona do Niemiru i zapalona | Widoczny/stabilny dawny trakt | Brama fabularna jest stała; czy samo światło ujawnia drogę, czy ustępuje przeszkoda — do decyzji autora (VARIANTS.md) |
| Otworzenie bariery od strony obozu | Skrót z obozu do rozstaju | Stała usunięta blokada przejścia, nie instant teleport |
| Pokonanie Stróża | Odcinek suchego szlaku | Otwarte przejście za areną, bez fade-to-black |
| Zbadanie suchego szlaku i powrót | Finał w Niemirze | Gracz fizycznie wraca odkrytymi drogami |

Trzy kamienne słupy w dowolnej kolejności. Nie wymagamy zabicia każdego napotkanego stwora, by zbadać ślady. Zbieracz i Żałobnica nie stanowią ukrytych wymagań dla głównego finału.

## 6. Szwy i logiczne zasady projektowania

- Pierwsza walka przy wozie: czytelny dystans skoku Psa, wolny pełen unik **U** i obie flanki wozu. Nie tworzyć schronienia, z którego da się bezkarnie atakować przez drewno.
- Kamienie: każda odnoga powinna mieć własną formę słupa i otwarte miejsce inspekcji. Wrogowie nie mogą „trzymać” wszystkich trzech słupów z jednego punktu.
- Obóz: stos drewna naprawdę odcina linię ostrzału, ale nie blokuje obu przejść. Drwal i Łucznik działają jako jeden kontrolowany encounter.
- Dźwigacz: przy piecu dwa obejścia, bez klinowania szerokiego potwora; gracz może powrócić do obozu i osady.
- Stróż: pole walki nie może być jednowymiarowym tunelem; wyraźny obrys zagrożenia, żadnych nieosiągalnych wysepek i dodatkowych fal.
- Prolog i osada: warstwy dachu i wysokie drzewa nie mogą całkowicie ukryć bohatera. Jedna główna brama i rozpoznawalna skała ze źródłem.
- Granica mapy: urwisko/potok/gęstwina to uzasadnione przeszkody. Unikać szerokich widocznych ścieżek prowadzących do niewidzialnej ściany.

## 7. Podział prac na chunki — kolejność PRODUKCJI, nie loadingu

| Pakiet | Zakres do zaprojektowania i przetestowania | Kryterium odbioru |
|---|---|---|
| **WLD-00** | Zasady globalnej mapy, skala, kamera, nawigacja, identyfikatory | Spójna nawigacja i identyfikatory; technologia współrzędnych do ustalenia |
| **WLD-01** | S01: Niemir (brama, plac, źródło, gospoda, trening) | Bez pomyłki od bramy do Miłki/Żegoty |
| **WLD-02** | S01 + S10 + S11: rozstaj, wóz, most, pętla, cmentarne miejsce | Pierwsza wyprawa i powrót, obejścia i anomalia |
| **WLD-03** | S11 + S12 + S21: trzy słupy, Korzeniec, polanka z pieśnią | Dowolna kolejność śladów, brak zablokowanych skrótów questowych |
| **WLD-04** | S12 + S02: obóz, narzędzia, schronienie, skrót | Drwal/Łucznik i dwukierunkowe przejście po otwarciu |
| **WLD-05** | S13: Dźwigacz, piec, komora z latarnią | Ciągłe zejście schodami, powrót bez przerwania gry |
| **WLD-06** | S12 + S13; S23 wyłącznie tło: dawny trakt, Stróż, sucha droga | Finał i poprawne ustawienie wszystkich bramek |
| **WLD-07** | S21 + S22 + tło: sidła, Zbieracz, polana, podmokłości | Poboczne miejsca mają sensowny powrót i nie blokują głównego szlaku |
| **WLD-08** | Integracja 12 sektorów, streaming, zapis, profilowanie | Brak pauz przy szwach, poprawna trwałość stanu i zero podwójnych obiektów |

**Pierwszy grywalny pionowy wycinek** = WLD-00 + WLD-01 + WLD-02. Pozostałe sektory mogą być najpierw blokowane naturalnymi przeszkodami. Muszą zachować ciągłe przejście **odczuwane przez gracza**, także jeśli silnik użyje wielu scen lub osobnych zasobów.

## 8. Otwarte kwestie przed detalowaniem geometrii

1. Czy docelowa kamera pozostaje stała w jednym kierunku (rzut Diablo 2), czy dopuszczamy obrót? Od tego zależy geometria dachu i czytelność bram.
2. Silnik: Godot 4, gra 2D z prerenderowanych sprite'ów ([decyzja warunkowa](../SILNIK.md)). Reprezentacja podłoża i fizyki — otwarte.
3. Wymiary świata — dopiero po ustaleniu D, B, U, A, V w walce.
4. Wymagana „niemożliwość” pętli: rysunek zachowuje **wariant A jako makietę**; **wariant B** może zmieniać relacje przestrzenne bez widocznego ekranu ładowania. Ostateczna decyzja autora jest otwarta: [porównanie](VARIANTS.md).
5. Jak szczegółowe i grywalne mają być wnętrza gospody i strażnicy? Na razie pełne bezładowaniowe wnętrza są obowiązkiem tylko wtedy, gdy gracz faktycznie do nich wchodzi.
6. Dalsza pełna gra po suchym szlaku **nie ma jeszcze opisanego regionu**. Granica demo ma być przygotowana na przyszłą ekspansję bez zmiany fundamentu mapy, ale nie deklarować lokacji bez kanonu.

## 9. Podstawa i zgodność z repozytorium

- [Koncepcja i zaakceptowana fabuła demo](../demo-fabula.md).
- [Pakiet 04: topologia Niemiru i lasu](../pakiet-04-mapa.md).
- [Początek, prolog i pierwsza wyprawa](../pakiet-04-poczatek.md).
- [Spotkania i bossowie](../spotkania-i-bossowie.md).
- [Dane grafu istniejącego demo](../graphs/layout-demo.json).
- [Dane pierwszej wyprawy](../graphs/layout-first-expedition.json).
- [Przewodnik artystyczny osady Niemir](https://github.com/DawidWrona92/RPG-OldSchool/blob/main/docs/art/niemir/NIEMIR_ART_DIRECTION.md).

Nie zmieniamy nazw i treści uzgodnionych zadań ani NPC. Układ miejsc, tras i sektorów jest **zaakceptowaną podstawą do greyboxu**; współrzędne i długości tras mogą się zmienić po pomiarach w prototypie i nie ustanawiają nowych faktów fabularnych.

## 10. Zmiany i zgodność w v0.2

- 28 kotwic otrzymało `owner_sector`, 30 polilinii `owner_sector` (koordynator) i `sectors_crossed` (faktycznie odwiedzone obszary); 11 dróg przecina przynajmniej jedną granicę.
- Pierwszy słup należy do S11, powalony i rozbity do S12, suchy szlak do S13. S23 to **tło**, nie właściciel końca gry. Nie ruszaliśmy ich współrzędnych.
- Skorygowana pora pierwszego spotkania wozu — przed zmierzchem.
- Pętla A i anomalia B; latarnia L1/L2/L3 pozostają wariantami autorskimi, bez zmiany bramek głównych zadań.
- W projektowym grafie dopuszczamy różne rozwiązania techniczne streamingu, bez widocznych ekranów ładowania podczas zwykłej podróży.
- Rysunek pozostaje topologią — obie trasy obejścia wozu są problemem lokalnej geometrii wg [placu przy wozie](../plac-przy-wozie.md), a nie dwiema nowymi krawędziami między węzłami świata.
