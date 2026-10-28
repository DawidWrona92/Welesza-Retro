# Pakiet do walidacji 01 — walka

Status: propozycja projektowa do oceny przez autora. Nie stanowi zatwierdzonej implementacji ani balansu.
Metoda: core-loop-mechanics, tryb Design i przegląd według listy Review. Podstawa: [ustalenia walki](walka-i-trafienia.md), [mechaniki](mechaniki-podstawy.md).

## Cel i granice pakietu

Łączymy sterowanie myszą z walką wymagającą rozpoznania zagrożenia, rytmu i decyzji o przerwaniu ataku. Zatwierdzone kierunki: groźne małe grupy, sprawczość gracza, rozwój u nauczycieli oraz znaczenie przygotowania. Ich kolejność przy konfliktach nie została ustalona.

Nowa decyzja autora: unik i parada muszą móc przerwać rozpoczęty atak. Proponowane niżej koszty, efekty, klawisze i reguły resetowania łańcucha wymagają oceny wraz z całym pakietem.

Proponowane identyfikatory: MECH-cancel-defense, MECH-rhythm-chain, MECH-guard, MECH-dodge, MECH-stamina, MECH-ranged-aim. Nie są wpisami zatwierdzonego rejestru.

## A. Sterowanie, rytm i przerwanie

| Czynność | Wejście — propozycja przypisania | Efekt | Koszt lub ograniczenie | Cel projektowy |
|---|---|---|---|---|
| Ruch | LPM na terenie | Przejście do punktu | Przeszkody, czas przejścia | Pozycjonowanie |
| Atak wręcz | LPM na przeciwniku | Jeden cios; poza zasięgiem dojście i jeden cios | Czas i wytrzymałość | Świadomy atak |
| Atak w miejscu | Shift + LPM | Cios albo strzał w kierunku kursora bez dojścia | Te same koszty co zwykły atak | Jednoznaczna intencja |
| Unik | Spacja | Krótki odskok ku kursorowi | Wytrzymałość, przestrzeń do ruchu, koniec wiązanki | Reakcja na zagrożenie |
| Garda/parada | Przytrzymanie Q | Obrona od strony kursora | Koszt przyjęcia ciosu, wolniejszy ruch | Obrona przeciw broni |
| Umiejętność | PPM | Wybrana aktywna technika | Koszt i ograniczenie techniki | Rozwój możliwości |
| Strzał | LPM na celu lub Shift + LPM w punkt | Przygotowanie i pojedynczy strzał | Amunicja i czas | Walka na dystans |

Klawisze zmienialne. Logika akcji oddzielona od urządzenia wejścia, żeby późniejsze dodanie pada nie wymagało zmiany zasad walki. Nie ustalamy jeszcze mapowania pada.

### Reguła przerwania

- Unik i podniesienie gardy przerywają każdą fazę własnego ataku: przygotowanie, zamach i powrót po ciosie. Obrona ma pierwszeństwo przed oczekującym kolejnym atakiem; kolejka zostaje wyczyszczona.
- Jeżeli obrażenia już zostały zadane albo pocisk wypuszczony, pozostają w świecie. Przerwanie nie cofa skutków. Przerwanie przed kontaktem usuwa przyszły kontakt tego ciosu.
- Koszt rozpoczętego ciosu nie jest zwracany. Obrona kończy wiązankę. Gracz wymienia szansę na silniejszy kolejny cios na bezpieczeństwo.
- Anulowanie ataku nie oznacza odporności na atak, który już trafił. Stan ogłuszenia po otrzymaniu ciosu nie jest własnym atakiem; jego reguły wymagają osobnego testu.
- Nowy atak po obronie ma własne przygotowanie i koszt. Nie można usuwać czasu ataku przez szybkie przełączanie atak–garda–atak i pomijać kolejnego przygotowania.
- Podczas przytrzymanej gardy nie atakujemy. Trzeba ją zwolnić i wykonać świadomy atak. Po uniku nie wykonuje się automatycznie starego polecenia ataku.

### Wiązanki

Propozycja: wiązanki dotyczą broni wręcz. Każda rodzina broni ma czytelny rytm wynikający z animacji, wspierany dźwiękiem i opcjonalnym wskaźnikiem. Broń dystansowa ma własny rytm przygotowania/przeładowania, bez przenoszenia czwartego ciosu na strzały.

Pierwszy klik rozpoczyna podstawowy cios. Kliknięcie w oknie następnego ogniwa przechodzi do dalszego ciosu. Przedwczesne kliknięcie zamyka możliwość przedłużenia tej wiązanki, ale nie zatrzymuje wykonywanego ataku. Kolejne kliknięcia nie przyspieszają animacji ani nie tworzą długiej kolejki. Wciąż można normalnie wykonać kolejny podstawowy atak po gotowości broni.

Proponowane zakończenia wiązanki: własny unik lub garda, użycie PPM, chybienie, skuteczna obrona przeciwnika, otrzymanie trafienia przerywającego akcję albo przekroczenie okna rytmu. Sama zmiana celu nie resetuje łańcucha, jeśli kolejny cios jest poprawnie wykonany i trafia; ciosy w powietrze nie pozwalają przygotować finiszu poza walką.

Stopnie umiejętności zachowują kierunek autora: I — do trzech ciosów; II — wzmocnienie obrażeń; III — czwarty cios z wyraźnie podwyższoną szansą krytyka. Dla II proponuję premię wynikającą z treningu danej broni, bez automatycznego skalowania z poziomem bohatera. Dla finiszu proponuję premię dodawaną do bazowej szansy krytyka, ograniczoną maksymalną dopuszczalną szansą. Wcześniejsze wartości autora pozostają robocze; żadnych nowych wartości balansu nie zatwierdzamy w tym pakiecie.

## B. Obrona, wytrzymałość i obrażenia

### Unik

Odskok jest zmianą pozycji, bez fazy magicznej nietykalności. Ratuje, kiedy wynosi bohatera poza tor lub zasięg ataku; skok w stronę ostrza nadal może skończyć się trafieniem. Kolizje nie pozwalają przejść przez wroga ani drzewo.

Unik służy przeciw zwierzętom, potworom i uzbrojonym wrogom. Nie jest szybszą metodą podróżowania niż zwykły ruch w dłuższym odcinku; ma własne zakończenie i koszt.

### Garda i dobrze wyczuta parada

Broń wręcz pozwala chronić sektor przed bohaterem, skierowany ku kursorowi. Garda zatrzymuje zwykły cios bronią, zużywając wytrzymałość zależnie od siły uderzenia. Nie chroni pleców. Na potrzeby pierwszego prototypu nie dodajemy osobnego systemu tarcz.

Podniesienie gardy tuż przed trafieniem daje precyzyjną paradę: mniejszy koszt i krótkie zachwianie napastnika, tworzące okazję na kontrę. Nie zadaje samo obrażeń ani nie napełnia paska wytrzymałości.

Okno precyzyjnej parady odnawia się dopiero po faktycznym opuszczeniu gardy i zakończeniu tej akcji. Wielokrotne wciskanie klawisza nie może utrzymywać go bez przerwy. Zwykła garda pozostaje sensowną, mniej wydajną obroną.

Parowanie dotyczy ataków bronią wskazanych w zatwierdzonym kierunku. Potężny cios niemożliwy do zatrzymania jest rozpoznawalny po animacji i dodatkowym sygnale; gracz potrzebuje uniku. Szczególne wyjątki nie mogą opierać się wyłącznie na niewidocznym znaczniku przeciwnika.

### Wytrzymałość

Proponuję jeden odnawialny zasób walki. Ataki, uniki i część umiejętności zużywają go, a garda płaci za przyjęte ciosy. Zwykły ruch nie kosztuje. Wytrzymałość odnawia się podczas oddechu między akcjami; wolniej przy podniesionej gardzie i nie podczas wykonywania kosztownej akcji.

Wyczerpanie osłabia działania zamiast odbierać możliwość przerwania ataku: unik jest krótszy i ma dłuższy powrót do gotowości, garda może zostać przełamana, a atak jest wolniejszy. Nadal można odwołać atak i spróbować się obronić. Dokładny model regeneracji i osłabienia trzeba zweryfikować w prototypie.

To zasób pojedynczego starcia. Nie zastępuje zapasów leczenia i amunicji zużywanych na całej wyprawie. Nie dokładamy teraz głodu ani osobnego paska postawy.

### Trafienie, pancerz, krytyk

Kontakt → obrona → skutek trafienia. Krytyk jest losowym wzmocnieniem skutecznego trafienia; pancerz nadal działa. Czwarty cios zwiększa szansę krytyka, ale nie przebija automatycznie gardy ani nie trafia z dowolnej odległości.

Propozycja: pancerz redukuje obrażenia według odporności na rodzaj ataku, a parametry przebicia broni zmniejszają tę redukcję. Nie wykonujemy osobnego rzutu na to, czy pancerz zadziała. Formuły, wartości i minimalne obrażenia powstaną w etapie balansu.

## C. Walka na dystans i zakres prototypu

Kliknięcie wroga wskazuje cel, ale strzał po wypuszczeniu nie śledzi go. Shift + LPM pozwala wycelować przed poruszającym się celem. Postać obraca się i przygotowuje strzał, pozostając na miejscu; nie podchodzi automatycznie do wroga podczas przygotowania.

Łuk wymaga przygotowania każdego strzału. Kusza pozwala przygotować bełt wcześniej, ale po strzale potrzebuje dłuższego przeładowania. Unik i garda przerywają przygotowanie, zanim pocisk zostanie wypuszczony; nie tracimy niewystrzelonej amunicji. Przerwane przeładowanie trzeba zacząć ponownie. Po wypuszczeniu pocisk pozostaje aktywny niezależnie od dalszych akcji bohatera.

Przy broni dystansowej przycisk gardy odwołuje przygotowanie strzału, ale nie daje możliwości parowania łukiem lub kuszą. Po zmianie na broń wręcz można korzystać z gardy; zmiana broni ma własny czas i nie jest natychmiastowym blokiem. Unik jest główną obroną strzelca.

Umiejętności skracają przygotowanie lub przeładowanie i odblokowują techniki. Nie decydują losowo, czy poprawnie wycelowany pocisk zniknie przed celem. Wskazanie celu, płaszczyzna celowania i kolizje wymagają próby w wybranej perspektywie kamery.

Proponowany PPM do pierwszego prototypu wręcz: pchnięcie rozbijające zwykłą gardę przeciwnika. Jest czytelnie zapowiadane, kosztowniejsze od zwykłego ataku i daje słabszy rezultat przeciw niebroniącemu się celowi. Tworzy powód do użycia umiejętności inny niż jej ciągłe powtarzanie.

Pierwsza próba: broń jednoręczna, przeciwnik uzbrojony, zwierzę i przeszkody terenowe. Najpierw sprawdzamy przerwania, rytm i obronę. Łuk oraz kuszę dokładamy po ustabilizowaniu sterowania wręcz. To proponowana kolejność testów, nie deklaracja terminu ani gotowości pełnego demo.

## Pętle i sygnały dla gracza

| Skala | Cel | Przeszkoda | Informacja zwrotna | Nagroda |
|---|---|---|---|---|
| Wymiana | Trafić lub wybronić zagrożenie | Zasięg, obrona, moment ataku | Animacja, dźwięk kontaktu, pasek wytrzymałości | Przewaga pozycji i obrażenia |
| Starcie | Pokonać zagrożenie bez nadmiernych strat | Grupa i ukształtowanie terenu | Liczba zagrożeń, zdrowie, zapasy | Dostęp do miejsca lub celu |
| Wyprawa | Wykonać zadanie i wrócić | Zużycie zapasów i nieznana trasa | Dziennik, stan wyposażenia | Nagroda zadania, rzadka zdobycz |
| Rozwój | Zdobyć większe możliwości | Wymagające cele i dostęp do nauki | Awans, PN, nowe ogniwa łańcucha | Techniki otwierające nowe decyzje |

## Macierz najważniejszych interakcji

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

## Przegląd projektu według skilla

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

## Sposób walidacji

Autor ocenia łącznie bloki A, B i C. Wskazuje akceptowane bloki i wyjątki. Dopiero po tej odpowiedzi nowe propozycje przechodzą do dokumentu zatwierdzonych zasad. Szczegółowych liczb nie ustalamy przed próbą mechaniki.
