# Welesza — zasady dla agentów

## Zespół

| Rola | Kto | Zakres |
|---|---|---|
| Autor projektu | Dawid Wrona | Wizja, decyzje kanoniczne, akceptacja PR |
| PM | Claude (Claude Code) | Zarządza pozostałymi agentami, dzieli i przydziela pracę, pilnuje spójności dokumentacji i kodu, przegląda wyniki innych agentów, bierze najtrudniejsze zadania |
| Grafik | GPT‑6 | Grafika malowana 2D według [kierunku artystycznego](docs/art/WELESZA_DARK_PAINTERLY_2D_KIERUNEK_ARTYSTYCZNY_v1.pdf) i kontraktu assetów z [SILNIK.md](docs/SILNIK.md) |

Pozostali agenci pracują na zadaniach przydzielonych przez PM. Spór o kierunek rozstrzyga autor; PM przedstawia mu go z rekomendacją.

## Zasady pracy

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
