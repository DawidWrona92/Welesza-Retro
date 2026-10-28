# Przegląd projektowy pakietów 02–03

Status: analiza scenariuszy według playtest-simulator i encounter-director. Nie są to testy działającej gry, obserwacje graczy ani pomiary czasu walki.

Zakres: [wyprawa](propozycja-wyprawy-02.md), [bestiariusz](bestiariusz-demo.md), [spotkania](spotkania-i-bossowie.md). Punktem startu jest bohater z podstawową bronią, umiejętnością uniku i gardą w wariancie z pakietu 01. Nie zakładamy zakupionej aktywnej umiejętności ani szczęśliwych krytyków.

## Początkujący — pierwsza porażka przy wozie

1. Wchodzi w zasięg Psa, ignorując większość opisów. Widzi przysiad i słyszy warkot.
2. Klika kolejne ataki zamiast uniku. Spodziewamy się trafienia i utraty zdrowia, ale nie deklarujemy liczby trafień potrzebnych do śmierci.
3. Próbuje się bandażować przy Psu. Atak przerywa czynność, bez darmowego częściowego leczenia. Wymagany jest czytelny sygnał przerwania, a nie samo zniknięcie animacji.
4. Po śmierci wczytuje bezpieczny zapis: zachowuje przygotowanie sprzed próby, nie zachowuje łupu zdobytego po zapisie.
5. Może wrócić do osady, odpocząć i zaopatrzyć się, nawet jeśli nie ma pieniędzy.

**Odchylenia:** przytrzymuje zamiast klikać; podnosi pakunek przed zabiciem drugiego wroga. Reguły odpowiednio nie uruchamiają autoataku i nie wymagają konkretnej kolejności podnoszenia przedmiotów.

**Ustalenie PLT-R02 / Major:** bez sygnału przerwania leczenia gracz może nie zrozumieć porażki. Dodać wizualne i dźwiękowe potwierdzenie przerwania. Czytelność pozostaje do próby w silniku.

## Gracz szukający skrótów — latarnia i finał w złej kolejności

1. Pomija opcjonalnego Zbieracza i Żałobnicę. Żaden z nich nie daje przedmiotu wymaganego do głównej drogi.
2. Dociera do Dźwigacza przed formalnym przyjęciem zadania. Może go pokonać i odnaleźć latarnię; stan zostaje zapamiętany.
3. Wraca do NPC później. Rozmowa rozpoznaje przedmiot zamiast ponownie zamykać komorę.
4. Próbuje ominąć Stróża. Przejście ma widoczny stan zamknięcia związany ze zwycięstwem, nie z obecnością ciała w konkretnym miejscu.
5. Po wygranej chce od razu odejść. Dziennik kieruje go do zawiadomienia osady, a widoczny odcinek wyjścia potwierdza sukces; nie dopisujemy nowego dużego obszaru do demo.

**Odchylenia:** dotarcie do słupów przed rozmową z tropicielką; powrót do komory po zdobyciu latarni. Ślady są rejestrowane, a przedmiot nie powstaje drugi raz.

**Ustalenie PLT-R03 / Major:** bez obsługi kolejności zadania mogłyby wymagać zmartwychwstania bossa. W projekcie zapisano trwałe flagi oraz rozpoznawanie wcześniejszych osiągnięć. Implementacja flag pozostaje do testów.

## Gracz próbujący zepsuć grę — geometria i reset

1. Ustawia się przy filarze, na którym boss mógłby utknąć. Projekt Dźwigacza wymaga dwóch przejść mieszczących jego obrys; bez mapy nie da się potwierdzić spełnienia warunku.
2. Atakuje zza granicy pościgu. Reset wyłącza jednocześnie obrażenia zadawane i otrzymywane przez wracającego bossa; nie może powstać jednostronnie bezpieczny ostrzał.
3. Ucieka w trakcie przejścia fazy. Stan resetu usuwa oczekujące ataki i odnawia fazę początkową; nie pozostawia bossa w wiecznej niewrażliwości.
4. Próbuje sprzedać latarnię. Przedmiot fabularny nie ma takiej operacji i nie zajmuje zwykłego limitu łupu.
5. Wyłącza grę przy zwycięstwie. Nagroda, pokonanie bossa i flaga zadania wymagają atomowego zapisu.

**Odchylenia:** śmierć gracza jednocześnie ze śmiercią bossa; zapis w przejściu fazy. Proponowana reguła pierwszego przypadku: przywrócenie zapisu sprzed próby, bez zachowania nagrody; zwycięstwo wymaga żywego gracza po rozliczeniu bieżącego kroku walki. Drugi przypadek odtwarza dokładny stan przejścia wraz z ograniczeniem czasu, nie rozpoczyna go bez końca od nowa.

**Ustalenie PLT-R04 / Blocker przed wdrożeniem:** trzeba jawnie ustalić kolejność jednoczesnych śmierci. Powyższa reguła została dopisana do projektu spotkań jako propozycja do walidacji.

**Ustalenie ENC-R04 / Major, otwarte technicznie:** kolizji i miejsc umożliwiających bezkarny atak nie potwierdzi sam tekst. Wymagane testy na geometrii.

## Optymalizujący — zasoby i nagrody

1. Pobiera pakiet awaryjny, próbuje schować go w magazynie i pobrać kolejny. Projekt sprawdza cały posiadany zapas, nie sam pasek podręczny.
2. Próbuje sprzedać pakiet. Zestaw nie ma wartości sprzedaży ani przepisu przetwarzania.
3. Pokonuje wroga, odpoczywa i wraca po ponowną nagrodę. Przeciwnicy i znaleziska nie odnawiają się od odpoczynku.
4. Przegrywa walkę po zużyciu nalewek, wczytuje zapis. Odzyskuje środki, ale również traci wszystkie zyski z nieudanej próby.
5. Próbuje zabijać Stróża samymi strzałami z wejścia. Dostępność podejścia bossa, czytelny pochód i reset poza obszarem ograniczają taki scenariusz na poziomie zasad; jego skuteczności nie znamy bez gry.

**Odchylenia:** wyjście w trakcie efektu nalewki; jednoczesne podniesienie łupu i zapis. Stan efektu jest częścią zapisu, a przyznanie przedmiotu wymaga jednorazowej operacji.

**Ustalenie ECO-R03 / Blocker przed wdrożeniem:** pomoc awaryjna bez sprawdzenia magazynu mogłaby tworzyć nieskończony zapas. Reguła została uwzględniona; nie ma jeszcze implementacji do testowania.

Nie obliczano ekonomii ani TTK. Brak cen, statystyk i docelowych czasów nie pozwala raportować wyników symulacji. Nie twierdzimy, że zniknęła dominująca strategia strzelania i cofania się.

## Gracz bez dźwięku — rozpoznanie zagrożenia

1. Pies przysiada przed skokiem, więc dźwięk nie jest jedyną zapowiedzią.
2. Drwal unosi topór i zatrzymuje go przed ciężkim ciosem. Zwykłe cięcie ma inny ruch barków.
3. Osłona Żałobnicy ma widoczne połączenie, nie tylko pieśń. Nie wymaga rozróżnienia dwóch podobnych kolorów.
4. Stróż pokazuje pełną zmianę postawy przed pochodem; informacja o fazie nie zależy od zrozumienia głosów.
5. Po zwycięstwie zmienia się stan przejścia i dziennik. Brak fanfary nie ukrywa zakończenia zadania.

**Odchylenia:** zasłonięcie bossa koroną drzewa; przeciwnik tuż poza ekranem. Projekt wymaga odsłaniania sylwetki i wstrzymania nieczytelnych ataków spoza widocznego obszaru. Sprawdzić w kamerze, nie uznać za rozwiązane przez samą deklarację.

**Ustalenie PLT-R10 / Major, otwarte technicznie:** czytelność animacji, wskaźników i czasu reakcji wymaga testu bez dźwięku. Nie deklarujemy dostępności całego systemu rytmu bez osobnej próby wejścia.

## Wynik przeglądu

| Persona | Wynik analizy dokumentu | Najważniejsza rzecz do sprawdzenia w grze |
|---|---|---|
| Początkujący | Opisana droga do ponownej próby bez trwałej utraty zapasów | Czy rozumie sygnały ataku i przerwanie leczenia |
| Szukający skrótów | Projekt uwzględnia pomijanie treści pobocznej i inną kolejność | Faktyczne flagi zadań i blokada wyjścia |
| Psujący grę | Określono reset, jednoczesną śmierć i trwałość nagród | Geometria, przejścia faz i atomowy zapis |
| Optymalizujący | Opisano zabezpieczenia pakietu ratunkowego i nagród | Kiting, leczenie, farmienie i rzeczywista ekonomia |
| Bez dźwięku | Ataki mają także sygnały wizualne | Kamera, animacje i tolerancja czasu reakcji |

Czasów przejścia i liczby udanych prób nie zmierzono. Żaden wiersz nie oznacza zaliczonego testu gry.

## Wykonana walidacja strukturalna

Uruchomiono skrypt z pakietu skilli:

```bash
python3 .agents/skills/level-designer/scripts/validate_graph.py docs/graphs/boss-zbieracz.json
python3 .agents/skills/level-designer/scripts/validate_graph.py docs/graphs/boss-dzwigacz.json
python3 .agents/skills/level-designer/scripts/validate_graph.py docs/graphs/boss-stroz.json
```

Każde polecenie zwróciło `OK: graph is valid` i kod zakończenia 0. Wszystkie zadeklarowane stany mają strukturalną drogę od startu i do rozliczonego zwycięstwa. Skrypt nie wykonuje warunków zapisanych w polu `condition`, nie sprawdza kolizji, zasobów, progów zdrowia ani atomowości zapisu. Wynik nie dowodzi, że AI nie utknie podczas gry.

## Do walidacji przez autora

Łącznie: model porażki i zapisów z pakietu 02, dobór przeciwników, dwa proponowane dodatkowe boss fighty oraz fazy Stróża. To pakiet propozycji; zatwierdzona fabuła nie została automatycznie przepisana ani rozszerzona o nowe fakty świata.
