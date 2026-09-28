class_name LootRunInventory
extends RefCounted
## Loot "a rischio" della run corrente: materiali (id -> quantita'), oggetti trovati (M11, #58) e
## Bag of Resources (M13, #86: sacchetti ancora chiusi, si aprono nella piazza dopo l'estrazione).
## Separato dall'inventario permanente: passa a MetaProgression solo con un'estrazione riuscita.

signal changed(total: int)

var _amounts: Dictionary[StringName, int] = {}
var _items: Array[ItemInstance] = []
var _bags: int = 0


func add(material: MaterialData, amount: int) -> void:
	if material == null or amount <= 0:
		return
	_amounts[material.id] = _amounts.get(material.id, 0) + amount
	changed.emit(total())


func add_item(item: ItemInstance) -> void:
	if item == null:
		return
	_items.append(item)
	changed.emit(total())


func add_bags(count: int) -> void:
	if count <= 0:
		return
	_bags += count
	changed.emit(total())


func bags() -> int:
	return _bags


func items() -> Array[ItemInstance]:
	return _items.duplicate()


func amount_of(id: StringName) -> int:
	return _amounts.get(id, 0)


func total() -> int:
	var sum := 0
	for amount in _amounts.values():
		sum += amount
	return sum + _items.size() + _bags


func is_empty() -> bool:
	return _amounts.is_empty() and _items.is_empty() and _bags == 0


func to_dictionary() -> Dictionary[StringName, int]:
	return _amounts.duplicate()


func clear() -> void:
	if is_empty():
		return
	_amounts.clear()
	_items.clear()
	_bags = 0
	changed.emit(0)
