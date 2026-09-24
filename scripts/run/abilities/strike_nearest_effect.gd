class_name StrikeNearestEffect
extends AbilityEffect
## Fulmine sul nemico piu' vicino entro range: danno ad area (danno dell'arma + bonus). Fulmine errante.
## Un fulmine per livello; con il Contatore altrettanti in piu' (i nemici piu' vicini, uno per fulmine).

@export var range: float = 420.0
@export var radius: float = 70.0
@export var damage_bonus: int = 2


func activate(host: WandAbilities, level: int = 1) -> void:
	host.strike_nearest(range, radius, damage_bonus, level + host.player.stats.count_bonus)
