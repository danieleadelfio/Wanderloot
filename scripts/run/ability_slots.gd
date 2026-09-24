class_name AbilitySlots
extends RefCounted
## Slot della bacchetta (M10): numero limitato, l'ordine non conta. Logica pura, testata.

var capacity: int = 3
var abilities: Array[WandAbility] = []


func _init(slot_count: int = 3) -> void:
	capacity = slot_count


func is_full() -> bool:
	return abilities.size() >= capacity


func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for ability in abilities:
		result.append(ability.id)
	return result


func has(id: StringName) -> bool:
	return ids().has(id)


func add(ability: WandAbility) -> bool:
	if is_full() or has(ability.id):
		return false
	abilities.append(ability)
	return true


## Sostituisce lo slot index; restituisce l'abilita' tolta (null se indice non valido).
func replace(index: int, ability: WandAbility) -> WandAbility:
	if index < 0 or index >= abilities.size() or has(ability.id):
		return null
	var removed := abilities[index]
	abilities[index] = ability
	return removed


## Colore dei proiettili: media dei colori delle abilita' (bianco senza abilita').
func tint() -> Color:
	if abilities.is_empty():
		return Color.WHITE
	var sum := Color(0, 0, 0, 0)
	for ability in abilities:
		sum += ability.projectile_tint
	return Color(sum.r / abilities.size(), sum.g / abilities.size(), sum.b / abilities.size(), 1.0)
