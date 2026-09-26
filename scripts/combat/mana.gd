class_name Mana
extends RefCounted
## Pool di mana consumato dall'attacco principale (M12, #86): non le abilita' della bacchetta, solo lo
## sparo base (Weapon.try_fire). Regen continuo (non a scatti), letto/scritto ogni frame da chi la
## possiede, come Knockback: nessun nodo, nessun segnale.

var current: float = 0.0
var max_value: float = 0.0
var regen_per_second: float = 0.0


func reset(new_max: float, new_regen: float) -> void:
	max_value = maxf(new_max, 0.0)
	regen_per_second = maxf(new_regen, 0.0)
	current = max_value


## cost <= 0 (arma senza costo di mana) e' sempre permesso, anche a pool vuoto.
func can_afford(cost: float) -> bool:
	return cost <= 0.0 or current >= cost


## true e scala se disponibile; false e nessun effetto se il pool non basta.
func spend(cost: float) -> bool:
	if not can_afford(cost):
		return false
	current = maxf(current - cost, 0.0)
	return true


func regenerate(delta: float) -> void:
	current = minf(current + regen_per_second * delta, max_value)
