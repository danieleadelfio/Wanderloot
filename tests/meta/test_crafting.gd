extends GdUnitTestSuite
## Regole del fabbro: il craft scala esattamente i costi e aggiunge il pezzo, altrimenti non tocca nulla.

var _inventory: MetaInventory
var _loadout: EquipmentLoadout
var _recipe: RecipeData


func before_test() -> void:
	_inventory = MetaInventory.new()
	_loadout = EquipmentLoadout.new()
	_recipe = _make_recipe(&"wand", {&"gel": 6, &"core": 1})


func test_craft_spends_exact_costs_and_adds_owned() -> void:
	_inventory.deposit({&"gel": 8, &"core": 1} as Dictionary[StringName, int])

	assert_int(Crafting.craft(_recipe, _inventory, _loadout)).is_equal(Crafting.Result.OK)

	assert_int(_inventory.amount_of(&"gel")).is_equal(2)
	assert_int(_inventory.amount_of(&"core")).is_equal(0)
	assert_bool(_loadout.owns(&"wand")).is_true()


func test_not_enough_materials_changes_nothing() -> void:
	_inventory.deposit({&"gel": 10} as Dictionary[StringName, int])

	assert_int(Crafting.craft(_recipe, _inventory, _loadout)).is_equal(Crafting.Result.NOT_ENOUGH_MATERIALS)

	assert_int(_inventory.amount_of(&"gel")).is_equal(10)
	assert_bool(_loadout.owns(&"wand")).is_false()


func test_already_owned_is_refused_without_spending() -> void:
	_inventory.deposit({&"gel": 20, &"core": 5} as Dictionary[StringName, int])
	_loadout.add_owned(&"wand")

	assert_int(Crafting.craft(_recipe, _inventory, _loadout)).is_equal(Crafting.Result.ALREADY_OWNED)

	assert_int(_inventory.amount_of(&"gel")).is_equal(20)


func test_recipe_without_result_is_invalid() -> void:
	var recipe := RecipeData.new()
	assert_int(Crafting.check(recipe, _inventory, _loadout)).is_equal(Crafting.Result.INVALID_RECIPE)
	assert_int(Crafting.check(null, _inventory, _loadout)).is_equal(Crafting.Result.INVALID_RECIPE)


func test_cost_dictionary_sums_duplicates_and_ignores_invalid_rows() -> void:
	var recipe := _make_recipe(&"x", {&"gel": 2})
	var extra := MaterialCost.new()
	extra.material = recipe.costs[0].material
	extra.amount = 3
	var empty := MaterialCost.new()
	recipe.costs.append_array([extra, empty, null])

	assert_dict(recipe.cost_dictionary()).is_equal({&"gel": 5})


func _make_recipe(result_id: StringName, costs: Dictionary) -> RecipeData:
	var recipe := RecipeData.new()
	recipe.result = EquipmentData.new()
	recipe.result.id = result_id
	for id in costs:
		var cost := MaterialCost.new()
		cost.material = MaterialData.new()
		cost.material.id = id
		cost.amount = costs[id]
		recipe.costs.append(cost)
	return recipe
