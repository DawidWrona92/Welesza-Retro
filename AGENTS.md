# Welesza — zasady dla agentów

## Zespół

Role, zadania i kamienie milowe: [docs/PLAN.md](docs/PLAN.md). PM (Claude) zarządza pozostałymi agentami, przydziela zadania z planu, przegląda każdy PR przed autorem i bierze najtrudniejsze prace. Spór o kierunek rozstrzyga autor; PM przedstawia mu go z rekomendacją.

## Zasady pracy

- **Hierarchia dokumentów:** biblia świata opisuje, co jest w świecie (kosmos, wiara, frakcje, architektura, kraina). Kierunek artystyczny wyznacza, jak to wygląda, i wzoruje się na biblii; nie ustanawia faktów o świecie. Kanon demo (fabuła, przeciwnicy, mapa) ma pierwszeństwo przed biblią. Sprzeczność treści między tymi dokumentami (np. „wielkie katedry” wobec „małych chramów”) to błąd do zgłoszenia autorowi; różny poziom szczegółu nim nie jest.
- Zacznij od [docs/INDEX.md](docs/INDEX.md). Obowiązuje opisana tam konwencja statusu: wszystko jest propozycją, chyba że oznaczono decyzję autora.
- Nie zmieniaj statusu decyzji bez potwierdzenia autora. Nie dopisuj faktów fabularnych bez jego zgody.
- Zmiany i doprecyzowania zapisuj w dokumencie, którego dotyczą. Nie twórz nowych plików, rejestrów ani dokumentów pomocniczych bez potrzeby.
- Dokumentacja jest po polsku. Pisz krótko, bez powtarzania zastrzeżeń.
- Skille projektowe są w [`.agents/skills/`](.agents/skills/); punkt wejścia to design-maestro.

## Git

- Każde zadanie na osobnym branchu, zmiany przez PR. Nie pushuj bezpośrednio na `main`.
- Nie przepisuj historii cudzych branchy bez zgody właściciela PR; nie tracimy danych przy rebase ani merge.

## Kod (Godot)

- Godot 4.7.2-stable, GDScript w składni Godota 4, z typowaniem; bez C#/.NET.
- Przed commitem: `gdlint` i sprawdzenie skryptów w trybie headless.
