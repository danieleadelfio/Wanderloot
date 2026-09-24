class_name Forge
extends RefCounted
## Fusione e smontaggio dal fabbro (GDD §6.3). Logica pura: stato iniettato, nessun autoload.
## Solo oggetti nel baule (non equipaggiati).

## Quota del costo della ricetta restituita smontando un Comune (moltiplicata da salvage_multiplier).
const SALVAGE_SHARE: float = 0.25
## Resa base per oggetti senza ricetta.
const FALLBACK_SALVAGE: Dictionary[StringName, int] = {&"slime_gel": 3}


## Rarita' massima ottenibile per fusione: la penultima (Leggendario); il Mitico solo da ricetta.
static func max_fusion_tier(rarities: RarityTable) -> int:
	return rarities.highest() - 1


## Coppie fondibili: oggetti del baule con stesso oggetto base e stessa rarita', almeno due, sotto il massimo.
## Ogni gruppo e' ordinato per uid (si fondono i primi due).
static func fusion_groups(loadout: EquipmentLoadout, rarities: RarityTable) -> Array[Array]:
	var by_key: Dictionary[String, Array] = {}
	for item in loadout.stash_items():
		if item.rarity >= max_fusion_tier(rarities):
			continue
		var key := "%s/%d" % [item.base.id, item.rarity]
		if not by_key.has(key):
			by_key[key] = []
		by_key[key].append(item)
	var groups: Array[Array] = []
	for key in by_key:
		var group: Array = by_key[key]
		if group.size() >= 2:
			group.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool: return a.uid < b.uid)
			groups.append(group)
	return groups


static func can_fuse(a: ItemInstance, b: ItemInstance, loadout: EquipmentLoadout, rarities: RarityTable) -> bool:
	if a == null or b == null or a == b or not a.same_kind(b):
		return false
	if loadout.get_item(a.uid) != a or loadout.get_item(b.uid) != b:
		return false
	if loadout.is_equipped(a.uid) or loadout.is_equipped(b.uid):
		return false
	return a.rarity < max_fusion_tier(rarities)


## Due oggetti identici della stessa rarita' -> uno della rarita' successiva, bonus e abilita' ritirati.
## make_item(base, tier) crea l'oggetto (MetaProgression.make_item). Ritorna il nuovo oggetto o null.
static func fuse(a: ItemInstance, b: ItemInstance, loadout: EquipmentLoadout, rarities: RarityTable, make_item: Callable) -> ItemInstance:
	if not can_fuse(a, b, loadout, rarities):
		return null
	loadout.remove(a.uid)
	loadout.remove(b.uid)
	return loadout.add(make_item.call(a.base, a.rarity + 1))


## Materiali restituiti smontando: quota del costo della ricetta x moltiplicatore della rarita' (minimo 1).
static func salvage_yield(item: ItemInstance, recipes: RecipeBook, rarities: RarityTable) -> Dictionary[StringName, int]:
	var multiplier := rarities.tier(item.rarity).salvage_multiplier
	var costs: Dictionary[StringName, int] = FALLBACK_SALVAGE
	var share := 1.0
	for recipe in recipes.recipes:
		if recipe.result == item.base or (recipe.result and recipe.result.id == item.base.id):
			costs = recipe.cost_dictionary()
			share = SALVAGE_SHARE
			break
	var result: Dictionary[StringName, int] = {}
	for id in costs:
		result[id] = maxi(1, floori(costs[id] * share * multiplier))
	return result


## Smonta un oggetto del baule: lo rimuove e deposita la resa. false se equipaggiato o sconosciuto.
static func salvage(item: ItemInstance, loadout: EquipmentLoadout, inventory: MetaInventory, amounts: Dictionary[StringName, int]) -> bool:
	if item == null or loadout.get_item(item.uid) != item or loadout.is_equipped(item.uid):
		return false
	loadout.remove(item.uid)
	inventory.deposit(amounts)
	return true
