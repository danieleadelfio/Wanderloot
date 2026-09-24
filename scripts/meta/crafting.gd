class_name Crafting
extends RefCounted
## Regole di crafting (logica pura): verifica e applica una ricetta su inventario e loadout permanenti.
## Da M11 ogni craft crea una nuova istanza (si possono avere piu' copie dello stesso oggetto).
## Result: ALREADY_OWNED non viene piu' restituito (lasciato per non spostare i valori dell'enum).

enum Result { OK, INVALID_RECIPE, ALREADY_OWNED, NOT_ENOUGH_MATERIALS }


static func check(recipe: RecipeData, inventory: MetaInventory) -> Result:
	if recipe == null or recipe.result == null or recipe.result.id == &"":
		return Result.INVALID_RECIPE
	if not inventory.can_afford(recipe.cost_dictionary()):
		return Result.NOT_ENOUGH_MATERIALS
	return Result.OK


## Consuma i materiali e aggiunge una nuova istanza (creata da make_item, oppure Comune senza bonus)
## solo se check() e' OK; altrimenti non tocca nulla. Restituisce l'istanza creata o null.
static func craft(recipe: RecipeData, inventory: MetaInventory, loadout: EquipmentLoadout, make_item: Callable = Callable()) -> ItemInstance:
	if check(recipe, inventory) != Result.OK:
		return null
	inventory.spend(recipe.cost_dictionary())
	var item: ItemInstance = make_item.call(recipe.result) if make_item.is_valid() else ItemInstance.new(recipe.result)
	return loadout.add(item)
