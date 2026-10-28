# Plac przy wozie — pakiet dla projektu i prototypu

**Status:** propozycja układu i inscenizacji do oceny autora i testów, 27 października 2026. Nie jest gotowym poziomem, pomiarem ani nowymi faktami świata. Schemat pokazuje relacje i pozycje robocze, nie rzeczywiste rozmiary, kamerę ani kierunki geograficzne.

![Propozycja planu placu z góry](plac-przy-wozie.svg)

## 1. Co jest ustalone, a co proponujemy

| Element | Status | Źródło / uwaga |
|---|---|---|
| Trzy dni deszczu, błotnisty trakt, wóz, żywy koń, pakunki, ślady walki i buty ustawione równo | Fabuła zaakceptowana | [Fabuła demo](demo-fabula.md) |
| Dwa przejścia wokół wozu, rozstaj, brzeg i pętla | Propozycja projektowa | [Mapa](pakiet-04-mapa.md); do sprawdzenia w prototypie |
| Pierwsza wizyta bez aktywnego starcia; rankiem Pies przy jedzeniu, Powrotnik dalej | Propozycja inscenizacji | [Początek gry](pakiet-04-poczatek.md), do walidacji |
| Brak widocznych ekranów ładowania podczas normalnego przemieszczania się | Cel autora | Nie ustala sposobu doczytywania ani zachowania przy uruchomieniu/wczytaniu zapisu |
| Dokładne ustawienie konia, butów, pakunków i strefy Psa | Propozycja na rysunku | Dostosować do skali, odczytu i nawigacji; nie traktować jako kanonu |

## 2. Plan do blockoutu

- Oś traktu łączy wejście prologu z placem i dalszą ścieżką do rozstaju oraz bramy. Schemat nie przedstawia dokładnej odległości od osady. W prologu gracza prowadzi punkt światła, nie obowiązkowa daleka panorama Niemiru.
- Wóz zajmuje środek szerszego fragmentu traktu. Po obu bokach zaplanowano przejście od jednego końca wozu do drugiego. Zaznaczone linie są propozycją przebiegu, nie dowodem dostępności; dyszle, koń i rekwizyty muszą pozostawić obie trasy drożne.
- Buty umieścić przy widocznym kole, pakunki i księgę w pobliżu wozu, ale osobno. Sprawdzić widoczność ze startowej pozycji; interakcja z butami jest opcjonalna. Ustalenie dokładnego miejsca pakunków jest robocze.
- Koń jest żywy przy pierwszym spotkaniu. Jego stan przy powrocie, animacje i możliwość interakcji pozostają otwarte; nie zakładać ich na podstawie ilustracji. Zaprzęg i miejsce konia dopasować po sprawdzeniu konstrukcji.
- Przy powrocie strefa Psa jest przy obrzeżu placu, przy jedzeniu; pozwala na czytelne podejście. Powrotnika umieścić dalej poza pierwszym wywołaniem; w schemacie go nie umieszczono. Walka z obydwoma nie jest obowiązkowym warunkiem odzyskania pakunków.
- Odnogi do brzegu i na zapętlającą się ścieżkę są symboliczne. Ich ostateczne położenie, widoczność i granice w prologu wymagają projektu. Unikać szerokiej drogi, która wygląda na dostępną, a jest niewytłumaczalnie zablokowana.
- Jasny obszar „unik?” wskazuje kandydata na przestrzeń testową; test wykonać w kilku kierunkach, bez zakładania, że tylko tam można wykonać unik. Rozmiary wynikną z pomiarów postaci, przeciwnika i kamery.

## 3. Przebieg — dwie wizyty w tej samej przestrzeni

| Etap | Gracz i widoczne elementy | Stan i otwarte kwestie |
|---|---|---|
| Prolog | Podejście do wozu i żywego konia, opcjonalne obejrzenie butów, zauważenie światła i przejście do bramy | W proponowanej inscenizacji bez aktywnej walki. Nie rozstrzygamy, czy konia można dotknąć, odpiąć lub zabrać. |
| Po nocy | Powrót przez bramę i rozstaj; Pies przy jedzeniu, Powrotnik dalej; odzyskanie pakunków i znalezienie księgi | Stan wozu i przedmiotów jest wspólny dla obu wizyt. Dokładne zmiany stanu konia oraz stan ładunku przed przyjęciem zadania pozostają do uzgodnienia. |
| Dalsza obserwacja | Opcjonalne sprawdzenie brzegu i drogi, która wraca do wozu; powrót do osady | Pętla nie resetuje stanu, nie przenosi aktywnej walki i nie ujawnia rozwiązania przez nagły montaż. Sposób techniczny nieustalony. |

W istniejącym projekcie pakunki i księga są przy wozie, nie w losowym łupie. Ominięcie lub pokonanie wrogów powinno być możliwe, a pakunki mają zostać rozliczone tylko raz. Sposób działania, gdy gracz dotrze do pakunków przed formalnym przyjęciem zadania, trzeba doprecyzować przed implementacją.

## 4. Elementy i warstwy

| Element | Wizualnie | Potrzeba w prototypie | Status |
|---|---|---|---|
| Podłoże traktu i ściółka | Moduły; spójne przejścia, mokra paleta | Obszar przechodni, bez dekoracyjnych przeszkód w nawigacji | Assety Vibe'a oczekiwane, użyć placeholderów |
| Wóz | Skrzynia, rama, koła, zaprzęg; oddzielny cień, jeśli metoda pozwala | Bryła kolizji i test przesłaniania; sprawdzić zasłanianie pocisków według mapy | Istnieje prosty blockout, nie produkcyjny model |
| Koń | Oddzielny obiekt, czytelny obok wozu | Tymczasowy obrys i pozycja; status zachowania otwarty | Placeholder bez fabularnego dopowiadania |
| Buty | Oddzielny mały rekwizyt przy kole | Opcjonalny punkt interakcji, dostępny bez klikania koła | Nie ustalać zachowania poza opisem prologu |
| Pakunki i księga | Oddzielne, widoczne elementy przy wozie | Wykrywalne i zapamiętywane po podniesieniu; test jednokrotnego rozliczenia | Zachowanie przed zadaniem do ustalenia |
| Kamienie, korzenie, drzewa | Oddzielne dekoracje, korony na osobnej warstwie lub równoważny mechanizm | Obrys tylko tam, gdzie wizualnie i projektowo uzasadniony; test przejść i zasłaniania | Placeholdery do czasu oceny assetów Vibe'a |
| Pies i Powrotnik | Rozpoznawalne sylwetki, własne stany | Osobne pozycje i wywołania, telegraph widoczny; brak nieoczekiwanego wspólnego ataku | Inscenizacja do walidacji |
| Światło w kierunku bramy | Mały czytelny punkt, nie rozległa łuna | Prowadzi wzrok; nie wymaga ustawienia odległej bramy w tym samym kadrze | Sposób oświetlenia otwarty |

Sortowanie postaci i obiektów oraz odsłanianie koron należy rozwiązać i sprawdzić w docelowej kamerze. Ilustracja ani plan z góry nie przesądzają techniki renderowania, atlasów, cieni czy silnika.

## 5. Testy odbioru — do wykonania w prototypie

Najpierw zmierzyć D — obrys kolizji bohatera, B — obrys właściwego przeciwnika, U — pełny dystans uniku i V — widoczny obszar kamery. Nie podstawiać zmyślonych wartości. Wyniki zapisywać wraz z wersją prototypu, ustawieniami, zrzutem lub nagraniem; każde kryterium ma obecnie status **niewykonane**.

1. **Obejścia:** kliknąć na przemian po przeciwnych końcach obu tras, także w pobliżu konia i dyszli; sprawdzić brak klinowania bohatera, odpowiednią dostępność dla B i zgodność widocznej przestrzeni z kolizją.
2. **Unik:** ze strefy walki wykonać unik w kilku kierunkach, obserwując cały tor U oraz obszar startu i końca; nie może zatrzymać go niewidzialny rekwizyt ani prowadzić w ślepą pułapkę bez czytelnej przyczyny.
3. **Czytelność:** z początkowej kamery zobaczyć wóz i konia; sprawdzić możliwość odnalezienia butów przy podejściu, pakunków i kierunku do światła. Ocenić w normalnej skali i na ciemnym tle.
4. **Przesłanianie:** przejść z postacią przed i za wozem, kołami, koniem oraz koronami drzew. Bohater i zapowiedź ataku pozostają czytelne; artefakty kolejności są raportowane.
5. **Dwie wizyty:** pierwsza wizyta bez aktywnej walki, następnie powrót i osobne wywołanie Psa; Powrotnik nie pojawia się automatycznie w pierwszym starciu. Test ominięcia i odzyskania pakunków.
6. **Trwałość:** powrót do osady, zapis/wczytanie i powrót na plac nie duplikują odzyskanych pakunków ani nagrody; stan innych obiektów zgodny z przyjętą implementacją. Nie zakładać nieustalonego stanu konia.
7. **Płynne przejście:** przejść i wrócić na odcinku wóz → rozstaj → brama bez widocznego ekranu ładowania. Na dostępnej platformie zanotować przycięcia, wyskakiwanie obiektów oraz czasy klatek i pamięć — bez obietnicy wyniku przed pomiarem.
8. **Pętla:** po jej implementacji sprawdzić rozpoznanie tego samego wozu i znaku, trwałość stanu, brak przeniesienia aktywnej walki i brak widocznego skoku. To osobne zadanie, nie blokuje pierwszego statycznego blockoutu.

## 6. Przekazanie Codexowi

1. Przeczytaj [fabułę](demo-fabula.md), [początek](pakiet-04-poczatek.md), [mapę](pakiet-04-mapa.md) i [koncepcję wozu](https://github.com/DawidWrona92/RPG-OldSchool/blob/main/docs/koncepty/18-woz-i-trakt.md). Sprawdź bieżące zmiany aktywnych gałęzi przed użyciem.
2. Zbuduj na własnej gałęzi geometryczny blockout placu i połączenia z rozstajem. Zastosuj placeholdery dla terenu, Psa, bohatera i konia; nie czekaj na Vibe'a. Nie modyfikuj aktywnych branchy innych wykonawców.
3. Blockout wozu znajduje się na [`vibe/environment-wagon-blockout`](https://github.com/DawidWrona92/RPG-OldSchool/tree/vibe/environment-wagon-blockout/assets/environment/wagon_blockout). Jest bardzo uproszczony: nie ma materiałów, riggu ani poprawnego zaprzęgu i nie został zweryfikowany w Blenderze. Można go zastąpić lub przebudować.
4. Zmierz D, B, U i V, zweryfikuj obejścia, unik, widoczność oraz przesłanianie. Wymiary i technikę dostosuj do faktycznego prototypu; wynik pokaż autorowi wraz z wadami.
5. Po dostarczeniu paczki Vibe'a oceniaj ją osobno i integruj wyłącznie pasujące elementy; zastąpienie placeholderów nie może zmienić dostępności przejść ani skali bez ponownego sprawdzenia.

Nie twórz gotowego zadania, systemu streamingowego ani finalnej geometrii pętli na podstawie tego planu bez dodatkowego projektu. Wszystkie opisane testy są obecnie niewykonane.
