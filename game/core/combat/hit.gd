class_name Hit
extends RefCounted
## Pojedynczy cios, który dosięgnął celu.
## Rozstrzygnięcie: kontakt -> obrona -> skutek (docs/walka.md).

enum Result { HIT, BLOCKED, PARRIED }

var attacker: Combat
var origin: Vector2
var damage: float = 10.0
## Parowalne są ataki bronią; chwyty, ataki zwierząt i ciężkie ciosy nie (docs/przeciwnicy.md).
var parryable: bool = true
## Koszt wytrzymałości obrońcy przy zablokowaniu gardą.
var guard_cost: float = 15.0
var armor_pierce: float = 0.0
var crit_chance: float = 0.0
## Trafienie przerywa akcję celu i wprowadza go w krótkie ogłuszenie.
var interrupts: bool = true
