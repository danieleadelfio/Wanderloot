class_name MetaInventory
extends RefCounted
## Inventario permanente (id materiale -> quantita'). Logica pura, senza I/O: la persistenza e' in MetaProgression.

var _amounts: Dictionary[StringName, int] = {}


func deposit(amounts: Dictionary[StringName, int]) -> void:
	for id in amounts:
		if amounts[id] > 0:
			_amounts[id] = _amounts.get(id, 0) + amounts[id]


func amount_of(id: StringName) -> int:
	return _amounts.get(id, 0)


func total() -> int:
	var sum := 0
	for amount in _amounts.values():
		sum += amount
	return sum


func to_dictionary() -> Dictionary[StringName, int]:
	return _amounts.duplicate()


func can_afford(costs: Dictionary[StringName, int]) -> bool:
	for id in costs:
		if amount_of(id) < costs[id]:
			return false
	return true


## Scala i costi solo se tutti coperti; altrimenti non tocca nulla. I materiali a zero vengono rimossi.
func spend(costs: Dictionary[StringName, int]) -> bool:
	if not can_afford(costs):
		return false
	for id in costs:
		if costs[id] <= 0:
			continue
		_amounts[id] -= costs[id]
		if _amounts[id] <= 0:
			_amounts.erase(id)
	return true


func load_dictionary(amounts: Dictionary[StringName, int]) -> void:
	_amounts.clear()
	deposit(amounts)
