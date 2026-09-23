class_name EquipmentLoadout
extends RefCounted
## Equipaggiamento permanente: pezzi posseduti (per id) e pezzo equipaggiato per slot.
## Logica pura, senza I/O: la persistenza e' in MetaProgression.

var _owned: Array[StringName] = []
## EquipmentData.Slot -> id del pezzo equipaggiato.
var _equipped: Dictionary[int, StringName] = {}


func add_owned(id: StringName) -> void:
	if id != &"" and not _owned.has(id):
		_owned.append(id)


func owns(id: StringName) -> bool:
	return _owned.has(id)


func owned_ids() -> Array[StringName]:
	return _owned.duplicate()


## Equipaggia un pezzo posseduto, sostituendo quello nello stesso slot. False se non posseduto.
func equip(item: EquipmentData) -> bool:
	if item == null or not owns(item.id):
		return false
	_equipped[item.slot] = item.id
	return true


func unequip(slot: EquipmentData.Slot) -> void:
	_equipped.erase(slot)


func equipped_id(slot: EquipmentData.Slot) -> StringName:
	return _equipped.get(slot, &"")


func is_equipped(id: StringName) -> bool:
	return id != &"" and _equipped.values().has(id)


func equipped_ids() -> Dictionary[int, StringName]:
	return _equipped.duplicate()


func clear() -> void:
	_owned.clear()
	_equipped.clear()
