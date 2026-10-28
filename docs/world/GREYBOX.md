# Welesza — plan pierwszego greyboxu (v0.2)

**Priorytet:** brama → rozstaj → wóz → podejście do mostu. Pozostałe sektory tylko zaznaczone, bez szczegółowej geometrii. Testy poniżej są **do wykonania w silniku**, nie zostały zaliczone przez sam projekt mapy.

## Faza G0 — instrumentacja i skala

Zmierzyć w prototypie: `D` średnica/obrys kolizji bohatera (wraz z typowymi odchyleniami), `B` największy odpowiedni obrys Psa/Powrotnika, `U` całkowity dystans uniku z fazą rozpoczęcia i odzyskania kontroli, `A` największy zasięg zapowiedzi i trafienia, `V` widoczny obszar podłoża i dynamika kamery. Zarejestrować wersję assetów, kamerę, FPS/timing i ścieżkę wejścia. **Nie wyprowadzać metrów z 24×18 komórek papierowej mapy.**

## Faza G1 — prosty ciąg terenu

1. Brama z jednym rzeczywistym wejściem, dziedziniec i droga na rozstaj.
2. Pochylone drzewo jako landmark i dwa czytelne kierunki: do wozu / dalej ku kamieniom (dalszy odcinek może być poprawnie zakończony naturalną granicą w wersji G1).
3. Plac wozu oparty na [`docs/mapa-demo.md`](../mapa-demo.md): cztery koła, prawidłowo skierowany dyszel, oddzielny koń, buty przy kole, pakunki i księga jako osobne obiekty.
4. **Obejścia po obu bokach wozu** są pełnymi trasami między obiema stronami placu. Nie pozwolić, aby dyszel, koń, skrzynie lub dekoracje domknęły jeden bok. Nie zakładać przechodniości na podstawie samego rysunku.
5. Boczna trasa do zerwanego mostu: brzeg widoczny, faktyczna wyrwa i drugi przyczółek; bez konieczności skoku. Most nie musi znajdować się w kadrze wozu.
6. Oddzielny testowy wjazd na „drogę, która wraca” bez finalnego efektu; tryby A/B po osobnej decyzji.

**Uwaga do schematów:** opis wozu pokazuje oś prolog → wóz → rozstaj → światło, natomiast makromapa ma brama → rozstaj → wóz → most; to **nie konflikt**: prolog zaczyna się przy wozie, rano wraca się do niego od strony osady. Bez dokładnych odległości oba opisy da się pogodzić. Nie należy automatycznie nadawać stronie mostu osobnego wejścia do doliny ani obracać wozu zgodnie z orientacją JPG.

## Faza G2 — testy ruchu i walki

| Test | Metoda w greyboxie | Co zanotować / kryterium jakościowe |
|---|---|---|
| Długość traktu | Przejście i bieg brama↔rozstaj↔wóz z kamerą gry, nagranie. | Rytm i monotonność, orientacja bez minimapy, realny czas w sekundach z pomiaru. |
| Szerokość ścieżek | Przejście bohaterem i Psem; uniki przy pniach i skarpie. | Brak zahaczania, zapas ≥ obrys i margines na manewr; nie ustalamy jeszcze metrów. |
| Dwa obejścia | Klikanie na przemian po obu stronach wozu; próba przeprowadzenia Psa, kontrola toru pocisku. | Obie trasy naprawdę drożne, bez tzw. softlocku; wóz faktycznie blokuje linię ataku jeśli przyjmiemy tę regułę. |
| Zapowiedź Psa | Pies na obrzeżu placu, unik w kilku kierunkach. | Postać i zapowiedź mieszczą się w `V`; `U` nie kończy się niewidzialnym colliderem. |
| Powrotnik | Drugi wróg dalej, bez automatycznego dołączenia do pierwszej walki. | Czytelne odróżnienie dwóch spotkań; odwrót do rozstaju. |
| Landmarki | Test nieznanej mapy: bez minimapy znaleźć wóz, bramę, potem most. | Błędy orientacji; czy światło bramy oraz pochylone drzewo naprawdę pomagają. |
| Zasłanianie | Okrążenie wozu, przejście pod koronami, przy bramie. | Brak utraty bohatera, celu interakcji i telegraphu; dokumentować kąty kamery. |
| Granice doliny | Próby dojścia poza trakt po całej stronie północnej i przy potoku. | Naturalny brzeg/skała/gęstwina, nie rząd niewidzialnych ścian. Gracz czuje las, a nie tunel. |
| Odwrót | Pies/pościg do granicy nieagresji i powrót. | Przeciwnik nie atakuje z „bezpiecznej” strony granicy; brak snapowania stanu na szwie. |
| Ciągłość podróży | Przejście brama↔rozstaj↔wóz↔most, tam i z powrotem. | Brak widocznego loadingu, skoków obrazu, utraty sterowania i obiektów. Zmierzyć czas klatek i pamięć. |
| Pora | Prolog przy wozie **przed zmierzchem**, potem nocleg, następnego ranka odwiedziny i pies. | Brak automatycznej nocnej pierwszej wizyty; poprawne światło/stany bez nowego kanonu cyklu dobowego. |

## Faza G3 — anomalia, latarnia i sektory

Autor wybrał wariant B z [`VARIANTS.md`](VARIANTS.md); A służy tylko jako punkt odniesienia. Wariant A należy przygotować jedynie jako baseline z aktualnej polilinii; B może wymagać specjalnego modelu połączeń. Próba ślepa obserwatorów ma rozstrzygnąć, czy gracz interpretuje sytuację jako coś nadprzyrodzonego. Osobne testy podczas pościgu, przerwania uniku, podnoszenia przedmiotu i odwrotu. Żaden ze stanów pętli nie powinien podmieniać instancji wozu, butów, psa i księgi.

Kamienie, słupy, strażnica, latarnia i Stróż czekają do kolejnych iteracji. Wejścia do sektorów pozostają niewidocznymi umownymi podziałami pracy; **to nie gotowy podział scen silnika**.

## Protokół dokumentowania wyników

Dla każdej próby: identyfikator builda, scenariusz, wersja bohatera/Psa, kamera, urządzenie, pozycja startowa, wynik PASS/FAIL/NOT_RUN, nagranie i komentarz. Zmiany `D/B/U/A/V` wymuszają ponowienie odpowiednich prób. **Nie przyznawać PASS bez testu silnikowego.**
