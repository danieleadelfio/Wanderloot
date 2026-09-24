class_name RingBurstEffect
extends AbilityEffect
## Anello di proiettili attorno al player con l'arma della run (Anello arcano).

@export var count: int = 10
@export var damage_multiplier: float = 1.0


func activate(host: WandAbilities) -> void:
	host.spawn_ring(count + host.player.stats.count_bonus, damage_multiplier)
