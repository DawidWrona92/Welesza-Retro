# Welesza — podstawy mechanik

Data: 26 października 2026 r.
Status: zapis decyzji autora oraz osobno oznaczona propozycja do dalszego omówienia. Nie jest to gotowa specyfikacja implementacji ani zatwierdzony balans.

Powiązania: [fabuła demo](demo-fabula.md), [kolejność prac](przed-prototypem.md).

## 1. Decyzje autora

| Obszar | Ustalenie |
|---|---|
| Platforma | PC, mysz i klawiatura; możliwość późniejszego dodania obsługi pada. |
| Sterowanie | Jak w Diablo 2: sterowanie myszą. Perspektywa kamery do ustalenia w prototypie. LPM: ruch i atak; PPM: umiejętność; unik i parada pod osobnymi klawiszami. Konkretne klawisze obrony pozostają do wyboru. |
| Tryb | Wyłącznie single player. |
| Sprint | Zostaje; zużywa wytrzymałość. Część przeciwników atakuje z zaskoczenia, więc gracz ryzykuje, że wejdzie do walki zmęczony (28.10.2026). |
| Walka | Mniejsza liczba groźnych przeciwników, precyzyjne wyczucie momentu ataku. Przeciw potworom i zwierzętom: unik. Przeciw ludziom walczącym bronią i podobnym uzbrojonym przeciwnikom, np. szkieletom lub zombie: unik oraz parada. |
| Unik | Osobny klawisz, krótki odskok w kierunku kursora zgodnie z zaakceptowaną rekomendacją. Koszt i ograniczenia pozostają otwarte. |
| Atak i wiązanki | Atak na kliknięcie, bez ciągłego atakowania po przytrzymaniu. Bezładne klikanie daje podstawowy atak; trafianie kliknięciami w rytm uruchamia wiązankę, w której kolejne ciosy zadają większe obrażenia. Umiejętność określa długość łańcucha i jego premie: podstawowy stopień daje do trzech ciosów, III daje cztery, a czwarty cios znacząco zwiększa szansę losowego krytyka. Liczby i otwarte szczegóły opisano w dokumencie walki. |
| Sprawczość gracza | Autor odrzuca rozstrzyganie trafień kostką. Trafienia wręcz wynikają z kontaktu i obrony, dystansowe z toru lotu i sytuacji w świecie. Pancerz osłabia trafienie. Losowe krytyki pozostają osobnym efektem trafienia; poprawny czwarty cios znacząco zwiększa ich szansę, ale nie gwarantuje krytyka. |
| Broń dystansowa | Autor proponuje kalkulację z uwzględnieniem umiejętności, dystansu i pancerza. Rozdzielenie trafienia oraz działania pancerza zostało zaakceptowane; szczegóły celowania pozostają otwarte, a losowe testy trafienia są odrzucone. |
| Zagrożenie | Inspiracja WFRP: walka przeciw trzem przeciwnikom naraz ma być bardzo niebezpieczna. Nie ustalono automatycznej porażki ani konkretnej szansy przeżycia. |
| Rozwój | Inspiracja WFRP; doświadczenie prowadzi do awansów, awanse dają Punkty Nauki (PN), a PN wydajemy u nauczycieli, na wzór Gothic. |
| Łupy | Rzadkie, bardzo cenne, dające wyraźne poczucie zwycięstwa i postępu. |
| Wyprawa | Przygotowanie w osadzie → eksploracja → starcie → nagroda → powrót po nagrodę lub naganę. |
| Zasoby | Wymagające gospodarowanie zapasami. Autor wycofał procentowy cel ich wyczerpania; tempo zużycia i presję należy dopracować na podstawie testów gry. Rodzaje zasobów pozostają otwarte. |
| Inspiracja wypraw | Darkest Dungeon w aspekcie gospodarowania zapasami. Zużycie zasobów będzie dopracowane w testach, a dobre przygotowanie ma dawać rzeczywistą przewagę, bez automatycznego zwiększania trudności niwelującego tę przewagę. |

WFRP stanowi inspirację dla zagrożenia i rozwoju. Nie zatwierdzono przeniesienia pełnego systemu rzutów WFRP, losowego pudłowania, profesji, trwałych ran ani śmierci permanentnej. Losowy krytyk jest odrębną, zatwierdzoną zasadą. Gothic stanowi inspirację dla roli nauczycieli, nie automatyczne przyjęcie wszystkich jego zasad.

Darkest Dungeon stanowi inspirację dla presji zasobów podczas wyprawy. Nie zatwierdzono drużyny, walki turowej, stresu, głodu, systemu światła ani trwałych urazów. Fabularna latarnia pozostaje elementem zadań; nie wynika z tego automatycznie konieczność zużywania paliwa.

## 2. Proponowane przełożenie na rozgrywkę — do omówienia

### Walka

Podstawą starcia może być odczytanie zamiaru przeciwnika, ustawienie się poza jego atakiem, wykorzystanie krótkiej okazji i świadome wycofanie. Trafienia oraz porażki powinny mieć czytelną przyczynę.

Proponuję, żeby przewaga liczebna była groźna przez oskrzydlanie i nakładanie się zagrożeń. Rozdzielenie grupy, wykorzystanie przejścia i rezygnacja ze starcia powinny być sposobami na poprawę sytuacji. Sama liczba przeciwników nie powinna uruchamiać sztucznego mnożnika obrażeń.

Osobny unik w kierunku kursora jest zatwierdzony. Unik i parada mogą przerwać rozpoczęty atak — to zatwierdzona decyzja autora. Ograniczenia użycia i ewentualna nietykalność pozostają do walidacji w pakiecie. Parada pod osobnym klawiszem jest zatwierdzona przeciw uzbrojonym przeciwnikom: przytrzymanie utrzymuje gardę, a dobre wyczucie momentu daje dodatkowy efekt. Rodzaj efektu pozostaje otwarty. Szczegóły i propozycje trafień: [Walka i trafienia](walka-i-trafienia.md).

### Zasoby i końcówka wyprawy

Nie ustalamy z góry momentu wyczerpania zasobów ani docelowego procentu ich zużycia. Tempo i presję dopracujemy w testach działającej gry, z zachowaniem przewagi wynikającej z dobrego przygotowania. Świat nie powinien potajemnie odbierać zapasów ani dokładać przeciwników tylko dlatego, że gracz radzi sobie lepiej niż oczekiwano.

W duchu Darkest Dungeon proponuję budować napięcie wokół oceny: „czy wystarczy mi zapasów na dalszy cel i powrót?”. Dodatkowa odnoga może oferować korzyść kosztem zapasów, a odwrót zachowywać część osiągnięć. Zakres zachowywanych nagród, możliwość uzupełniania zapasów i konsekwencje przerwania zadania wymagają decyzji autora.

Przed balansowaniem należy określić, co się kończy: leczenie, amunicja, przedmioty pomocnicze czy inny zasób. Chwilowa zdolność do wykonania ataku lub uniku to inny problem niż zapasy na całą wyprawę.

Kreatywność wymaga działających alternatyw. Przykłady do rozważenia: obejście przeciwnika, rozdzielenie grupy, wykorzystanie terenu lub rezygnacja z dodatkowego łupu. Nie należy najpierw wymagać zużywalnego zasobu do każdej walki, a potem odbierać go przed obowiązkowym finałem bez innej drogi.

### Rozwój i nauczyciele

Potwierdzony przebieg rozwoju: zdobywanie doświadczenia → awans → otrzymanie PN → wydanie PN u nauczyciela. Otwarte pozostają źródła doświadczenia, tempo awansów, liczba PN, warunki dostępu do szkolenia, ewentualne dodatkowe opłaty i możliwość zmiany wcześniejszych wyborów.

Propozycja: nowe umiejętności powinny rozszerzać dostępne decyzje, a nie wyłącznie zwiększać liczby. Nie przydzielamy jeszcze nauczycieli do obsady; wymaga to zgodności z ich rolami fabularnymi.

### Łupy i nagrody

Proponuję rozróżnić istotną zdobycz zmieniającą wyposażenie od drobnych zapasów. Rzadkość cennej broni nie musi oznaczać, że eksploracja długo nie daje żadnego rezultatu: nagrodą mogą być również informacja, przejście lub dostęp do szkolenia.

To propozycja do omówienia, zwłaszcza w zakresie tego, czy rzadkie mają być wszystkie przedmioty, czy przede wszystkim ulepszenia wyposażenia. Nie wybrano systemu jakości, losowych właściwości ani tabel wypadania łupów.

## 3. Propozycja pętli na różnych skalach

Poniższe czasy są skalami opisu, nie zatwierdzonym czasem trwania walki lub demo.

| Skala | Cel gracza | Przeszkoda | Informacja zwrotna | Nagroda |
|---|---|---|---|---|
| Pojedyncza wymiana, około 30 sekund | Zadać obrażenia i uniknąć odpowiedzi | Zasięg ataku, pozycja, kolejny wróg | Zapowiedź ruchu, trafienie, reakcja przeciwnika | Bezpieczniejsza pozycja i postęp w starciu |
| Fragment wyprawy, około 5 minut | Przejść przez niebezpieczne miejsce | Grupa wrogów, teren, koszt użycia zapasów | Stan zasobów, odkryta droga, rozpoznane zagrożenie | Dostęp do celu, wskazówki lub zdobyczy |
| Sesja | Zrealizować cel i powrócić | Długość trasy, trudne starcia, ograniczone zapasy | Postęp zadania i stan przygotowania do powrotu | Rozliczenie zadania i odczuwalny postęp |
| Dłuższa gra | Rozwinąć bohatera i znaleźć drogę z Niemiru | Groźniejsze obszary i niepełna wiedza | Nowe możliwości, reakcje mieszkańców | Dostęp do dalszych zadań i rozwiązanie lokalnego problemu |

Awans zapewnia PN, a nauczyciele pozwalają je wydać. Pętla nie przesądza jeszcze, które działania nagradzane są doświadczeniem.

## 4. Ryzyka do sprawdzenia w prototypie

- Klikanie przeciwnika i ruch korzystające z tego samego przycisku mogą powodować niezamierzony atak zamiast ucieczki. Sprawdzić rozróżnienie intencji i reakcję na polecenie ruchu.
- Sprawdzić, czy sterowanie myszą pozwala wykonać precyzyjny unik w tłoku i przy przeszkodach.
- Nieograniczone wycofywanie i pojedynczy atak mogą stać się najlepszą odpowiedzią na każde zagrożenie. Testować zachowania przeciwników i teren, zanim doda się kolejne ograniczenia gracza.
- Ograniczenie leczenia połączone z trudną walką może zmienić końcówkę w powtarzanie beznadziejnej próby. Potrzebne są zrozumiałe warunki odwrotu, śmierci i ponownego podejścia.
- Rzadkie łupy mogą opóźnić poczucie postępu. Sprawdzić, czy gracz rozpoznaje wartość nagrody i czy może z niej skorzystać.
- Nauczyciel lub usługa nie mogą stać się przypadkowo niedostępne po naganie, jeśli bez nich nie da się kontynuować głównego zadania.

To analiza projektu, nie wyniki testów gry. Nie uruchomiono prototypu ani symulacji balansu.

## 5. Kolejne decyzje

Źródło PN zostało doprecyzowane przez autora. Następnie omówić wspólnie:

1. Walidacja [pakietu walki 01](propozycja-walki-01.md): koszty przerwania ataku, reguły wiązanek, gardy i strzelania. Możliwość przerwania ataku unikiem lub paradą jest zatwierdzona.
2. Dostępne zasoby, leczenie oraz konsekwencje śmierci i odwrotu.
3. Pierwszy styl walki, zakres umiejętności i funkcję wyposażenia w demie.
4. Minimalny zestaw sytuacji bojowych do sprawdzenia sterowania i zagrożenia liczebnego.

Silnik: Godot 4 ([decyzja warunkowa](SILNIK.md)); przed oceną wykonalności ustalić doświadczenie i zasoby zespołu. Przed implementacją zadań opracować ich stany i wewnętrzną logikę tajemnicy. Nie jest konieczne wcześniejsze rozpisanie całej Weleszy.
