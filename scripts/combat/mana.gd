class_name Mana
extends RefCounted
## Pool di mana consumato dall'attacco principale (M12, #86): non le abilita' della bacchetta, solo lo
## sparo base (Weapon.try_fire). Regen continuo (non a scatti), letto/scritto ogni frame da chi la
## possiede, come Knockback: nessun nodo, nessun segnale.

var current: float = 0.0
var max_value: float = 0.0
var regen_per_second: float = 0.0
## Prisma di Mana (consumabile, M13, #86): finche' true, ogni costo e' sempre permesso e non
## scala il pool (si vede pieno). Impostato/tolto da Player.boost_infinite_mana().
var unlimited: bool = false


func reset(new_max: float, new_regen: float) -> void:
	max_value = maxf(new_max, 0.0)
	regen_per_second = maxf(new_regen, 0.0)
	current = max_value


## cost <= 0 (arma senza costo di mana), o mana infinito attivo, e' sempre permesso, anche a pool vuoto.
## Cambia il massimo; se aumenta, la differenza si aggiunge subito al pool corrente (come Health.set_max_hp).
func set_max_value(new_max: float) -> void:
	var gained := new_max - max_value
	max_value = maxf(new_max, 0.0)
	current = clampf(current + maxf(gained, 0.0), 0.0, max_value)


func can_afford(cost: float) -> bool:
	return unlimited or cost <= 0.0 or current >= cost


## true e scala se disponibile; false e nessun effetto se il pool non basta.
func spend(cost: float) -> bool:
	if not can_afford(cost):
		return false
	if not unlimited:
		current = maxf(current - cost, 0.0)
	return true


func regenerate(delta: float) -> void:
	current = minf(current + regen_per_second * delta, max_value)
