# Welesza — warianty przestrzeni nieoczywistej (v0.2)

**Status: propozycje do porównania / decyzja autora OTWARTA.** Ten plik nie ustala mechanizmu tajemnicy Weleszy. Zatwierdzona fabuła jest w [`docs/demo-fabula.md`](../demo-fabula.md): bohater wraca dawną drogą, znajduje wóz tam, gdzie nie powinien; ślad na drzewie i powrót z innego kierunku wzmacniają niepokój. Latarnia zapalona w Niemirze pozwala zobaczyć nową ścieżkę między słupami.

## I. Droga, która wraca — dwie wersje do prób

| Wymaganie | A — fizyczne okrążenie (wariant z mapy v0.1) | B — autentyczna anomalia połączeń |
|---|---|---|
| Co widzi gracz | Idzie między drzewami, traci linię wzroku na wóz, po kilku zakrętach wraca z innej strony do tego **samego** wozu i rozpoznawalnego drzewa. | Rozpoznaje kierunek, z którego przyszedł, i rusza pozornie wstecz; bez cięcia obrazu znana trasa prowadzi od strony przestrzennie niemożliwej z powrotem do wozu. Landmarki wskazują sprzeczne kierunki. |
| Co rozumie | Może pomyśleć „zgubiłem się / okrążyłem polanę”. Element nadprzyrodzony **nie jest zagwarantowany**. | Może sam sprawdzić, że kolejność lub kierunek połączeń nie odpowiada jego wcześniejszej trasie; odczuwa anomalię przestrzeni. Nadal nie znamy jej przyczyny. |
| Proponowany test | Ten sam fragment greyboxu z zakrętami i naturalnymi zasłonami. 5–8 graczy bez podpowiedzi: „Co się stało?”. Rejestrujemy spontaniczne „zatoczyłem koło” versus „droga niemożliwie zawraca”. Liczba osób to pomysł organizacyjny, nie próg zaliczenia. | Dwie topologie tej samej makiety (stan zwykły, anomalny), ciągły ruch kamery. Uczestnik opisuje, skąd wyszedł; oceniamy, czy zauważył sprzeczność bez sztucznego błysku/ściemnienia/komunikatu. Kontrolujemy, czy nie odebrał tego jako błąd gry. |
| Wóz i znak | Jedna trwała instancja/identyfikator każdego obiektu; nie dublować pakunków i śladów po okrążeniu. | Także jeden logiczny wóz/znak; ewentualna iluzja reprezentacji nie może generować duplikatów interakcji. Widok wozu może pojawić się po zmianie połączenia, ale nie w aktywnym kadrze jako nagły pop-in. |
| Przedmioty | Zebrany pakunek i księga zostają zebrane po powrocie. | Stan globalny jak w A; zmiana topologii nie cofa czasu ani łupu. |
| Przeciwnicy | AI porusza się fizycznie po pętli; brak resetów spowodowanych przekroczeniem umownej linii. | Stan i pozycja przeciwnika nie zmieniają się magicznie podczas walki; potrzebne jasne reguły przestrzenne, gdy AI próbuje przekroczyć granicę anomalii. Nie duplikować AI. |
| Walka / odwrót | Bezpieczne przejścia w obie strony; pętla nie może zamknąć drogi do Niemiru. | **Nie przełączać topologii podczas aktywnego ataku, pościgu, pocisku ani uniku**, dopóki prototyp nie dowiedzie poprawnego odwrotu. Bezpieczna droga do osady zawsze pozostaje stabilna. |
| Ryzyka | Efekt banalnego labiryntu; oszustwo odczuwane jako prowadzenie za rękę; koszt niskiego zaskoczenia. | Szwy nawigacji, kamery i fizyki; nieciągłość linii widzenia i audio; gracz uzna przejście za teleport/bug; większy koszt testów. |
| Wizualizacja w `WORLD_MAP` | Narysowana jest wyłącznie fizyczna polilinia A, żeby zachować istniejącą topologię. | Na płaskiej mapie **nie da się wiernie narysować** nieeuklidesowego połączenia; należy wprowadzić warunkową relację / diagram dwóch stanów, nie udawać zwykłej dodatkowej ścieżki. |

**Rekomendacja projektowa (nie decyzja):** testować A jako tani baseline i B jako docelową próbę osiągnięcia zaskoczenia. Najpierw prosta demonstracja z placeholderami i jednym wozem, nie gotowy shader/portal. Przy obu wariantach osobno testować powrót bez walki, w trakcie pościgu, ze zgubionym/zebranym przedmiotem oraz odwrót do bramy.

**Decyzja autora:** A, B, hybryda, lub nowe rozwiązanie. Potrzebne również zatwierdzenie, *kiedy* anomalia jest aktywna (prolog/rano/później); mapa tego nie rozstrzyga.

## II. Odsłonięta droga latarnią — warianty

Wszystkie wersje zachowują ten sam stan zadania: `village_lamp_lit` przywraca **możliwość przejścia** na dawny trakt. Nie wprowadzamy drugiego wyjścia z doliny i nie zmieniamy miejsca Stróża.

| Wersja | Przed zapaleniem | Po zapaleniu | Jak uniknąć sztucznej blokady | Trudność/ryzyko |
|---|---|---|---|---|
| L1 — droga ukryta percepcyjnie | Gęsty las i słupy, brak czytelnego przejścia. Ścieżkę można minąć, nie rozpoznając jej; mechaniczna granica wymaga uczciwego wyjaśnienia, jeżeli gracz próbuje ją sforsować. | Subtelny zarys traktu w świetle; gracz rozumie, którędy iść. | Zasłona terenowa/krzywizna, nie niewidzialna ściana w pustej przestrzeni; światło odkrywa czytelny kierunek. | Ryzyko: gracz przypadkowo przejdzie wcześniej albo uderzy w niewidoczną barierę. Wymaga testu nieoczekiwanych podejść. |
| L2 — rzeczywista nadprzyrodzona przeszkoda | Rozpoznawalne, fizycznie nieprzebyte korzenie / ściana lasu / ciemność (wygląd do ustalenia), których obecność ma przyczynę w świecie. | Element ustępuje lub zmienia formę **w obserwowalny, ciągły sposób**; teren pozostaje pod tym samym miejscem. | Przeszkoda ma sylwetkę i kolizję zgodne z obrazem; przed/po nie podmieniamy całej mapy. | Wprowadza nowy fakt o działaniu magii i efekt, który trudno wykonać subtelnie. |
| L3 — ujawnienie orientacji przestrzeni | Droga pozornie prowadzi do znanego słupa lub zamkniętej ścieżki; połączenie wydaje się inne, lecz nie ma „magicznego muru”. | Światło pozwala ustawić znaki/linię widzenia w nowej relacji; trakt okazuje się dostępny po innym skręcie. | Ten sam teren, widoczne landmarki, brak natychmiastowego przestawiania pod stopami; część zmian przeprowadzana poza bezpośrednim wzrokiem. | Może mieszać motyw z pętlą i sugerować zbyt wiele o kosmologii; wymaga kontroli czytelności. |

**Rekomendacja projektowa (nie decyzja):** zacząć od prototypu L1 i L2, ocenić przypadki wejścia „na siłę”, ryzyko niewidzialnej ściany oraz odczyt zmiany. L3 zostawić jako alternatywę. **Brak zatwierdzenia** fizycznych korzeni, mgły czy skarpy jako jedynej interpretacji.

## III. Kontrakt eksperymentu

1. Nie stosować fade-to-black, loading screena ani wyrywania sterowania do zakrycia zmiany podczas zwykłego chodu.
2. Nie rozdzielać jednego przedmiotu, wozu lub wroga na dwa odrębne zapisy świata.
3. Przejście/odwrót pozostają możliwe także przed ukończeniem opcjonalnych zadań.
4. Graf flag potwierdza **dostępność**, a nie sposób wizualnego uzasadnienia bramki.
5. Ostateczny wariant, jego dokładny moment fabularny i zachowanie podczas aktywnej walki zatwierdza autor po demonstracji.
