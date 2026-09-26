extends GdUnitTestSuite
## Guardie di bilanciamento (M13, #86): fusione a sei invece di tre, costi di crafting triplicati,
## bonus del raggio di raccolta (magnete) ridotto di 3 volte sia da equip che da upgrade di run.

const AFFIXES: AffixTable = preload("res://data/equipment/affix_table.tres")


func test_fusion_count_is_six() -> void:
	assert_int(Forge.FUSION_COUNT).is_equal(6)


func test_recipe_costs_are_tripled_from_pre_m13_values() -> void:
	# Valori pre-M13 noti (prima della tripla): gel_wand 25, slime_boots 30, core_amulet 20+3.
	var book: RecipeBook = load("res://data/recipes/recipe_book.tres")
	var costs_by_id: Dictionary = {}
	for recipe in book.recipes:
		costs_by_id[recipe.result.id] = recipe.cost_dictionary()
	assert_int(costs_by_id[&"gel_wand"][&"slime_gel"]).is_equal(75)
	assert_int(costs_by_id[&"slime_boots"][&"slime_gel"]).is_equal(90)
	assert_int(costs_by_id[&"core_amulet"][&"slime_gel"]).is_equal(60)
	assert_int(costs_by_id[&"core_amulet"][&"slime_core"]).is_equal(9)


func test_magnet_upgrade_bonus_is_reduced_to_a_third() -> void:
	# Era +30% (amount 1.3): ridotto di 3 volte -> +10% (amount 1.1).
	var magnet_up: UpgradeData = load("res://data/upgrades/magnet_up.tres")
	assert_float(magnet_up.amount).is_equal_approx(1.1, 0.001)


func test_wanderer_hood_pickup_radius_bonus_is_reduced_to_a_third() -> void:
	# Era +20% (amount 1.2): ridotto di 3 volte -> +6,7% (amount 1.067).
	var hood: EquipmentData = load("res://data/equipment/wanderer_hood.tres")
	var mod: StatModifier = hood.modifiers.filter(func(m: StatModifier) -> bool: return m.stat == UpgradeData.Stat.PICKUP_RADIUS)[0]
	assert_float(mod.amount).is_equal_approx(1.067, 0.001)


func test_pickup_radius_affix_range_is_reduced_to_a_third() -> void:
	# Era 1,1-1,4 (+10%..+40%): ridotto di 3 volte -> ~1,033-1,133 (+3,3%..+13,3%).
	var source: AffixRoll = AFFIXES.rolls.filter(func(r: AffixRoll) -> bool: return r.stat == UpgradeData.Stat.PICKUP_RADIUS)[0]
	assert_float(source.min_value).is_equal_approx(1.033, 0.001)
	assert_float(source.max_value).is_equal_approx(1.133, 0.001)
