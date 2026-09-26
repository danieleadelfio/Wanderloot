class_name UpgradeData
extends Resource
## Potenziamento temporaneo di run. Il bilanciamento si fa solo nei .tres in res://data/upgrades/.

## Nuove voci sempre in coda: i .tres salvano l'indice numerico.
enum Stat {
	DAMAGE, FIRE_RATE, PROJECTILE_SPEED, MOVE_SPEED, MAX_HP,
	PROJECTILE_LIFETIME, PICKUP_RADIUS, EXP_GAIN, DROP_CHANCE, INVULNERABILITY, KNOCKBACK,
	PROJECTILE_COUNT, PIERCE, COUNT_BONUS,
}

@export var display_name: String = ""
@export_multiline var description: String = ""
@export var stat: Stat = Stat.DAMAGE
## Valore da sommare, o moltiplicatore se is_multiplier.
@export var amount: float = 0.0
@export var is_multiplier: bool = false
## Peso relativo nell'estrazione casuale delle scelte.
@export var weight: float = 1.0
## Volte massime che si puo' scegliere in una run (0 = nessun tetto). Ventaglio, M12 #86: oltre 2 diventa
## troppo forte in combo con Perforazione/danno ad area; una volta al tetto non compare piu' tra le scelte.
@export var max_picks: int = 0


func apply_to(value: float) -> float:
	return value * amount if is_multiplier else value + amount
