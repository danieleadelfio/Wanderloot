class_name Crafting
extends RefCounted
## Regole di crafting (logica pura): verifica e applica una ricetta su inventario e loadout permanenti.

enum Result { OK, INVALID_RECIPE, ALREADY_OWNED, NOT_ENOUGH_MATERIALS }


static func check(recipe: RecipeData, inventory: MetaInventory, loadout: EquipmentLoadout) -> Result:
	if recipe == null or recipe.result == null or recipe.result.id == &"":
		return Result.INVALID_RECIPE
	if loadout.owns(recipe.result.id):
		return Result.ALREADY_OWNED
	if not inventory.can_afford(recipe.cost_dictionary()):
		return Result.NOT_ENOUGH_MATERIALS
	return Result.OK


## Consuma i materiali e aggiunge il pezzo ai posseduti solo se check() e' OK; altrimenti non tocca nulla.
static func craft(recipe: RecipeData, inventory: MetaInventory, loadout: EquipmentLoadout) -> Result:
	var result := check(recipe, inventory, loadout)
	if result == Result.OK:
		inventory.spend(recipe.cost_dictionary())
		loadout.add_owned(recipe.result.id)
	return result
