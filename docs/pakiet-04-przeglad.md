# Pakiet 04 — przegląd i walidacja

Status: przegląd projektu według level-designer, ux-onboarding i playtest-simulator. Nie wykonano grywalnego testu, pomiaru czasu ani oceny gotowych ilustracji.

Zakres: [mapa](pakiet-04-mapa.md), [początek gry](pakiet-04-poczatek.md), [brief obrazów](https://github.com/DawidWrona92/RPG-OldSchool/blob/main/docs/pakiet-04-obrazy.md). Wskazane poniżej wyniki narzędzi dotyczą wyłącznie grafów symbolicznych.

## 1. Spójność z dotychczasową fabułą

- Wóz pojawia się przed przybyciem do osady; poranna wyprawa wraca do tego samego obiektu i zachowuje jego stan.
- Nocleg przy wspólnym ogniu i prywatna izba za zadanie są odrębnymi korzyściami. Nie przyznajemy ponownie tej samej nagrody.
- Strażnica w osadzie jest bezpiecznym miejscem zapalenia latarni, a leśna mieści Dźwigacza i komorę. Obie są rozróżnione wizualnie oraz w grafie.
- Finał wymaga zapalonej latarni, nie tylko podniesionego przedmiotu. Obóz daje skrót, aby powrót z latarnią nie oznaczał obowiązkowego powtarzania całej trasy walk.
- Czternaście istniejących postaci wystarcza do obsadzenia osady i zaginionego lokatora. Przypisanie tej roli Czciborowi pozostaje propozycją, nie dopisanym faktem do zatwierdzonej fabuły.
- Nie dodano pól, nowej odległej krainy, systemu głodu ani obowiązkowej magii bojowej.

## 2. Przejście jako początkujący

1. Startuje na trakcie i widzi wóz. Może pominąć tekst przy butach i nadal dostrzec światło prowadzące do bramy.
2. Rozmawia z Żegotą i Miłką. Nie musi poznać wszystkich czternastu osób przed ruszeniem dalej.
3. Rano próbuje ciosu i odskoku na dziedzińcu. Pies nie zostaje pierwszym miejscem, w którym pojawia się informacja o klawiszu uniku.
4. Przy wozie przegrywa lub się wycofuje. Brama nadal jest dostępna; porażka nie kasuje usług w osadzie.
5. Wraca z pakunkami, omijając brzeg. Zadanie zostaje rozliczone, a Nawoja może wskazać temat dalszego badania drogi.

**Ryzyka UXO-R02 / UXO-R07:** nadmierna liczba pierwszych rozmów i niejasność „muszę zbadać wszystko, żeby oddać pakunki”. Projekt ogranicza obowiązkowe kontakty i rozdziela warunki rozliczenia pakunków od opcjonalnych obserwacji. Czytelność trzeba sprawdzić z osobą nieznającą scenariusza.

**Dwa odchylenia:** gracz omija trening; gracz nie czyta księgi. Pomoc jest ponownie dostępna, a wpis do dziennika zachowuje odkrycie. Nie przyznajemy za to automatycznie zaliczonej nauki walki.

## 3. Przejście jako gracz szukający skrótów

1. Bierze pakunki bez zabicia wszystkich wrogów. Projekt dopuszcza takie rozwiązanie, jeśli faktycznie dotrze do przedmiotu.
2. Oddaje je i nie bada mostu. Może kontynuować główny wątek.
3. Pomija cmentarne miejsce, Zbieracza, schronienie oraz polankę z pieśnią. Żadne nie daje jedynego wymaganego klucza.
4. Dociera do obozu przed zbadaniem wszystkich słupów. Poznanie miejsca nie blokuje późniejszych obserwacji i rozmów; nie ustawiamy niewidzialnej bariery za brak dialogu z Borzętą.
5. Po zdobyciu zimnej lampy próbuje wejść na dawny trakt. Droga pozostaje niedostępna do zapalenia w Niemirze; wskazówka przy lampie i dziennik wyjaśniają potrzebny powrót.

**Ryzyko LVL-R02 / Major:** bez rozróżnienia lampy zimnej i zapalonej graf mógłby pomijać kluczowy powrót. W modelu użyto dwóch osobnych stanów, a właściwa bramka wymaga zapalonej latarni.

**Dwa odchylenia:** podniesienie lampy przed przyjęciem zadania; wejście na skrót od strony rozstaju. Pierwsze ma być rozpoznane przez stan przedmiotu. Drugie wymaga wcześniejszego otwarcia skrótu od obozu. Graf opisuje warunek, ale nie testuje realizacji zamknięcia w geometrii.

## 4. Przejście jako gracz próbujący zepsuć mapę

1. Wciąga Psa do pętli i próbuje przenieść go w inne miejsce. Projekt zakazuje przejścia z aktywnym pościgiem i wymaga stabilnej drogi odwrotu; dokładny sposób realizacji trzeba sprawdzić w prototypie, bez pojawiania się niewidzialnej ściany pod graczem.
2. Ponownie ogląda wóz po oddaniu pakunków. Przedmiot i nagroda nie mogą odtworzyć się przy zmianie wejścia do obszaru.
3. Próbuje przejść przez filar w ruinach albo strzelać zza nieprzechodniej osłony. To zależy od kolizji i nawigacji, nie od grafu.
4. Próbuje użyć uniku do przeskoczenia mostu lub muru przy Stróżu. Unik nie ma funkcji skoku przez głęboką wyrwę ani przenikania przez mur.
5. Próbuje atakować NPC potrzebnego do rozliczenia. Pakiet proponuje interakcję zamiast swobodnej walki z mieszkańcami; ta decyzja wymaga walidacji autora.

**Ryzyka LVL-R10 / LVL-R11 — otwarte przed implementacją:** brak znanych D, B, U, A i V uniemożliwia dowiedzenie, że korytarze i kamery działają. Dokument podaje warunki pomiaru, nie fałszywe gotowe wymiary.

**Dwa odchylenia:** zapis przed przejściem pętli i wznowienie po nim; upuszczenie/sprzedaż lampy. Pierwsze wymaga zachowania właściwego wejścia, stanu wozu i obserwacji. Drugie jest niedozwolone dla przedmiotu fabularnego zgodnie z pakietem 02.

## 5. Rytm i nauczanie

Pierwsza sekwencja: orientacja → schronienie → próba bez ryzyka → jedno zagrożenie → odkrycie → powrót. Pies nie wymaga parady, a pierwsze ćwiczenie gardy poprzedza Drwala. PPM i strzelanie otrzymują pokaz dopiero po udostępnieniu tych akcji.

Cięższe starcia oddzielają odcinki ciszy: po Dźwigaczu komora, po powrocie usługi osady, przed Stróżem krótki odsłonięty trakt. Te odcinki nie otrzymują dodatkowych fal wrogów tylko w celu wypełnienia mapy.

**Niezweryfikowane:** faktyczny czas wędrówki, czytelność bez znaczników, tolerancja rytmu, nakładanie sylwetek i reakcja na zmiany światła. Nie raportujemy zaliczenia testów UX na podstawie samego tekstu.

## 6. Wykonana walidacja grafów

```bash
python3 .agents/skills/level-designer/scripts/validate_graph.py docs/graphs/layout-demo.json
python3 .agents/skills/level-designer/scripts/validate_graph.py docs/graphs/layout-first-expedition.json
```

Oba polecenia zwróciły `OK: graph is valid` z kodem 0. Ponadto wykonano na kopiach grafów w pamięci:

| Próba | Wynik narzędzia |
|---|---|
| Usunięcie wszystkich oznaczonych odgałęzień pobocznych demo | Graf nadal poprawny; finał osiągalny |
| Usunięcie opcjonalnych obserwacji i treningu z grafu pierwszej wyprawy | Graf nadal poprawny; rozliczenie pakunków osiągalne |
| Usunięcie źródła zapalonej latarni | Oczekiwane odrzucenie: nieosiągalne węzły i brak wymaganego stanu bramki |
| Usunięcie źródła zwycięstwa nad Stróżem | Oczekiwane odrzucenie: suchy szlak i finał niedostępne |
| Usunięcie źródła pakunków | Oczekiwane odrzucenie: rozliczenie zadania niedostępne |

Grafy reprezentują możliwość przejścia i pozyskania trwałych stanów. Nie przyznają automatycznie zwycięstwa po wejściu na arenę. Pola `condition` są opisami, nie wykonywanym kodem. Graf demo zaczyna się po nocy, więc nie symuluje prologu ani zerwania mostu. Nie jest pełną maszyną wszystkich stanów ośmiu zadań: osiągalność finału nie oznacza automatycznie rozliczenia każdej obserwacji na trzech słupach.

Nie modelują kosztów, kolizji, czasów, bitwy, cofnięcia zapisu ani aktywnego pościgu w pętli. Wynik jest kontrolą struktury projektu, nie dowodem gotowości mapy do gry.

## 7. Przekazanie do obrazów

[Brief obrazów](https://github.com/DawidWrona92/RPG-OldSchool/blob/main/docs/pakiet-04-obrazy.md) ma siedem kadrów z konkretnymi kryteriami. Pierwsza seria powinna skupić się na osadzie, bramie, wozie i czytelności pierwszej walki. Nie wybrano jeszcze silnika, finalnego stylu ani rozdzielczości assetów.

Cały pakiet 04 pozostaje propozycją do oceny razem z wcześniejszymi pakietami. Ilustracje mogą pomóc w tej ocenie; nie zastępują późniejszej próby grywalnego fragmentu.
