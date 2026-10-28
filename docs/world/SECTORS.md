# Welesza — karty 12 sektorów / ownership v0.2

> **Zaakceptowana podstawa do greyboxu** (decyzja autora, 27.10.2026). Siatka 24×18 jednostek projektu, sektory po 6×6. To nie metry i nie wymuszony podział silnika na sceny.

## Konwencja i zasady odpowiedzialności

- Punkt ma dokładnie jednego właściciela `owner_sector`, liczonego z jego `grid` w półotwartym prostokącie sektora (`x0 ≤ x < x0+w`, analogicznie `y`; tylko zewnętrzny maksimum wchodzi do skrajnego sektora).
- Droga `sectors_crossed` może należeć przestrzennie do więcej niż jednego sektora. `owner_sector` drogi to sektor jej `from_node` — **koordynuje pracę**, a pozostałe sektory przygotowują swój odcinek/kolizję.
- Droga nie tworzy nowego miejsca: właścicielowi słupa przypisujemy jego **kotwicę**, właściciel drogi nie zmienia tego przypisania.
- S00, S03, S20 i S23 są sektorami tła/granic bez węzłów i bez polilinii w v0.2; S23 **nie** obejmuje `dry_road`.
- Deklaracje sektorów są roboczą organizacją produkcji, a nie nakazem streamingu ani ekranów przejścia.

## Indeks sektorów

| Sektor | Główne miejsce / funkcja | Punkty z kotwicą | Liczba tras przechodzących |
|---|---|---:|---:|
| `S00` | Zachodnia granica boru | 0 | 0 |
| `S01` | Niemir i skalne źródło | 8 | 10 |
| `S02` | Północne ścieżki | 1 | 2 |
| `S03` | Wschodni las i podejście | 0 | 0 |
| `S10` | Zerwany most i wóz | 3 | 4 |
| `S11` | Rozstaj oraz cmentarne miejsce | 3 | 8 |
| `S12` | Kamienie i obóz | 6 | 13 |
| `S13` | Ruiny oraz finał | 4 | 4 |
| `S20` | Nieprzebyta skarpa i podmokłości | 0 | 0 |
| `S21` | Polana z pieśnią | 1 | 1 |
| `S22` | Sidła i jama Zbieracza | 2 | 2 |
| `S23` | Południowo-wschodnia granica doliny (tło suchego szlaku) | 0 | 0 |

## Karty robocze

### S00 — Zachodnia granica boru

**Funkcja:** Niegrywalne tło i ograniczenie zachodnie.

**Geometria/inscenizacja:** Gęsty bór, mokre skały; brak sugerowanych ścieżek wyjściowych.

**Greybox/QA:** Nie tworzyć niewidzialnej bariery na czytelnej drodze.

**Punkty kotwiczone:** brak.

**Odpowiedzialność za trasy od punktów początkowych:** brak.

**Trasy z innych sektorów przecinające ten sektor:** brak.

### S01 — Niemir i skalne źródło

**Funkcja:** Niemir: źródło, palisada, domy, gospoda, strażnica, kuźnia i dziedziniec.

**Geometria/inscenizacja:** Jedna nieregularna polana, kamienna skała na skraju, niewielki plac. Drzwi usług i jedyna brama czytelne z głównego traktu. Bez walki w osadzie.

**Greybox/QA:** Test: od bramy do gospody i Wszebory bez zasłonięć; dachy reagują na kamerę; nie dodawać pól.

**Punkty kotwiczone:** `spring`, `watch_village`, `houses`, `inn`, `square`, `services`, `training`, `gate`.

**Odpowiedzialność za trasy od punktów początkowych:** `square__spring`, `square__watch_village`, `square__houses`, `square__inn`, `square__services`, `services__training`, `square__gate`, `gate__training`, `gate__crossroads`.

**Trasy z innych sektorów przecinające ten sektor:** `camp__crossroads`.

### S02 — Północne ścieżki

**Funkcja:** Leśne schronienie Czcibora i fragment górnego dojścia obozowego.

**Geometria/inscenizacja:** Odcinki dróg `camp__shelter` i `camp__crossroads` przecinają S02; nie utożsamiać z całym skrótem.

**Greybox/QA:** Otwieranie skrótu od obozu i powrót do rozstaju przetestować bez przeskoku sceny.

**Punkty kotwiczone:** `shelter`.

**Odpowiedzialność za trasy od punktów początkowych:** brak.

**Trasy z innych sektorów przecinające ten sektor:** `camp__shelter`, `camp__crossroads`.

### S03 — Wschodni las i podejście

**Funkcja:** Niegrywalny górny skraj wschodniego boru.

**Geometria/inscenizacja:** Skały i gęstwina w tle ruin; żaden punkt ani trasa v0.2 nie ma kotwicy w tym sektorze.

**Greybox/QA:** Brak sztucznego dodatkowego wejścia do komory i na finał.

**Punkty kotwiczone:** brak.

**Odpowiedzialność za trasy od punktów początkowych:** brak.

**Trasy z innych sektorów przecinające ten sektor:** brak.

### S10 — Zerwany most i wóz

**Funkcja:** Wóz, podejście do mostu, oznaczone drzewo.

**Geometria/inscenizacja:** Pierwsza wizyta **przed zmierzchem** (chłodno, deszczowo), rano powrót; 2 drożne obejścia wozu, osobny koń, buty i pakunki. Trasa z rozstaju przekracza granicę S11→S10.

**Greybox/QA:** Dwa rzeczywiście przechodnie boki wozu oraz wyraźna wyrwa mostu; test „przed zmierzchem”, nie „nocą”.

**Punkty kotwiczone:** `wagon`, `bridge`, `loop_mark`.

**Odpowiedzialność za trasy od punktów początkowych:** `wagon__bridge`, `wagon__loop_mark`, `loop_mark__wagon`.

**Trasy z innych sektorów przecinające ten sektor:** `crossroads__wagon`.

### S11 — Rozstaj oraz cmentarne miejsce

**Funkcja:** Rozstaj, miejsce cmentarne i **cały pierwszy słup** na skraju tej strefy.

**Geometria/inscenizacja:** Punkt `pillar_whole` = (11.4, 11.3) leży w S11; droga `stones__pillar_whole` zaczyna się w S12 i wchodzi do S11. Pętla A to wyłącznie wariant, nie zatwierdzony cud.

**Greybox/QA:** Sprawdzić orientację między bramą, rozstajem i wozem; anomalię A/B oddzielnie według VARIANTS.md.

**Punkty kotwiczone:** `crossroads`, `grave`, `pillar_whole`.

**Odpowiedzialność za trasy od punktów początkowych:** `crossroads__wagon`, `crossroads__grave`, `crossroads__stones`.

**Trasy z innych sektorów przecinające ten sektor:** `gate__crossroads`, `loop_mark__wagon`, `stones__pillar_whole`, `stones__song`, `camp__crossroads`.

### S12 — Kamienie i obóz

**Funkcja:** Węzeł trzech dróg, **słup powalony i rozbity**, obóz i początek traktu.

**Geometria/inscenizacja:** Punkty `pillar_fallen` (14.9, 11.5) i `pillar_broken` (15.1, 9.3) leżą w S12; pierwszy słup leży w S11, ale projekt jego dojścia startuje w S12.

**Greybox/QA:** Trzy ślady w dowolnej kolejności; droga do kamieni nie blokuje odwrotu; wejście na trakt tylko z odpowiednią flagą.

**Punkty kotwiczone:** `stones`, `pillar_fallen`, `pillar_broken`, `camp`, `tools`, `old_road`.

**Odpowiedzialność za trasy od punktów początkowych:** `stones__pillar_whole`, `stones__pillar_fallen`, `stones__pillar_broken`, `stones__song`, `stones__snares`, `stones__camp`, `camp__tools`, `camp__shelter`, `camp__ruins`, `camp__crossroads`, `stones__old_road`, `old_road__guardian`.

**Trasy z innych sektorów przecinające ten sektor:** `crossroads__stones`.

### S13 — Ruiny oraz finał

**Funkcja:** Ruiny, komora, Stróż i **kotwica suchego szlaku**.

**Geometria/inscenizacja:** `dry_road` = (22.7, 10.4) leży w S13, nie w S23. Komora jest podziemnym poziomem w tej samej podróży, ale sposób organizacji scen silnika jest otwarty.

**Greybox/QA:** Bez bezpośredniego skrótu z komory na Stróża; płynne zejście bez widocznego ekranu ładowania.

**Punkty kotwiczone:** `ruins`, `chamber`, `guardian`, `dry_road`.

**Odpowiedzialność za trasy od punktów początkowych:** `ruins__chamber`, `guardian__dry_road`.

**Trasy z innych sektorów przecinające ten sektor:** `camp__ruins`, `old_road__guardian`.

### S20 — Nieprzebyta skarpa i podmokłości

**Funkcja:** Tło: południowo-zachodnie podmokłości.

**Geometria/inscenizacja:** Naturalna granica doliny bez grywalnych kotwic i ścieżek w v0.2.

**Greybox/QA:** Nie sugerować graczowi otwartej drogi w bagno.

**Punkty kotwiczone:** brak.

**Odpowiedzialność za trasy od punktów początkowych:** brak.

**Trasy z innych sektorów przecinające ten sektor:** brak.

### S21 — Polana z pieśnią

**Funkcja:** Polana z pieśnią i boczna droga od trzech kamieni.

**Geometria/inscenizacja:** Wyraźnie poboczne spotkanie: Żałobnica + Powrotnik. Co najmniej dwa sposoby przerwania osłony, nagroda nie służy do odblokowania finału.

**Greybox/QA:** Test: czytelna zapowiedź i droga odwrotu, bez ostrzału poza widokiem.

**Punkty kotwiczone:** `song`.

**Odpowiedzialność za trasy od punktów początkowych:** brak.

**Trasy z innych sektorów przecinające ten sektor:** `stones__song`.

### S22 — Sidła i jama Zbieracza

**Funkcja:** Ślady sideł i jama Zbieracza. Słup powalony i rozbity należą do S12.

**Geometria/inscenizacja:** Znaki pułapek widoczne przed zejściem do jamy. Opcjonalny miniboss bez wpływu na uzyskanie lampy ani pokonanie Stróża.

**Greybox/QA:** Test: możliwość ominięcia bez walki i powrót na normalną trasę, żadnych ślepych zagłębień.

**Punkty kotwiczone:** `snares`, `collector`.

**Odpowiedzialność za trasy od punktów początkowych:** `snares__collector`.

**Trasy z innych sektorów przecinające ten sektor:** `stones__snares`.

### S23 — Południowo-wschodnia granica doliny (tło suchego szlaku)

**Funkcja:** **Tło i dalszy skraj doliny**, nie właściciel suchej drogi.

**Geometria/inscenizacja:** Brak punktów i polilinii w S23. Możliwa dalsza panorama świata, lecz koniec grywalnego demo jest przy `dry_road` w S13.

**Greybox/QA:** Nie projektować fikcyjnej grywalnej drogi w S23; brak nowej krainy bez kanonu.

**Punkty kotwiczone:** brak.

**Odpowiedzialność za trasy od punktów początkowych:** brak.

**Trasy z innych sektorów przecinające ten sektor:** brak.

## Zgłoszone rozbieżności — zweryfikowane

| Punkt | Współrzędne siatki | Sektor kotwicy | Gdzie przebiega droga | Korekta |
|---|---|---|---|---|
| `pillar_whole` | (11.4, 11.3) | **S11** | `stones__pillar_whole` S12→S11 | Usunięto błędne przypisanie słupa do S12; w S12 pozostaje odpowiedzialność za początek dojścia. |
| `pillar_fallen` | (14.9, 11.5) | **S12** | `stones__pillar_fallen` w S12 | Usunięto błędny opis S22 jako właściciela. |
| `pillar_broken` | (15.1, 9.3) | **S12** | `stones__pillar_broken` w S12 | Usunięto błędny opis S22. |
| `dry_road` | (22.7, 10.4) | **S13** | `guardian__dry_road` w S13 | Przedefiniowano S23 jako tło, nie „miejsce suchego szlaku”. |

Ponadto analiza grafu wykazała **11 tras przecinających sektory**; np. skrót `camp__crossroads` przecina S12, S02, **S01** i S11. Dla tego fragmentu w S01 trzeba sprawdzić, czy nie widać przypadkowego dodatkowego wyjścia z Niemiru. To zadanie greyboxu, nie powód do samowolnego przesunięcia skrótu.

## Kontrola przypisań

Dane: [`world-layout.v0.2.json`](world-layout.v0.2.json).
