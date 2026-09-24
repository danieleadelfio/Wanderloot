class_name StashSort
extends RefCounted
## Ordine degli oggetti nel baule (M11.3, #69). Logica pura.

enum Mode { ARRIVAL, RARITY, CATEGORY }


## ARRIVAL: dal piu' vecchio (uid); RARITY: dal piu' raro, poi per slot; CATEGORY: per slot, poi dal piu' raro.
static func sorted(items: Array[ItemInstance], mode: Mode) -> Array[ItemInstance]:
	var result := items.duplicate()
	match mode:
		Mode.RARITY:
			result.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool: return _key(a, [-a.rarity, a.slot()]) < _key(b, [-b.rarity, b.slot()]))
		Mode.CATEGORY:
			result.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool: return _key(a, [a.slot(), -a.rarity]) < _key(b, [b.slot(), -b.rarity]))
		_:
			result.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool: return a.uid < b.uid)
	return result


static func _key(item: ItemInstance, head: Array) -> Array:
	return head + [String(item.base.id), item.uid]
