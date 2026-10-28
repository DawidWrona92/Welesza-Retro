# Walka, wiązanki i trafienia

Status: decyzje autora oraz wyraźnie oznaczone propozycje. Wartości liczbowe podane przez autora są robocze; nie przeprowadzono testów gry ani balansu.
Podstawa: [mechaniki](mechaniki-podstawy.md).
Aktualny pakiet do wspólnej walidacji: [Walka — propozycja 01](propozycja-walki-01.md). Nowe propozycje z tego pakietu nie są jeszcze zatwierdzone.

## Ustalenia autora

- LPM odpowiada za chodzenie i atak. PPM uruchamia umiejętność.
- Atak wymaga kliknięcia; przytrzymanie nie uruchamia ciągłego atakowania.
- Unik i parada mogą przerwać rozpoczęty atak. Autor chce świadomej decyzji między kontynuacją wiązanki a obroną; nie blokujemy przerwania po rozpoczęciu zamachu.
- Dalsze propozycje przedstawiamy większymi pakietami do walidacji, zamiast pytać osobno o każdą regułę.
- Unik: osobny klawisz, odskok w kierunku kursora, zgodnie z zaakceptowaną rekomendacją.
- Parada: osobny klawisz; przytrzymanie utrzymuje gardę, a dobre wyczucie momentu daje dodatkowy efekt. Rodzaj efektu, okno czasowe i koszt gardy pozostają otwarte.
- Przeciw potworom i zwierzętom używamy uniku; przeciw ludziom walczącym bronią i podobnym uzbrojonym wrogom, np. szkieletom lub zombie, dostępne są unik i parada.
- Bezładne klikanie daje podstawowy atak. Kliknięcia w rytm uruchamiają wiązankę ciosów, z większymi obrażeniami kolejnych uderzeń.
- Rozwój umiejętności zwiększa maksymalną długość łańcucha i jego premie. Inspiracją są Gothic oraz Wiedźmin 1. Nie ustalono osobnego katalogu wielu rodzajów kombinacji.
- Trafienia dystansowe wynikają z lotu pocisku i sytuacji w świecie, bez losowego testu pudła. Umiejętności wpływają na możliwości bohatera, pancerz na skutek trafienia; szczegóły przedstawiono w pakiecie do walidacji.

## Rozwój wiązanki — robocze wartości autora

| Stopień | Efekt podany przez autora |
|---|---|
| Podstawowy / I | Maksymalnie trzy elementy łańcucha. |
| II | „+5% obrażeń na poziom” — robocza wartość; wymaga ustalenia, do jakiego poziomu odnosi się mnożnik. |
| III | Cztery elementy łańcucha; czwarty cios znacząco zwiększa szansę losowego krytyka. Nie gwarantuje krytyka. Docelowa premia pozostaje otwarta. |

Osobną zatwierdzoną zasadą jest wzrost obrażeń kolejnych ciosów wykonanych w rytm. Nie należy utożsamiać go automatycznie z premią stopnia II. Nie określono bazowej szansy krytyka, mnożnika jego obrażeń, dokładnego zwiększenia szansy dla czwartego ciosu, kumulowania premii między stopniami ani interakcji z wyposażeniem. Wcześniej podane 20% było wartością roboczą; wymaga doprecyzowania, czy oznacza całkowitą szansę czwartego ciosu, czy premię do szansy bazowej. Na tym etapie nie obliczamy oczekiwanych obrażeń ani kosztów szkolenia.

## Zasada sprawczości gracza — aktualizacja autora

Autor odrzuca losowy test pudła niezależny od działania gracza, ale zachowuje losowe krytyki. Trafienia są rozstrzygane przez wykonane działanie, kontakt i obronę, bez dodatkowego losowego testu. Dla pocisków obowiązuje tor lotu uwzględniający celowanie, ruch celu i przeszkody; bez losowego rozrzutu.

Autor doprecyzował, że krytyk pozostaje losowy, a poprawnie wykonany czwarty cios znacząco zwiększa jego szansę. To zastępuje wcześniejszą interpretację o gwarantowanym mocnym finiszu. Najpierw rozstrzygamy kontakt i obronę, następnie efekt trafienia; losowy krytyk nie zmienia pudła ani skutecznie obronionego ciosu w trafienie.

## Zatwierdzony kierunek: kontakt, obrona i obrażenia

Rekomendowany przebieg rozstrzygnięcia:

1. Czy cios lub pocisk dosięgnął celu w odpowiednim momencie?
2. Czy cel skutecznie wykonał dopuszczalną obronę?
3. Jak pancerz i właściwości broni zmieniły skutek trafienia?

Komunikat i animacja powinny odróżniać chybienie, paradę oraz trafienie zatrzymane lub osłabione przez pancerz.

### Walka wręcz — zatwierdzony kierunek

Nie dodawać losowego testu pudła do poprawnie wymierzonego, nieobronionego ciosu, który faktycznie dosięgnął celu. O wyniku decydują zasięg, kierunek, ruch celu, moment wykonania i obrona. Umiejętności bohatera mogą odblokowywać techniki i wiązanki; ich pozostały wpływ wymaga ustalenia.

Takie podejście pozwala uczyć się rytmu i pozycji. Widoczny kontakt broni z niebroniącym się wrogiem nie kończy się niewytłumaczalnym pudłem.

### Łuk i kusza — zatwierdzony kierunek

Autor zaakceptował deterministyczny lot pocisku: kierunek celowania, dystans, ruch celu i przeszkody rozstrzygają kontakt. Sposób wskazania punktu celowania, ewentualne wspomaganie oraz rola umiejętności łuczniczych wymagają ustalenia.

Umiejętność bohatera może wpływać na czas przygotowania strzału, przeładowanie albo dostępne techniki zamiast na losową szansę chybienia. To propozycje, nie zatwierdzone parametry. Nie przyjmujemy automatycznie pocisków naprowadzanych ani trafienia gwarantowanego kliknięciem przeciwnika.

Pancerz uwzględniamy na etapie skutku trafienia: redukcji obrażeń lub przebicia, a nie celności. Konkretnego modelu przebicia nie zatwierdzono. Nie ustalono również celowania w części ciała ani osobnego trybu przytrzymania do celowania.

## Propozycja: rytm bez premiowania bezładnego klikania

- Moment na następny cios powinien wynikać z animacji i mieć czytelny sygnał; opcjonalne wsparcie wizualne wymaga omówienia.
- Cios ma własny czas wykonania. Kolejne kliknięcia nie przyspieszają go i nie tworzą nieograniczonej kolejki ataków.
- Samo znalezienie pojedynczego kliknięcia w oknie rytmu jest niewystarczające: spam zawsze mógłby przypadkiem w nie trafić. Proponuję, aby przedwczesne kliknięcie zużywało próbę przejścia do następnego ogniwa, pozostawiając możliwość zwykłego ataku po zakończeniu bieżącego. Ta reguła wymaga testu wygody i akceptacji autora.
- Dokończenie wiązanki konkuruje z obroną. Unik i parada przerywają rozpoczęty atak; sposób rozliczania kosztu i resetu łańcucha jest proponowany w pakiecie 01.
- Trzeba rozstrzygnąć, czy pudło, parada przeciwnika, unik gracza lub zmiana celu resetują wiązankę. Nie przyjmujemy domyślnej reguły.

## Szczegóły objęte pakietem do walidacji

Poniższe kwestie rozstrzygamy łącznie na podstawie propozycji 01, nie jako serię pojedynczych pytań.

1. Do czego odnosi się „+5% obrażeń na poziom” na stopniu II: poziomu bohatera, stopnia umiejętności czy kolejnych zakupów szkolenia? Czy obejmuje każdy cios?
2. Jaki dodatkowy efekt daje dobrze wyczuta parada? Jakie ataki zatrzymuje zwykła garda i jaki ma koszt?
3. Czy rytmiczne wiązanki dotyczą wyłącznie broni wręcz? Zachowanie łuku i kuszy nie zostało doprecyzowane.
4. Czym wykonujemy paradę: dowolną bronią, wybranymi rodzajami broni, tarczą? Jak oznaczamy ataki niemożliwe do sparowania?
5. Jakie są ograniczenia uniku i parady oraz wpływ na wiązankę? Sama możliwość przerwania ataku jest zatwierdzona.
6. Jak realizujemy celowanie łukiem i kuszą przy sterowaniu myszą, zgodnie z odrzuceniem losowych testów trafienia? Jaka jest bazowa szansa krytyka i sposób zwiększania jej przy czwartym ciosie?

## Scenariusze przyszłych testów

- Klikanie z maksymalną częstotliwością, przytrzymanie LPM oraz pojedyncze kliknięcia w rytm: spam nie przyspiesza ataków i nie uzyskuje premii wiązanki.
- Polecenie ruchu obok przeciwnika: sprawdzić, czy postać nie rozpoczyna niezamierzonego ataku oraz jak odróżniany jest klik ruchu od kliknięcia rytmu.
- Unik pod koniec ataku, nieudana parada i poprawna parada: czy wynik ma czytelną przyczynę i czy postać reaguje zgodnie z regułami przerywania.
- Cios poza zasięgiem, cios w unikającego wroga, cios sparowany i cios w pancerz: różne wyniki powinny dać się odróżnić bez czytania logu.
- Strzał z różnych dystansów do nieruchomego i poruszającego się celu: umiejętność oraz warunki mają zrozumiały wpływ, pancerz nie powoduje magicznego znikania trafień.
- Atak z dwóch stron: parada nie może przypadkowo chronić przed każdym zagrożeniem niezależnie od kierunku.

To plan weryfikacji; żadnego z tych scenariuszy jeszcze nie wykonano.
