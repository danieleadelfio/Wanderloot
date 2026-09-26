extends GdUnitTestSuite
## Ossario: sbloccato da 3 estrazioni nella Cripta, nemici macabri, ricompensa craftabile.


func test_ossuary_is_second_arena_and_locked_until_three_crypt_extractions() -> void:
	var catalog: ArenaCatalog = load("res://data/arenas/arena_catalog.tres")
	var ossuary := catalog.find(&"ossuary")
	assert_object(ossuary).is_not_null()
	assert_int(catalog.arenas.find(ossuary)).is_equal(1)
	assert_bool(ossuary.is_unlocked({&"crypt": 2})).is_false()
	assert_bool(ossuary.is_unlocked({&"crypt": 3})).is_true()


func test_ossuary_is_darker_and_harder_than_the_crypt() -> void:
	var crypt: ArenaData = load("res://data/arenas/crypt.tres")
	var ossuary: ArenaData = load("res://data/arenas/ossuary.tres")
	assert_float(ossuary.ambient_color.v).is_less(crypt.ambient_color.v)
	assert_float(ossuary.player_light_scale).is_less(crypt.player_light_scale)
	assert_int(ossuary.wave_data.max_alive).is_greater(crypt.wave_data.max_alive)
	assert_int(ossuary.enemies.size()).is_equal(2)
	assert_float(ossuary.enemies[1].min_time).is_greater(0.0)


func test_bone_wand_recipe_needs_ossuary_materials() -> void:
	var book: RecipeBook = load("res://data/recipes/recipe_book.tres")
	var found: RecipeData = null
	for recipe in book.recipes:
		if recipe.result.id == &"bone_wand":
			found = recipe
	assert_object(found).is_not_null()
	assert_dict(found.cost_dictionary()).is_equal({&"bone_shard": 120, &"shadow_essence": 18})
	var catalog: EquipmentCatalog = load("res://data/equipment/equipment_catalog.tres")
	assert_object(catalog.find(&"bone_wand")).is_not_null()
