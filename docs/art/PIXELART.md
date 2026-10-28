# Próba pixel artu: bohater i pies

Branch `feat/pixelart-combat-generator` realizuje prośbę autora o eksperyment z modern
pixel artem na podstawie przesłanego obrazu: naturalne proporcje, ciemny bór,
oliwkowa zieleń, chłodne cienie i ciepłe brązy. To próba do oceny w ruchu;
nie zastępuje zatwierdzonego PDF ani całej dokumentacji kierunku artystycznego.

## Uruchomienie

Python 3.12, Pillow, NumPy, jsonschema; Godot **4.7.2-stable**.

```bash
python -m pip install -r tools/requirements.txt
python tools/pixelart_generator.py
godot --headless --path game --editor --import --quit
godot --path game
```

Domyślna scena tego brancha: `game/world/pixelart/pixelart.tscn`. Stare sceny pozostają
dostępne. LPM na ziemię: ruch; LPM w psa: podejście i jeden cios; kolejne kliknięcia
w rytm: wiązanka. Ctrl+LPM: cios w miejscu. Spacja: unik w stronę kursora. Q: garda,
Shift: sprint, 1/2: leczenie, R: nowe starcie. Pies obiega, ostrzega i skacze;
obrażenia wynikają z istniejącej logiki kontaktu oraz zdarzeń animacji.

```bash
# Pokaz automatyczny; kod wyjścia 0 wymaga trafień obu stron.
godot --headless --path game -- --demo
# Zrzut prawdziwego renderu; wymaga działającego wyświetlacza.
godot --path game -- --capture=/tmp/pixelart.png
python -m unittest discover -s tools/tests
```

W środowisku chmurowym używaj binarki
`/workspace/.tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64`;
systemowe `godot` ma starszą wersję. Cache i dane Godota ustaw w zapisywalnych katalogach
przez `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `XDG_DATA_HOME`.

## Jeden automatyczny przebieg

```bash
python tools/check_pixelart.py --build --godot godot
```

Buduje wszystkie warianty, nakłada zapisane korekty, sprawdza paletę, siatkę,
alfę, niepuste klatki, zgodność zdarzeń i czasów animacji oraz aktualność hashy.
Następnie wykonuje testy Python, importuje projekt, wykonuje testy gry i rzeczywiste starcie obu stron.
Dowolny błąd przerywa proces z niezerowym kodem wyjścia. W CI te same kroki są
wpięte po budowie zwykłych assetów i przed importem do Godota.

Chód jest stabilizowany poziomo względem górnej części sylwetki (bez deformacji
kończyn, limit korekty 18 natywnych pikseli). Korekty są jawnie zapisane w manifeście;
przekroczenie limitu albo obcięcie sylwetki zatrzymuje budowę. Ciosy i skoki nie
są stabilizowane, bo zawierają celowe wychylenia. W runtime cykl kroku przyspiesza
z ruchem i sprintem oraz zachowuje fazę podczas skrętu; dotyczy to tylko postaci
z ustawioną długością cyklu (`walk_cycle_distance`), nie zmienia wcześniejszych scen.
To redukcja mierzalnego dryfu, nie gwarancja doskonałej anatomii ani kontaktu każdej stopy.

`game/assets/pixelart/quality.json` zawiera listę odłączonych fragmentów sylwetki
(np. obcego kawałka miecza), dotknięć krawędzi płótna oraz klatek chodu z nagłym skokiem
górnej części sylwetki o więcej niż 4 natywne piksele. Są to ostrzeżenia do
selektywnej oceny, nie diagnoza anatomii ani automatyczna naprawa. Twarde reguły
techniczne blokują build; heurystyka ruchu go nie blokuje. Dzięki temu oglądamy
głównie wskazane klatki, zamiast analizować całe paski od początku.
`quality_review.png` składa je automatycznie w jeden arkusz.
`walk.gif` i `combat.gif` pokazują jednocześnie osiem kierunków obu postaci.

Pierwsza zapisana korekta usuwa dodatkowe ostrze za plecami bohatera w
`attack_w`, klatka 2 i uzupełnia uciętą końcówkę miecza w klatce 3 (numeracja od zera).
Maska i warstwa poprawek są źródłami w Git i wracają automatycznie przy każdej budowie.

## Co kontroluje generator

`tools/pixelart_profile.json`: wspólna paleta 41 kolorów, piksel 2 jednostki gry,
próg odcięcia alfa, kontrast i ziarno terenu. Brak losowania palety osobno dla
klatek, ditheringu, zewnętrznych API i pamięci modelu. Ziarno dotyczy wyłącznie
proceduralnego terenu. Kamera i filtrowanie nearest zachowują ostre krawędzie;
skalowanie okna jest całkowite, z pasami przy niepasujących proporcjach.

Generator korzysta z obecnego pipeline'u do wyrównania kotwic i odbić psa,
po czym konwertuje atlasy na stałej siatce. Zachowuje nazwy animacji, liczbę klatek,
FPS, zdarzenia walki, punkty kotwicy i kolizje. Bohater zachowuje osiem osobnych
kierunków; pies pięć i trzy odbicia. Wyniki mają ID zakończone `-pixel`,
nie nadpisują painted artów ani ich wersji w runtime. Teren powstaje z rysowanych
kodem klastrów pikseli i kałuż; rekwizyty pochodzą z obecnych malowanych źródeł.

`game/assets/pixelart/sprites.png`: arkusz do oceny.
`game/assets/pixelart/manifest.json`: pełny profil, hashe źródeł, generatora,
poprawek i wyników. Wyniki są ignorowane przez Git, odtwarzaj je poleceniem powyżej.
Dla identycznych plików używaj tych samych wersji Pillow i NumPy.

## Ręczna kontrola pikseli

Otwórz np. `game/assets/HERO-bohater-pixel/attack.png`, zmniejsz dokładnie 2×
filtrem nearest do natywnej siatki. W osobnej przezroczystej warstwie namaluj
poprawki wyłącznie kolorami palety i zapisz ją jako
`art-src/_pixel_overrides/HERO-bohater/attack.png`. Zachowaj pełny rozmiar atlasu
w natywnej siatce (każda klatka 128×128), nie przycinaj go do zawartości.
Przezroczystość oznacza brak zmiany, pełna alfa zastępuje piksel. Żeby usunąć
piksel, dodaj jednokanałowy obraz `attack.erase.png` o takim samym wymiarze:
biały usuwa, czarny pozostawia. Usuwanie ma pierwszeństwo przed malowaniem.
Ponownie uruchom generator: poprawki przetrwają i zostaną wpisane do manifestu.
Niewłaściwe kolory, półprzezroczystość i rozmiary są odrzucane.

## Granice pierwszej wersji

To deterministyczny konwerter i generator terenu, nie generator dowolnej nowej
postaci z tekstu. Nie naprawia anatomii ani niespójnych póz w źródłowych obrazach.
Obecny walidator nadal zgłasza drganie głowy w chodzie bohatera i psa; wspólna
siatka i paleta usuwają dryf koloru, nie gwarantują stabilnej anatomii. Następna
iteracja powinna poprawiać klatki na małej siatce (lub używać jawnego szkieletu
i części postaci), zamiast ponownie generować całe paski modelem obrazowym.
Nie odtworzono zabudowy z referencji; celem tej próby jest czytelne starcie na trakcie.
