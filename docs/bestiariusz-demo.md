# Bestiariusz Niemiru — pakiet 03

Status: propozycja do walidacji, nie działające AI. Zależności: [walka 01](propozycja-walki-01.md), [wyprawa 02](propozycja-wyprawy-02.md). Rozmieszczenie i boss fighty: [spotkania](spotkania-i-bossowie.md).
Nazwy i ID są propozycjami; wartości HP, obrażeń, prędkości i odporności będą osobnym etapem balansu.

## Zasady projektowe

Proponowana obsada: siedem typów zwykłych przeciwników (karta wilka do opracowania), dwóch minibossów i finałowy Stróż. Minibossowie korzystają z rodzin zachowań zwykłych przeciwników; nie wymagają trzech odrębnych systemów walki z bossami.

Groza wynika z życia, które nadal próbuje się powtarzać. Przeciwnik może strzec pustego domu, nieść niepotrzebny już zapas albo wołać kogoś, kto nie odpowie. Nie każdy jest świadomy i nie każdy rozumie, co robi. To wskazówki wykonawcze, nie ujawniona prawda o kosmologii Weleszy.

Przeciwników będzie wielu, dlatego każdy typ ma warianty wyglądu i uzbrojenia, żeby nie był to atak klonów [DECYZJA AUTORA, 28.10.2026]. Warianty jednego typu dzielą tryby ataku, np. hak i sierp na trzonku. Limit aktywnych wrogów w jednym starciu z projektu spotkań nadal obowiązuje.

Nie używamy dzieci jako przeciwników, przypadkowej makabry jako głównego środka ani żartobliwych odzywek przy śmierci. Ciała i rekwizyty mogą być niepokojące bez eksponowania okaleczeń.

Każdy groźny ruch ma sygnał wizualny i dźwiękowy; odróżnienie ataku nieparowalnego nie zależy wyłącznie od koloru. Przeciwnicy nie wykonują nieczytelnych ataków spoza ekranu. Roślinność musi odsłaniać sylwetkę podczas zapowiedzi ataku.

Nowe ofiary i istoty nie dopisują historii do zatwierdzonych NPC. Ślady człowieczeństwa są obserwacjami; ich interpretacja może pozostać niepewna. Żadna karta nie rozstrzyga źródła zamknięcia boru.

## Zwykli przeciwnicy

### ENM-zdziczaly-pies — Zdziczały pies

**Rola:** flankujący napastnik; porzucone zwierzę. **Pytanie:** czy potrafisz zejść z linii skoku, nie oddając drugiemu napastnikowi pleców?

**Sylwetka:** niski, wychudzony korpus; zerwany rzemień obroży; jasna łatka widoczna w ciemnym futrze. Dźwięk: warkot przechodzi w ciche skomlenie, kiedy traci cel. Nie jest to magiczny wilk.

**Zachowanie:** czujny, głodny, nerwowy. Chce bronić znalezionego pożywienia, boi się osaczenia. Przeczucie dawnego przywiązania: po walce siada czasem przy porzuconym wozie zamiast szukać kolejnej ofiary.

**Priorytety AI:** pilnuje miejsca → ostrzega → obiega cel po dostępnej stronie → atakuje po odsłonięciu → po chybieniu odzyskuje równowagę → ściga do czytelnej granicy. Samotny pies nie ma obowiązku rzucać się pod ostrze bez przerwy.

| Atak | Zapowiedź | Efekt | Odpowiedź i okazja |
|---|---|---|---|
| Skok do gardła | Przysiad, uszy do tyłu, krótki warkot | Skok po ustalonym torze; bez śledzenia gracza w locie | Unik w bok lub wyjście z toru; po chybieniu możliwość ciosu |
| Kłapnięcie | Odsunięcie łba i odsłonięcie kłów | Krótki atak blisko celu | Odstąpienie zamiast długiego łańcucha |

**Obrona:** ataków zwierzęcia nie parujemy. **Słabość:** długi skok oddaje inicjatywę, jeśli spudłuje. **Łup:** nie generuje monet; obroża może być rekwizytem bez wartości handlowej. **Występowanie:** bliżej wioski [DECYZJA AUTORA, 28.10.2026]: wóz, rozstaj, skraj traktu.

### ENM-wilk — Wilk

**[DECYZJA AUTORA, 28.10.2026]** Osobny potwór, odrębny od Zdziczałego psa. Duży i szary, wyraźnie większy od burego psa ([kierunek artystyczny](art/WELESZA_DARK_PAINTERLY_2D_KIERUNEK_ARTYSTYCZNY_v1.pdf), s. 9).

**Rola:** samotny myśliwy głębszego lasu; rodzina zachowań psa (skok do gardła, kłapnięcie, obieganie celu), ale trudniejszy. **Różnice:** więcej zdrowia i mocniejsze ugryzienie, krótsza okazja po chybionym skoku, chętniej atakuje z zaskoczenia; zapowiedź pozostaje równie czytelna. Wartości w etapie balansu.

**Występowanie:** las: kamienie, obóz, dalsze odnogi. Pojedynczo, najwyżej w parze, zgodnie z limitem aktywnych wrogów.

### ENM-powrotnik — Powrotnik

**Rola:** powolny napastnik; dawna ofiara traktu. **Pytanie:** czy zauważysz różnicę między niegroźnym powłóczeniem nogami a przygotowaniem chwytu?

**Sylwetka:** pochylony człowiek z workiem na plecach; ręka stale trzymająca węzeł; wyblakły pas tkaniny przy nadgarstku. Dźwięk: oddech i tarcie mokrej tkaniny. Nie wypowiada wyjaśniających zdań.

**Zachowanie:** uparty, zagubiony, przywiązany do drogi. Próbuje ruszyć dalej, lecz wraca do tego samego kamienia. Nie ma nowej frakcji ani potwierdzonego związku z duszą pierwotnej osoby.

**Priorytety AI:** powtarza krótki obchód → reaguje na wejście blisko → podchodzi bez sprintu → chwyta tylko z odpowiedniego zasięgu → wraca do worka po utracie celu.

| Atak | Zapowiedź | Efekt | Odpowiedź i okazja |
|---|---|---|---|
| Oburęczny chwyt | Odkłada worek, prostuje ramiona, nabiera powietrza | Krótki frontalny atak; bez QTE i długiej animacji więzienia gracza | Unik na bok, atak z flanki po chybieniu |
| Uderzenie tobołem | Unosi worek nad bark, słychać przedmioty w środku | Szeroki, bliski zamach | Odejść poza zasięg, wrócić podczas opuszczania worka |

**Obrona:** chwyty i uderzenie ciężkim workiem traktujemy jako nieparowalne. Sam gatunek „nieumarły” nie gwarantuje parowania — istotny jest atak bronią. **Słabość:** wolne odzyskiwanie pozycji. **Łup:** czasem konkretny przedmiot z historii miejsca, bez losowego skarbu. **Występowanie:** przy wozie, drogowskazach i kamieniach.

### ENM-drwal — Drwal z wygasłego obozu

**Rola:** uzbrojony przeciwnik uczący gardy; człowiek lub jego poruszające się szczątki, bez rozstrzygnięcia w karcie. **Pytanie:** kiedy parować narzędzie, a kiedy zejść z drogi ciężkiemu zamachowi?

**Sylwetka:** szerokie barki; długi topór; ciemny fartuch z jednym jasnym szwem. Dźwięk: przed atakiem przesuwa dłoń po trzonku; poza walką układa drwa.

**Zachowanie:** pracowity, drażliwy, wyczerpany. Broni pustego paleniska, choć drewno leży w wodzie. Chce przepędzić obcego; nie prowadzi zrozumiałej rozmowy.

**Priorytety AI:** ostrzega ruchem topora → broni wejścia → zwykły zamach w zasięgu → przy uporczywej gardzie gracza wybiera wyraźnie zapowiedziany ciężki atak → po chybieniu wraca do gotowości. Reakcja nie jest odczytem przycisku gracza w tej samej klatce.

| Atak | Zapowiedź | Efekt | Odpowiedź i okazja |
|---|---|---|---|
| Cięcie z boku | Obrót barków i szurnięcie trzonka | Parowalny zamach toporem | Garda lub precyzyjna parada; odsłonięta strona po zamachu |
| Rozłupanie | Obie dłonie nad głową, krótki bezruch, głośny wysiłek | Nieparowalne pionowe uderzenie | Zejść w bok; ostrze na chwilę grzęźnie w podłożu |

**Słabość:** silny, ale po ciężkim ataku nie odwraca się natychmiast. **Łup:** przygotowany materiał lub narzędzie związane z obozem; zwykła broń nie musi być ulepszeniem. **Występowanie:** obóz węglarzy i zadanie o narzędziach.

### ENM-lucznik — Łucznik pustego traktu

**Rola:** napastnik dystansowy; porzucony strażnik. **Pytanie:** jak skrócić dystans, korzystając z osłon i przerw między strzałami?

**Sylwetka:** wysoki łuk; asymetryczna peleryna; jasny kościany gwizdek na piersi. Dźwięk: tarcie cięciwy, czasem urwany sygnał, na który nikt nie odpowiada.

**Zachowanie:** zdyscyplinowany, ostrożny, samotny. Pilnuje nieistniejącej już odprawy kupieckiej. Boi się zamknięcia drogi odwrotu; nie ucieka w nieskończoność.

**Priorytety AI:** obserwuje drogę → ustawia linię strzału → naciąga widocznie → strzela w zablokowany przed wypuszczeniem kierunek → zmienia pozycję do wcześniej dostępnego punktu. W zwarciu odsuwa się, a jeśli nie ma miejsca, używa noża. Nie strzela przez osłony ani ściany.

| Atak | Zapowiedź | Efekt | Odpowiedź i okazja |
|---|---|---|---|
| Strzał | Wyprost, pełne naciągnięcie, skrzypienie cięciwy | Widoczny pocisk bez naprowadzania | Osłona lub ruch w poprzek; podejście między strzałami |
| Cięcie nożem | Odkłada łuk na bok i odsłania rękę z nożem | Parowalny, krótki cios | Garda/parada, nie zakładać bezbronności strzelca |

**Słabość:** ograniczone punkty odwrotu i przygotowanie strzału. **Łup:** niewielki, określony zapas amunicji przy stanowisku; jednorazowy. **Występowanie:** podejście do leśnej strażnicy, bez strzelania z nieosiągalnych balkonów.

### ENM-zalobnica — Żałobnica

**Rola:** wsparcie blokujące łatwą okazję; ślad żałoby. **Pytanie:** czy najpierw przerwiesz śpiew, czy odciągniesz chronionego przeciwnika?

**Sylwetka:** wąska postać; zwisający pusty płaszcz przewieszony przez ramiona jak niesiony człowiek; jasne dłonie. Dźwięk: melodia bez słów, kończąca się za każdym razem przed ostatnią nutą.

**Zachowanie:** cierpliwa, troskliwa, zaborcza. Zachowuje się, jakby próbowała kogoś ochronić. Nie potwierdzamy, czy jest człowiekiem, duchem czy obrazem wywołanym przez las.

**Priorytety AI:** pozostaje przy chronionym miejscu → rozpoczyna śpiew tylko przy widocznym sojuszniku → podtrzymuje osłonę jednego celu → przerywa po otrzymaniu trafienia lub utracie zasięgu/łączności wzrokowej → szuka nowej pozycji. Nie leczy HP i nie wskrzesza wrogów.

| Zdolność | Zapowiedź | Efekt | Odpowiedź i okazja |
|---|---|---|---|
| Niedokończona pieśń | Podniesienie pustego płaszcza, początek melodii, widoczne połączenie z celem | Jednorazowa redukcja następnego trafienia w chronionego wroga; nigdy pełna odporność; nie kumuluje się | Trafić śpiewającą, przerwać widoczność albo wyczerpać osłonę zwykłym ciosem |
| Odepchnięcie | Zbiera płaszcz przy piersi, gwałtowny wdech | Bliski, nieparowalny atak odpychający, bez dalszego przyciągania | Odskok, po ataku przerwa w śpiewie |

**Słabość:** nieruchoma podczas pieśni, osłona nie obejmuje jej samej. **Łup:** brak automatycznej kosztowności; po walce zostaje płaszcz jako ślad. **Występowanie:** późny fragment lasu; nowy efekt osłony wymaga implementacji i jest kandydatem do odłożenia przy ograniczeniu zakresu.

### ENM-korzeniec — Korzeniec

**Rola:** terytorialny brutal; przyroda zawłaszczająca ludzkie ślady. **Pytanie:** czy odróżnisz bezpieczny bok od dalekiego zasięgu przednich kończyn?

**Sylwetka:** niski, szeroki kadłub; długie przednie korzenie jak ramiona; skrawek lnianej tkaniny tkwiący w korze. Dźwięk: napinanie mokrego drewna, bez demonicznego śmiechu.

**Zachowanie:** nieruchomy, cierpliwy, gwałtowny po naruszeniu terenu. Otacza korzeniami porzucone przedmioty. Interpretacja, że kiedyś coś lub kogoś chronił, pozostaje domysłem.

**Priorytety AI:** przed wykryciem wyraźnie porusza się i oddycha, nie zadaje kontaktowych obrażeń z ukrycia → obraca się ku intruzowi → sięga daleko → po chybieniu powoli składa kończyny → po obejściu używa czytelnego ataku bocznego.

| Atak | Zapowiedź | Efekt | Odpowiedź i okazja |
|---|---|---|---|
| Zagarnięcie | Wysuwa korzenie po ziemi i napina je, słychać trzask | Długi atak stożkowy, nieparowalny | Unik poprzeczny; podejście do odsłoniętego boku |
| Przetoczenie | Wyraźnie przenosi ciężar na przeciwny bok | Krótki boczny atak przeciw ciągłemu obchodzeniu | Odejść od kadłuba, wrócić po ruchu |

**Słabość:** obrót i odzyskanie pozycji, brak nagłego teleportu do celu. **Łup:** zapasy lub rekwizyt znajdują się w otoczeniu, nie w losowej tabeli z ciała. **Występowanie:** korzenie przy kamieniach i odnoga z sidłami.

## Minibossowie i boss

### ENM-zbieracz — Zbieracz spod korzeni, opcjonalny miniboss

**Rodzina:** Korzeniec; większe przednie kończyny i asymetrycznie obrośnięty bark. **Rola:** kontrola kierunku podejścia; niejednoznaczny opiekun. Związany z „Pustymi sidłami”.

W jamie wiszą porozrywane sidła, a pod nimi leżą starannie ułożone zęby. Nie pokazujemy ludzkich ofiar ani nie wyjaśniamy pochodzenia zębów. Zbieracz osłania puste legowisko jak coś, co wciąż warto chronić.

**Osobowość w ruchu:** czujny, metodyczny, ochronny; niszczy pułapki, a równocześnie atakuje intruza. Chce odsunąć gracza od legowiska, nie ściga go do osady.

**Zdolności:** zagarnięcie i przetoczenie Korzeńca oraz szeroki zamach oboma ramionami, poprzedzony pełnym wyprostem i trzaskiem korzeni. Wszystkie nieparowalne. Szeroki zamach kończy się odsłonięciem boku; szczegóły faz w projekcie walki.

**Smutny akcent:** po zwycięstwie kamera nie pokazuje trofeum, tylko puste miejsce pod osłaniającymi je ramionami. Interpretacja należy do gracza. **Nagroda:** odzyskane zapasy i rozliczenie zadania, bez konieczności łupienia ciała.

### ENM-dzwigacz — Dźwigacz, miniboss przy strażnicy

**Rodzina:** zachowania Drwala; szeroka, ludzka sylwetka z nosidłem pełnym mokrego drewna. **Broń [DECYZJA AUTORA, 28.10.2026]:** hak lub sierp na trzonku, nie topór; oba warianty mają te same tryby ataku. **Rola:** test rozróżnienia parady i uniku; pracownik powtarzający obowiązek.

Wciąż nosi drewno do dawno zgasłego pieca. Nie wyjaśniamy, czy kieruje nim pamięć, rozkaz czy sama powtarzalność. Jest wyczerpany, uporczywy i pilnujący narzędzi; boi się pozostawić piec pusty. Przed walką stawia nosidło delikatniej, niż traktuje własne ciało.

**Zdolności:** parowalne cięcie hakiem lub sierpem, nieparowalne rozłupanie oraz nieparowalne pchnięcie nosidłem z widocznym wyprostowaniem pleców. Po utracie części zdrowia porzuca nosidło: znika pchnięcie, pojawia się drugi, wyraźnie zapowiedziany zamach hakiem lub sierpem.

**Słabość:** po ciężkim zamachu zostaje długa okazja; precyzyjna parada zwykłego cięcia daje krótszą. **Głos:** wydechy i krótkie pomruki, nie monolog wyjaśniający świat. **Nagroda:** bezpieczny dostęp do komory z latarnią; brak obowiązkowej amunicji, ognia lub specjalnej broni do zwycięstwa.

### ENM-stroz — Stróż, boss finałowy

**Rola:** finałowy test kontroli zachłanności; strażnik o nieznanym celu. **Sylwetka:** wysoka postać w starym żelazie; długa broń drzewcowa; przywiązane do pasa fragmenty podróżnych pakunków; zwykła latarnia [DECYZJA AUTORA, 28.10.2026]. Nie jest to magiczna latarnia z komory. Część przedmiotów przypomina wcześniejsze znaleziska, ale nie potwierdza to ich pochodzenia.

**Zachowanie:** cierpliwy, nieustępliwy, niemal ceremonialny. Staje między graczem a wyjściem; nie rabuje i nie świętuje zwycięstwa. Głosy są ciche, różne, czasem sprzeczne. Nie naśladuje bliskich bohatera ani nie dopisuje mu osobistej przeszłości.

**Chce:** zatrzymać przejście. **Boi się:** nieujawnione; nie ustanawiamy nowego kanonu. **Sprzeczność:** brutalnie atakuje, ale po utracie celu podnosi upuszczony pakunek, zanim wróci do posterunku.

**Zdolności:** parowalne cięcie drzewcem, nieparowalne pionowe uderzenie, oznaczony szarżujący pochód oraz oślepienie latarnią [DECYZJA AUTORA, 28.10.2026]: świeci zwykłą latarnią w oczy bohatera. Latarnia jest też rekwizytem i źródłem światła areny. Kolejne fazy zmieniają sposób zakończenia kombinacji, nie dodają tłumu przywołań. Szczegółowy przebieg w projekcie walki.

**Smutny akcent:** przy śmierci pakunki spadają na ziemię, a urwany głos kończy zwyczajne „już idę”. Nie wyjaśniamy, kto mówił. Muzyka milknie; słychać tylko las. **Nagroda:** otwarte przejście i spełniony cel demo, bez fontanny złota.

## Zależności i priorytet wykonania

Najpierw Pies i Drwal: sprawdzają unik, paradę oraz przerwanie wiązanki. Potem Powrotnik i Łucznik, następnie Korzeniec i jego miniboss. Żałobnica wymaga dodatkowego efektu osłony, więc ma najniższy priorytet w pierwszym prototypie. Dźwigacz i Stróż wymagają reżyserii faz oraz testów areny.

Przy ograniczaniu zakresu najpierw odkładamy Żałobnicę i opcjonalnego Zbieracza, zachowując ich projekty. Nie usuwamy automatycznie zaakceptowanych zadań; ewentualne cięcie treści wymaga walidacji autora.

Każda broń i sylwetka potrzebują osobnego sprawdzenia czytelności w docelowej kamerze. Nie podajemy wyceny produkcji bez ustalenia zespołu i testu produkcji grafiki 2D w Godocie.
