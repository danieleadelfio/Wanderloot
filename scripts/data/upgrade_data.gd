class_name UpgradeData
extends Resource
## Potenziamento temporaneo di run. Il bilanciamento si fa solo nei .tres in res://data/upgrades/.

enum Stat { DAMAGE, FIRE_RATE, PROJECTILE_SPEED, MOVE_SPEED, MAX_HP }

@export var display_name: String = ""
@export_multiline var description: String = ""
@export var stat: Stat = Stat.DAMAGE
## Valore da sommare, o moltiplicatore se is_multiplier.
@export var amount: float = 0.0
@export var is_multiplier: bool = false
## Peso relativo nell'estrazione casuale delle scelte.
@export var weight: float = 1.0


func apply_to(value: float) -> float:
	return value * amount if is_multiplier else value + amount
