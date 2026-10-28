class_name AttackProfile
extends Resource
## Jeden rodzaj ataku przeciwnika (docs/przeciwnicy.md), np. skok psa albo rozłupanie drwala.
## Czas zapowiedzi i trafienia wyznaczają zdarzenia animacji; profil opisuje skutki i koszty.
## Ataki z profilu nie tworzą wiązanek: to rytm bohatera.

@export var animation: StringName = &"attack"
@export var damage := 10.0
## Ataki bronią są parowalne; chwyty, ataki zwierząt i ciężkie ciosy nie.
@export var parryable := true
@export var guard_cost := 15.0
@export var cost := 12.0
## Odskok po stałym torze w chwili hit_start (jednostki świata), np. skok psa; 0 = bez odskoku.
@export var lunge_distance := 0.0
@export var lunge_duration := 0.2
## Powrót do gotowości po każdym ataku (s); ruch zablokowany.
@export var recovery := 0.0
## Dodatkowy powrót po chybieniu (s): okazja dla gracza, np. ostrze ugrzęzło w ziemi.
@export var miss_recovery := 0.0
## Obszar trafienia wokół atakującego, nie przed nim (atak obrotowy). Garda i parada liczą kąt
## nadal od środka atakującego.
@export var around_self := false
## Mnożnik wielkości Hitboxa dla tego ataku, np. żeby obrót sięgał dalej niż cios przed sobą.
@export var area_scale := 1.0
