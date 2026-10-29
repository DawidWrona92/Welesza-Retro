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
`/workspace/welesza-env/bin/godot`;
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

Chód korzysta z jednej pozy odniesienia na kierunek: idle bohatera albo pierwszej
klatki walk psa. Maski w `art-src/_pixel_rigs/walk.json` wycinają teksturowane
fragmenty nóg. Generator odkształca je na siatce nearest, mocując górny szew;
dolna ćwiartka buta/łapy przesuwa się sztywno. Nie rysuje zastępczych nóg ani
nie usuwa fragmentów sylwetki metodą „zostaw największy komponent”. Maska `protect`
chroni miecz w widoku E. Rozdzielenie masek przednich nóg zapobiega poruszaniu
obiema naraz, gdy łączy je piksel przy biodrach. Pozostała część sylwetki jest stała.

Amplituda jest ograniczona długością wycinka; zawinięcie siatki lub zbyt duże
rozciąganie przerywa build. Rig jest przeznaczony dla siatki 128×128 (`pixel_size=2`);
inna siatka wymaga opracowania osobnych masek. Nie skaluje się ich po cichu.
Liczba klatek, FPS i zdarzenia pozostają dokładnie zgodne z `asset.json`:
bohater 8 klatek chodu, pies 6, kroki odpowiednio na 1/5 i 1/4.
Kierunki odbijane psa są kopiowane z gotowej animacji, klatka po klatce.

`quality.json` wskazuje odłączone fragmenty, krawędzie płótna i skoki górnej
części sylwetki, również na szwie ostatnia–pierwsza klatka. `quality_review.png`
pokazuje wskazane klatki; `walk.gif` i `combat.gif` osiem kierunków obu postaci.
Problemy wykryte w chodzie przerywają build po zapisaniu raportu i arkusza.
Raport techniczny nie ocenia anatomii ani naturalności ruchu. GIF pokazuje bazowe
12 FPS; runtime dopasowuje tempo do prędkości i zachowuje fazę podczas skrętu.
Krótki krok tej wersji przy dużej prędkości daje wysoką kadencję — oceniaj także sprint.

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

## Kierunek dalszych zmian i bramka odbioru

Utrzymujemy obecną paletę, proporcje i odrębne warianty `-pixel`. Zmiany anatomii
wymagają jawnych masek lub korekt źródłowych, z porównaniem przed/po we wszystkich
kierunkach. Nie zastępuj całych kończyn figurami geometrycznymi. Nie zwiększaj
liczby klatek ani nie przesuwaj zdarzeń walki w ramach poprawki grafiki.

Przed przyjęciem zmiany:

1. Uruchom pełne `check_pixelart.py --build --godot godot`; sprawdź liczbę wykonanych
   testów i `PIXEL_DEMO` z trafieniami bohatera oraz psa.
2. Sprawdź manifest i powtarzalność hashy po ponownej budowie z przypiętymi bibliotekami.
3. Obejrzyj wskazane klatki i pełne pętle: osiem kierunków, przejścia idle/walk/attack,
   kontakt stóp, niezmienność twarzy i ekwipunku, ostatnia–pierwsza klatka, skręt i sprint.
4. Zaakceptuj wygląd na podstawie ruchu w grze. Zielone testy nie są akceptacją artystyczną.

To konwerter z ograniczoną animacją wycinkową, nie rekonstrukcja szkieletu 3D.
Niewidoczne nogi nie są domyślane. Przy części widoków fragmenty nóg pozostają
zasłonięte płaszczem lub korpusem; nie uznajemy tego za pełny anatomiczny rig.
Korpus i ramiona nie mają jeszcze przeciwskrętu. Naturalny dłuższy krok oraz
pełny chód czworonożny wymagają osobno opracowanych części i póz kontaktowych.
Pozostałe animacje zachowują źródłowe pozy i istniejące korekty; konwersja nie
stanowi dowodu naprawienia wszystkich błędów rysunków GPT.

## Kontrola bryły i wnioski z przewodnika autora

Materiał: „Rysowany pixel art dla agentów LLM: uniwersalny przewodnik”, PDF
przekazany przez autora 29.10.2026, zwłaszcza sekcje 2, 5 i 6. Stosujemy z niego
kontrolę sylwetki, zachowania materiału, rozdzielenia części oraz filmstripów.
Konwersja painted artów jest bazą roboczą; poprawna paleta i siatka nie dowodzą
jakości rysowanego pixel artu. Progi dla 16–32 px z PDF nie są automatycznie
przenoszone na nasze płótna 128×128.

Walidacja chodu porównuje każdą klatkę ze źródłową pozą, sprzed deformacji:

- `fixed_region_changed`: choćby jeden zmieniony piksel RGBA w nieruchomym
  korpusie lub chronionej części. W masce miecza kontrolujemy również otoczenie
  przezroczyste, aby wykryć dodany zygzak przy nadal połączonym ostrzu.
- `interior_material_lost`: nowa zamknięta luka w miejscu, gdzie źródło zawierało
  materiał. Kontrola dotyczy pełnej maski alfa, również pojedynczego piksela we
  wnętrzu. Istniejąca przestrzeń między ręką a ciałem sama w sobie nie jest błędem.
- `quality.json` zapisuje powierzchnię sylwetki i liczbę pikseli wnętrz wszystkich
  klatek. Powierzchnia jest wskaźnikiem 2D, nie pomiarem objętości anatomicznej.

`pixelart/audit/<ID>/reference.png` i `fixed.png` są hashowane w manifeście.
Błąd jednakowy we wszystkich wygenerowanych klatkach nie staje się wzorcem tylko
przez porównanie do klatki 0. Maski rigu nadal wymagają oceny: błędnie opisanej
anatomii w samym źródle ta kontrola nie naprawia.

`pixelart/review/<ID>/<animacja>/<kierunek>.png` zawiera wszystkie klatki w trzech
pasach: obraz, pełną białą sylwetkę oraz różnicę z poprzednią klatką. Szary to
wspólny materiał, czerwony ubytek, zielony przyrost. W chodzie klatka 0 pokazuje
szew pętli; w niepętlących akcjach zestawienie końca z początkiem jest wyłącznie
porównaniem póz, nie wymaganiem zapętlenia. Oceniaj również atak, skok i reakcję
na trafienie — odtwarzacz GIF nie zastępuje arkuszy.

Przed uznaniem ruchu za ukończony trzeba jeszcze ocenić łańcuchy biodro–kolano–
kostka–stopa i bark–łokieć–dłoń–broń, ich proporcje oraz okluzję. Sam brak dziur,
stała powierzchnia i połączona sylwetka nie wykluczają stopy wyrastającej z kolana.
W szczególności porównanie nieruchomych części dotyczy chodu, a nie swobodnego
ruchu miecza podczas ataku; dla ataku potrzebne są jawnie ocenione pozy i punkty
anatomiczne. Nie raportuj automatycznej akceptacji anatomii.

Autor dopuścił propozycje zmiany palety lub timingów do wspólnej, pogłębionej
analizy. Przed taką zmianą przedstaw konkretny problem, porównanie wariantów oraz
wpływ na czytelność, zdarzenia i balans walki. Nie traktuj ogólnych zaleceń PDF
(np. minimalnego windupu gracza) jako decyzji o zmianie obecnego kontraktu.

## Nagranie z rzeczywistej sceny Godota

`game/world/pixelart/recording.tscn` jest osobnym pokazem: osiem kierunków ruchu
bohatera, następnie istniejący scenariusz walki z AI psa. Chód korzysta z `move_to`,
nawigacji i fizyki gry. Podczas prezentacji chodu pies jest ukryty i ma wstrzymane
AI; podczas walki działa normalnie. Kamera ma całkowite powiększenie 2×, aby
pokazać kończyny i broń. Nie zmieniamy prędkości gry, klatek ani zdarzeń animacji.

Godot 4.7.2 wymaga działającego ekranu X11/Wayland; `--headless` nadaje się do
sprawdzenia scenariusza, ale nie renderuje filmu. W chmurze można użyć Xvfb
z ekranem 1920×1080×24 i renderera Mesa llvmpipe. Ustaw `DISPLAY` na własny
wirtualny ekran (w bieżącym środowisku `:99`). Nie zakładaj, że proces Xvfb
przetrwa odtworzenie środowiska.

Z katalogu repozytorium, po budowie/importowaniu assetów:

```bash
mkdir -p /tmp/welesza-film
godot --path game res://world/pixelart/recording.tscn \
  --audio-driver Dummy --write-movie /tmp/welesza-film/recording.avi \
  --fixed-fps 60 --disable-vsync
ffmpeg -i /tmp/welesza-film/recording.avi -an -c:v libx264 -threads 4 \
  -preset medium -crf 18 -pix_fmt yuv420p -movflags +faststart \
  /tmp/welesza-film/chod-i-walka.mp4
```

Nagranie kończy się samo. Kod 0 wymaga osiągnięcia celów ruchu, pokazania ośmiu
kierunków i trafień obu stron; w logu muszą wystąpić `PIXEL_WALK directions=8`
i `PIXEL_DEMO` z dodatnimi licznikami. Nie dodawaj `--demo`: nagranie samo
uruchamia walkę po części poświęconej chodowi. Wyjście MP4 jest bez dźwięku.
Sprawdź również log pod kątem `ERROR`/`SCRIPT ERROR`, liczbę klatek przez ffprobe
oraz obrazy z części ruchowej i walki. Zapis klatka po klatce zachowuje tempo 1×
w filmie nawet wtedy, gdy renderowanie na CPU trwa dłużej.

Film służy ocenie obecnego stanu, nie stanowi potwierdzenia ukończenia animacji.
Krótki krok i wynikająca z niego wysoka kadencja pozostają widoczne. Do oceny
anatomii używaj równolegle arkuszy sylwetek i różnic z sekcji wyżej.
