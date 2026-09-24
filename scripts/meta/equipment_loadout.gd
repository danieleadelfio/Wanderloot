class_name EquipmentLoadout
extends RefCounted
## Equipaggiamento permanente (M11): tutte le istanze possedute (per uid) e l'istanza indossata per slot.
## Logica pura, senza I/O: la persistenza e' in MetaProgression.

## Slot del manichino. Nuove voci solo in coda (salvate per nome, ma usate negli indici dell'UI).
enum EquipSlot { WEAPON, AMULET, HEAD, GLOVES, ARMOR, PANTS, BOOTS, RING_1, RING_2 }

var _items: Dictionary[int, ItemInstance] = {}
## EquipSlot -> uid dell'istanza indossata.
var _equipped: Dictionary[int, int] = {}
var _next_uid: int = 1


## Slot del manichino in cui puo' andare un tipo di oggetto (gli anelli ne hanno due).
static func slots_for(item_slot: EquipmentData.Slot) -> Array[int]:
	match item_slot:
		EquipmentData.Slot.WEAPON:
			return [EquipSlot.WEAPON]
		EquipmentData.Slot.HEAD:
			return [EquipSlot.HEAD]
		EquipmentData.Slot.GLOVES:
			return [EquipSlot.GLOVES]
		EquipmentData.Slot.ARMOR:
			return [EquipSlot.ARMOR]
		EquipmentData.Slot.PANTS:
			return [EquipSlot.PANTS]
		EquipmentData.Slot.BOOTS:
			return [EquipSlot.BOOTS]
		EquipmentData.Slot.RING:
			return [EquipSlot.RING_1, EquipSlot.RING_2]
	return [EquipSlot.AMULET]


## Aggiunge un'istanza e le assegna un uid se non ce l'ha (o se e' gia' usato).
func add(item: ItemInstance) -> ItemInstance:
	if item == null or item.base == null:
		return null
	if item.uid <= 0 or _items.has(item.uid):
		item.uid = _next_uid
	_next_uid = maxi(_next_uid, item.uid + 1)
	_items[item.uid] = item
	return item


## Toglie un'istanza posseduta (anche se indossata).
func remove(uid: int) -> void:
	for slot in _equipped.keys():
		if _equipped[slot] == uid:
			_equipped.erase(slot)
	_items.erase(uid)


func get_item(uid: int) -> ItemInstance:
	return _items.get(uid)


## Tutte le istanze, in ordine di acquisizione.
func all_items() -> Array[ItemInstance]:
	var uids := _items.keys()
	uids.sort()
	var result: Array[ItemInstance] = []
	for uid in uids:
		result.append(_items[uid])
	return result


## Istanze non indossate (il "baule" degli oggetti).
func stash_items() -> Array[ItemInstance]:
	return all_items().filter(func(item: ItemInstance) -> bool: return not is_equipped(item.uid))


func count_of(base_id: StringName) -> int:
	return all_items().filter(func(item: ItemInstance) -> bool: return item.base.id == base_id).size()


## Indossa l'istanza nel suo slot: il primo libero tra quelli possibili, altrimenti sostituisce il primo.
func equip(uid: int) -> bool:
	var item: ItemInstance = _items.get(uid)
	if item == null:
		return false
	if is_equipped(uid):
		return true
	var slots := slots_for(item.slot())
	var target: int = slots[0]
	for slot in slots:
		if not _equipped.has(slot):
			target = slot
			break
	_equipped[target] = uid
	return true


func unequip(slot: int) -> void:
	_equipped.erase(slot)


func equipped_in(slot: int) -> ItemInstance:
	return _items.get(_equipped.get(slot, 0))


func is_equipped(uid: int) -> bool:
	return _equipped.values().has(uid)


## Istanze indossate, in ordine di slot.
func equipped_items() -> Array[ItemInstance]:
	var result: Array[ItemInstance] = []
	for slot: int in EquipSlot.values():
		var item := equipped_in(slot)
		if item:
			result.append(item)
	return result


func equipped_slots() -> Dictionary[int, int]:
	return _equipped.duplicate()


static func slot_key(slot: int) -> String:
	return String(EquipSlot.find_key(slot)).to_lower()


func clear() -> void:
	_items.clear()
	_equipped.clear()
	_next_uid = 1
