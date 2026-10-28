# Walka

Status: decyzje autora oraz oznaczone propozycje pakietu 01 do walidacji. Wartości liczbowe są robocze; nie przeprowadzono testów gry ani balansu.
Powiązania: [mechaniki](mechaniki.md), [przeciwnicy](przeciwnicy.md).

## Część I — ustalenia autora i zatwierdzony kierunek

### Ustalenia autora

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

### Rozwój wiązanki — robocze wartości autora

| Stopień | Efekt podany przez autora |
|---|---|
| Podstawowy / I | Maksymalnie trzy elementy łańcucha. |
| II | „+5% obrażeń na poziom” — robocza wartość; wymaga ustalenia, do jakiego poziomu odnosi się mnożnik. |
| III | Cztery elementy łańcucha; czwarty cios znacząco zwiększa szansę losowego krytyka. Nie gwarantuje krytyka. Docelowa premia pozostaje otwarta. |

Osobną zatwierdzoną zasadą jest wzrost obrażeń kolejnych ciosów wykonanych w rytm. Nie należy utożsamiać go automatycznie z premią stopnia II. Nie określono bazowej szansy krytyka, mnożnika jego obrażeń, dokładnego zwiększenia szansy dla czwartego ciosu, kumulowania premii między stopniami ani interakcji z wyposażeniem. Wcześniej podane 20% było wartością roboczą; wymaga doprecyzowania, czy oznacza całkowitą szansę czwartego ciosu, czy premię do szansy bazowej. Na tym etapie nie obliczamy oczekiwanych obrażeń ani kosztów szkolenia.

### Zasada sprawczości gracza — aktualizacja autora

Autor odrzuca losowy test pudła niezależny od działania gracza, ale zachowuje losowe krytyki. Trafienia są rozstrzygane przez wykonane działanie, kontakt i obronę, bez dodatkowego losowego testu. Dla pocisków obowiązuje tor lotu uwzględniający celowanie, ruch celu i przeszkody; bez losowego rozrzutu.

Autor doprecyzował, że krytyk pozostaje losowy, a poprawnie wykonany czwarty cios znacząco zwiększa jego szansę. To zastępuje wcześniejszą interpretację o gwarantowanym mocnym finiszu. Najpierw rozstrzygamy kontakt i obronę, następnie efekt trafienia; losowy krytyk nie zmienia pudła ani skutecznie obronionego ciosu w trafienie.

### Zatwierdzony kierunek: kontakt, obrona i obrażenia

Rekomendowany przebieg rozstrzygnięcia:

1. Czy cios lub pocisk dosięgnął celu w odpowiednim momencie?
2. Czy cel skutecznie wykonał dopuszczalną obronę?
3. Jak pancerz i właściwości broni zmieniły skutek trafienia?

Komunikat i animacja powinny odróżniać chybienie, paradę oraz trafienie zatrzymane lub osłabione przez pancerz.

#### Walka wręcz — zatwierdzony kierunek

Nie dodawać losowego testu pudła do poprawnie wymierzonego, nieobronionego ciosu, który faktycznie dosięgnął celu. O wyniku decydują zasięg, kierunek, ruch celu, moment wykonania i obrona. Umiejętności bohatera mogą odblokowywać techniki i wiązanki; ich pozostały wpływ wymaga ustalenia.

Takie podejście pozwala uczyć się rytmu i pozycji. Widoczny kontakt broni z niebroniącym się wrogiem nie kończy się niewytłumaczalnym pudłem.

#### Łuk i kusza — zatwierdzony kierunek

Autor zaakceptował deterministyczny lot pocisku: kierunek celowania, dystans, ruch celu i przeszkody rozstrzygają kontakt. Sposób wskazania punktu celowania, ewentualne wspomaganie oraz rola umiejętności łuczniczych wymagają ustalenia.

Umiejętność bohatera może wpływać na czas przygotowania strzału, przeładowanie albo dostępne techniki zamiast na losową szansę chybienia. To propozycje, nie zatwierdzone parametry. Nie przyjmujemy automatycznie pocisków naprowadzanych ani trafienia gwarantowanego kliknięciem przeciwnika.

Pancerz uwzględniamy na etapie skutku trafienia: redukcji obrażeń lub przebicia, a nie celności. Konkretnego modelu przebicia nie zatwierdzono. Nie ustalono również celowania w części ciała ani osobnego trybu przytrzymania do celowania.

### Propozycja: rytm bez premiowania bezładnego klikania

- Moment na następny cios powinien wynikać z animacji i mieć czytelny sygnał; opcjonalne wsparcie wizualne wymaga omówienia.
- Cios ma własny czas wykonania. Kolejne kliknięcia nie przyspieszają go i nie tworzą nieograniczonej kolejki ataków.
- Samo znalezienie pojedynczego kliknięcia w oknie rytmu jest niewystarczające: spam zawsze mógłby przypadkiem w nie trafić. Proponuję, aby przedwczesne kliknięcie zużywało próbę przejścia do następnego ogniwa, pozostawiając możliwość zwykłego ataku po zakończeniu bieżącego. Ta reguła wymaga testu wygody i akceptacji autora.
- Dokończenie wiązanki konkuruje z obroną. Unik i parada przerywają rozpoczęty atak; sposób rozliczania kosztu i resetu łańcucha jest proponowany w pakiecie 01.
- Trzeba rozstrzygnąć, czy pudło, parada przeciwnika, unik gracza lub zmiana celu resetują wiązankę. Nie przyjmujemy domyślnej reguły.

### Szczegóły objęte pakietem do walidacji

Poniższe kwestie rozstrzygamy łącznie na podstawie propozycji 01, nie jako serię pojedynczych pytań.

1. Do czego odnosi się „+5% obrażeń na poziom” na stopniu II: poziomu bohatera, stopnia umiejętności czy kolejnych zakupów szkolenia? Czy obejmuje każdy cios?
2. Jaki dodatkowy efekt daje dobrze wyczuta parada? Jakie ataki zatrzymuje zwykła garda i jaki ma koszt?
3. Czy rytmiczne wiązanki dotyczą wyłącznie broni wręcz? Zachowanie łuku i kuszy nie zostało doprecyzowane.
4. Czym wykonujemy paradę: dowolną bronią, wybranymi rodzajami broni, tarczą? Jak oznaczamy ataki niemożliwe do sparowania?
5. Jakie są ograniczenia uniku i parady oraz wpływ na wiązankę? Sama możliwość przerwania ataku jest zatwierdzona.
6. Jak realizujemy celowanie łukiem i kuszą przy sterowaniu myszą, zgodnie z odrzuceniem losowych testów trafienia? Jaka jest bazowa szansa krytyka i sposób zwiększania jej przy czwartym ciosie?

### Scenariusze przyszłych testów

- Klikanie z maksymalną częstotliwością, przytrzymanie LPM oraz pojedyncze kliknięcia w rytm: spam nie przyspiesza ataków i nie uzyskuje premii wiązanki.
- Polecenie ruchu obok przeciwnika: sprawdzić, czy postać nie rozpoczyna niezamierzonego ataku oraz jak odróżniany jest klik ruchu od kliknięcia rytmu.
- Unik pod koniec ataku, nieudana parada i poprawna parada: czy wynik ma czytelną przyczynę i czy postać reaguje zgodnie z regułami przerywania.
- Cios poza zasięgiem, cios w unikającego wroga, cios sparowany i cios w pancerz: różne wyniki powinny dać się odróżnić bez czytania logu.
- Strzał z różnych dystansów do nieruchomego i poruszającego się celu: umiejętność oraz warunki mają zrozumiały wpływ, pancerz nie powoduje magicznego znikania trafień.
- Atak z dwóch stron: parada nie może przypadkowo chronić przed każdym zagrożeniem niezależnie od kierunku.

To plan weryfikacji; żadnego z tych scenariuszy jeszcze nie wykonano.

## Część II — pakiet 01 do walidacji

Metoda: core-loop-mechanics. Autor ocenia łącznie bloki A, B i C; dopiero po tej odpowiedzi propozycje przechodzą do części I. Szczegółowych liczb nie ustalamy przed próbą mechaniki.

### Cel i granice pakietu

Łączymy sterowanie myszą z walką wymagającą rozpoznania zagrożenia, rytmu i decyzji o przerwaniu ataku. Zatwierdzone kierunki: groźne małe grupy, sprawczość gracza, rozwój u nauczycieli oraz znaczenie przygotowania. Ich kolejność przy konfliktach nie została ustalona.

Nowa decyzja autora: unik i parada muszą móc przerwać rozpoczęty atak. Proponowane niżej koszty, efekty, klawisze i reguły resetowania łańcucha wymagają oceny wraz z całym pakietem.

Proponowane identyfikatory: MECH-cancel-defense, MECH-rhythm-chain, MECH-guard, MECH-dodge, MECH-stamina, MECH-ranged-aim. Nie są wpisami zatwierdzonego rejestru.

### A. Sterowanie, rytm i przerwanie

| Czynność | Wejście — propozycja przypisania | Efekt | Koszt lub ograniczenie | Cel projektowy |
|---|---|---|---|---|
| Ruch | LPM na terenie | Przejście do punktu | Przeszkody, czas przejścia | Pozycjonowanie |
| Sprint [DECYZJA AUTORA, 28.10.2026] | Przytrzymanie Shift | Szybszy ruch | Zużywa wytrzymałość | Szybsze przejście kosztem gotowości do walki |
| Atak wręcz | LPM na przeciwniku | Jeden cios; poza zasięgiem dojście i jeden cios | Czas i wytrzymałość | Świadomy atak |
| Atak w miejscu | Ctrl + LPM (Shift zajęty przez sprint) | Cios albo strzał w kierunku kursora bez dojścia | Te same koszty co zwykły atak | Jednoznaczna intencja |
| Unik | Spacja | Krótki odskok ku kursorowi | Wytrzymałość, przestrzeń do ruchu, koniec wiązanki | Reakcja na zagrożenie |
| Garda/parada | Przytrzymanie Q | Obrona od strony kursora | Koszt przyjęcia ciosu, wolniejszy ruch | Obrona przeciw broni |
| Umiejętność | PPM | Wybrana aktywna technika | Koszt i ograniczenie techniki | Rozwój możliwości |
| Strzał | LPM na celu lub Ctrl + LPM w punkt | Przygotowanie i pojedynczy strzał | Amunicja i czas | Walka na dystans |

Klawisze zmienialne. Logika akcji oddzielona od urządzenia wejścia, żeby późniejsze dodanie pada nie wymagało zmiany zasad walki. Nie ustalamy jeszcze mapowania pada.

#### Reguła przerwania

- Unik i podniesienie gardy przerywają każdą fazę własnego ataku: przygotowanie, zamach i powrót po ciosie. Obrona ma pierwszeństwo przed oczekującym kolejnym atakiem; kolejka zostaje wyczyszczona.
- Jeżeli obrażenia już zostały zadane albo pocisk wypuszczony, pozostają w świecie. Przerwanie nie cofa skutków. Przerwanie przed kontaktem usuwa przyszły kontakt tego ciosu.
- Koszt rozpoczętego ciosu nie jest zwracany. Obrona kończy wiązankę. Gracz wymienia szansę na silniejszy kolejny cios na bezpieczeństwo.
- Anulowanie ataku nie oznacza odporności na atak, który już trafił. Stan ogłuszenia po otrzymaniu ciosu nie jest własnym atakiem; jego reguły wymagają osobnego testu.
- Nowy atak po obronie ma własne przygotowanie i koszt. Nie można usuwać czasu ataku przez szybkie przełączanie atak–garda–atak i pomijać kolejnego przygotowania.
- Podczas przytrzymanej gardy nie atakujemy. Trzeba ją zwolnić i wykonać świadomy atak. Po uniku nie wykonuje się automatycznie starego polecenia ataku.

#### Wiązanki

Propozycja: wiązanki dotyczą broni wręcz. Każda rodzina broni ma czytelny rytm wynikający z animacji, wspierany dźwiękiem i opcjonalnym wskaźnikiem. Broń dystansowa ma własny rytm przygotowania/przeładowania, bez przenoszenia czwartego ciosu na strzały.

Pierwszy klik rozpoczyna podstawowy cios. Kliknięcie w oknie następnego ogniwa przechodzi do dalszego ciosu. Przedwczesne kliknięcie zamyka możliwość przedłużenia tej wiązanki, ale nie zatrzymuje wykonywanego ataku. Kolejne kliknięcia nie przyspieszają animacji ani nie tworzą długiej kolejki. Wciąż można normalnie wykonać kolejny podstawowy atak po gotowości broni.

Proponowane zakończenia wiązanki: własny unik lub garda, użycie PPM, chybienie, skuteczna obrona przeciwnika, otrzymanie trafienia przerywającego akcję albo przekroczenie okna rytmu. Sama zmiana celu nie resetuje łańcucha, jeśli kolejny cios jest poprawnie wykonany i trafia; ciosy w powietrze nie pozwalają przygotować finiszu poza walką.

Stopnie umiejętności zachowują kierunek autora: I — do trzech ciosów; II — wzmocnienie obrażeń; III — czwarty cios z wyraźnie podwyższoną szansą krytyka. Dla II proponuję premię wynikającą z treningu danej broni, bez automatycznego skalowania z poziomem bohatera. Dla finiszu proponuję premię dodawaną do bazowej szansy krytyka, ograniczoną maksymalną dopuszczalną szansą. Wcześniejsze wartości autora pozostają robocze; żadnych nowych wartości balansu nie zatwierdzamy w tym pakiecie.

### B. Obrona, wytrzymałość i obrażenia

#### Unik

Odskok jest zmianą pozycji, bez fazy magicznej nietykalności. Ratuje, kiedy wynosi bohatera poza tor lub zasięg ataku; skok w stronę ostrza nadal może skończyć się trafieniem. Kolizje nie pozwalają przejść przez wroga ani drzewo.

Unik służy przeciw zwierzętom, potworom i uzbrojonym wrogom. Nie jest szybszą metodą podróżowania niż zwykły ruch w dłuższym odcinku; ma własne zakończenie i koszt.

#### Garda i dobrze wyczuta parada

Broń wręcz pozwala chronić sektor przed bohaterem, skierowany ku kursorowi. Garda zatrzymuje zwykły cios bronią, zużywając wytrzymałość zależnie od siły uderzenia. Nie chroni pleców. Na potrzeby pierwszego prototypu nie dodajemy osobnego systemu tarcz.

Podniesienie gardy tuż przed trafieniem daje precyzyjną paradę: mniejszy koszt i krótkie zachwianie napastnika, tworzące okazję na kontrę. Nie zadaje samo obrażeń ani nie napełnia paska wytrzymałości.

Okno precyzyjnej parady odnawia się dopiero po faktycznym opuszczeniu gardy i zakończeniu tej akcji. Wielokrotne wciskanie klawisza nie może utrzymywać go bez przerwy. Zwykła garda pozostaje sensowną, mniej wydajną obroną.

Parowanie dotyczy ataków bronią wskazanych w zatwierdzonym kierunku. Potężny cios niemożliwy do zatrzymania jest rozpoznawalny po animacji i dodatkowym sygnale; gracz potrzebuje uniku. Szczególne wyjątki nie mogą opierać się wyłącznie na niewidocznym znaczniku przeciwnika.

#### Wytrzymałość

Proponuję jeden odnawialny zasób walki. Ataki, uniki i część umiejętności zużywają go, a garda płaci za przyjęte ciosy. Zwykły ruch nie kosztuje; sprint zużywa wytrzymałość [DECYZJA AUTORA, 28.10.2026], więc gracz ryzykuje wejście zmęczony w zasadzkę. Wytrzymałość odnawia się podczas oddechu między akcjami; wolniej przy podniesionej gardzie i nie podczas wykonywania kosztownej akcji.

Wyczerpanie osłabia działania zamiast odbierać możliwość przerwania ataku: unik jest krótszy i ma dłuższy powrót do gotowości, garda może zostać przełamana, a atak jest wolniejszy. Nadal można odwołać atak i spróbować się obronić. Dokładny model regeneracji i osłabienia trzeba zweryfikować w prototypie.

To zasób pojedynczego starcia. Nie zastępuje zapasów leczenia i amunicji zużywanych na całej wyprawie. Nie dokładamy teraz głodu ani osobnego paska postawy.

#### Trafienie, pancerz, krytyk

Kontakt → obrona → skutek trafienia. Krytyk jest losowym wzmocnieniem skutecznego trafienia; pancerz nadal działa. Czwarty cios zwiększa szansę krytyka, ale nie przebija automatycznie gardy ani nie trafia z dowolnej odległości.

Propozycja: pancerz redukuje obrażenia według odporności na rodzaj ataku, a parametry przebicia broni zmniejszają tę redukcję. Nie wykonujemy osobnego rzutu na to, czy pancerz zadziała. Formuły, wartości i minimalne obrażenia powstaną w etapie balansu.

### C. Walka na dystans i zakres prototypu

Kliknięcie wroga wskazuje cel, ale strzał po wypuszczeniu nie śledzi go. Ctrl + LPM pozwala wycelować przed poruszającym się celem. Postać obraca się i przygotowuje strzał, pozostając na miejscu; nie podchodzi automatycznie do wroga podczas przygotowania.

Łuk wymaga przygotowania każdego strzału. Kusza pozwala przygotować bełt wcześniej, ale po strzale potrzebuje dłuższego przeładowania. Unik i garda przerywają przygotowanie, zanim pocisk zostanie wypuszczony; nie tracimy niewystrzelonej amunicji. Przerwane przeładowanie trzeba zacząć ponownie. Po wypuszczeniu pocisk pozostaje aktywny niezależnie od dalszych akcji bohatera.

Przy broni dystansowej przycisk gardy odwołuje przygotowanie strzału, ale nie daje możliwości parowania łukiem lub kuszą. Po zmianie na broń wręcz można korzystać z gardy; zmiana broni ma własny czas i nie jest natychmiastowym blokiem. Unik jest główną obroną strzelca.

Umiejętności skracają przygotowanie lub przeładowanie i odblokowują techniki. Nie decydują losowo, czy poprawnie wycelowany pocisk zniknie przed celem. Wskazanie celu, płaszczyzna celowania i kolizje wymagają próby w wybranej perspektywie kamery.

Proponowany PPM do pierwszego prototypu wręcz: pchnięcie rozbijające zwykłą gardę przeciwnika. Jest czytelnie zapowiadane, kosztowniejsze od zwykłego ataku i daje słabszy rezultat przeciw niebroniącemu się celowi. Tworzy powód do użycia umiejętności inny niż jej ciągłe powtarzanie.

Pierwsza próba: broń jednoręczna, przeciwnik uzbrojony, zwierzę i przeszkody terenowe. Najpierw sprawdzamy przerwania, rytm i obronę. Łuk oraz kuszę dokładamy po ustabilizowaniu sterowania wręcz. To proponowana kolejność testów, nie deklaracja terminu ani gotowości pełnego demo.

### Pętle i sygnały dla gracza

| Skala | Cel | Przeszkoda | Informacja zwrotna | Nagroda |
|---|---|---|---|---|
| Wymiana | Trafić lub wybronić zagrożenie | Zasięg, obrona, moment ataku | Animacja, dźwięk kontaktu, pasek wytrzymałości | Przewaga pozycji i obrażenia |
| Starcie | Pokonać zagrożenie bez nadmiernych strat | Grupa i ukształtowanie terenu | Liczba zagrożeń, zdrowie, zapasy | Dostęp do miejsca lub celu |
| Wyprawa | Wykonać zadanie i wrócić | Zużycie zapasów i nieznana trasa | Dziennik, stan wyposażenia | Nagroda zadania, rzadka zdobycz |
| Rozwój | Zdobyć większe możliwości | Wymagające cele i dostęp do nauki | Awans, PN, nowe ogniwa łańcucha | Techniki otwierające nowe decyzje |

### Macierz najważniejszych interakcji

| Połączenie | Proponowany wynik |
|---|---|
| Atak + unik/garda | Natychmiastowe anulowanie pozostałej części własnego ataku; koszty i już zadane obrażenia pozostają. |
| Wiązanka + obrona/PPM | Reset łańcucha. |
| Wiązanka + chybienie/obrona celu | Reset, bez ładowania finiszu na pustych ciosach. |
| Wiązanka + nowy cel | Kontynuacja możliwa przy zachowaniu rytmu i kontaktu. |
| Garda + atak od tyłu/nieparowalny | Brak ochrony; potrzebne ustawienie lub unik. |
| Garda + wyczerpanie | Możliwe przełamanie; nie ma nieskończonego blokowania. |
| Precyzyjna parada + kontratak | Okazja dzięki zachwianiu; bez automatycznej riposty. |
| Unik + przeszkoda | Ruch ograniczony kolizją; brak przenikania. |
| Pocisk + anulowanie przed/po wystrzale | Przed: brak pocisku i zużycia amunicji; po: pocisk pozostaje. |
| Krytyk + pancerz | Większy potencjał obrażeń, nadal stosowane reguły pancerza. |
| PPM + zwykła garda celu | Rozbicie gardy; możliwość uniknięcia techniki. |

### Przegląd projektu według skilla

To analiza, nie wyniki testów. Nie przyznajemy projektowi statusu zweryfikowanej gry.

| Akcja | Przydatna sytuacja A / B | Gorszy wybór A / B |
|---|---|---|
| Ruch | Podejście poza walką / zajęcie flanki | Bezpośredni szybki atak / zamknięta droga |
| Podstawowy atak | Krótka okazja / przerwanie odsłoniętego wroga | Podniesiona garda / trwający zamach wroga |
| Kontynuacja łańcucha | Długa luka obrony / odizolowany cel | Flankowanie przez drugiego wroga / wyczerpanie |
| Unik | Atak zwierzęcia / atak nieparowalny | Ściana na torze / utrata dobrej pozycji wobec zwykłego ciosu |
| Garda | Zwykły cios od frontu / mało miejsca na odskok | Atak z tyłu / atak potwora |
| Precyzyjna parada | Czytelny pojedynczy zamach / wymuszenie kontry | Nachodzące ataki / źle rozpoznany rytm |
| PPM rozbijający gardę | Broniący się przeciwnik / odblokowanie przejścia | Zwierzę bez gardy / nadchodzący atak flankujący |
| Strzał | Otwarta linia / wróg w oddali | Nacisk w zwarciu / zasłonięty cel |

Główne ryzyka i próby:

- MEC-R07: wielokrotne atak–garda nie może skracać przygotowania następnego ciosu ani zwracać wytrzymałości. Sprawdzić szybkość zadawania obrażeń przy takim spamie.
- MEC-R03: utrzymanie gardy nie może być zawsze najlepsze. Sprawdzić ataki z różnych kierunków, koszt przyjmowania ciosów i powód do precyzyjnej parady.
- MEC-R03: testować nieskończone cofanie i strzelanie. Koszt przeładowania, teren i zachowania wrogów muszą tworzyć ryzyko bez teleportowania przeciwników.
- MEC-R03: wyczerpany unik nie może stać się darmowym, równie skutecznym odpowiednikiem pełnego uniku. Sprawdzić dystans, gotowość i realną możliwość odzyskania oddechu.
- MEC-R08: najpierw sprawdzić przyjemność samej wymiany bez łupów i awansów. Nie maskować słabego sterowania nagrodami.
- MEC-R10: sprawdzić nakładanie funkcji LPM, kierunek kursora podczas gardy i uniku oraz przypadkowe polecenia dojścia.
- MEC-R12: osobne sygnały pudła, parady, pancerza, krytyka i utraty rytmu. Gracz musi rozumieć powód wyniku.

Silnik: Godot 4 ([decyzja warunkowa](SILNIK.md)). Brak danych o zespole uniemożliwia rzetelną wycenę czasu; pakiet nie zawiera takiej wyceny. Leczenie, śmierć, zapis gry i gospodarka wypraw będą kolejnym pakietem, żeby nie mieszać ich z rozstrzygnięciem podstaw walki.
