class_name RingBurstEffect
extends AbilityEffect
## Anello di proiettili attorno al player con l'arma della run (Anello arcano).

@export var count: int = 10
@export var damage_multiplier: float = 1.0
## Proiettili in piu' per ogni livello oltre il primo.
@export var count_per_level: int = 5


func activate(host: WandAbilities, level: int = 1) -> void:
	host.spawn_ring(count + count_per_level * (level - 1) + host.player.stats.count_bonus, damage_multiplier)
