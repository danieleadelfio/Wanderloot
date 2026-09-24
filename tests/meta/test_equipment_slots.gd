extends GdUnitTestSuite
## 9 slot del manichino (M11): ogni tipo nel suo slot, due anelli, sostituzione.


func _item(loadout: EquipmentLoadout, path: String) -> ItemInstance:
	return loadout.add(ItemInstance.new(load(path)))


func test_each_type_goes_in_its_slot() -> void:
	var loadout := EquipmentLoadout.new()
	var cases := {
		"res://data/equipment/wanderer_hood.tres": EquipmentLoadout.EquipSlot.HEAD,
		"res://data/equipment/smith_gloves.tres": EquipmentLoadout.EquipSlot.GLOVES,
		"res://data/equipment/bone_armor.tres": EquipmentLoadout.EquipSlot.ARMOR,
		"res://data/equipment/leather_pants.tres": EquipmentLoadout.EquipSlot.PANTS,
		"res://data/equipment/slime_boots.tres": EquipmentLoadout.EquipSlot.BOOTS,
		"res://data/equipment/core_amulet.tres": EquipmentLoadout.EquipSlot.AMULET,
		"res://data/equipment/gel_wand.tres": EquipmentLoadout.EquipSlot.WEAPON,
	}
	for path in cases:
		var item := _item(loadout, path)
		loadout.equip(item.uid)
		assert_object(loadout.equipped_in(cases[path])).is_same(item)
	assert_int(loadout.equipped_items().size()).is_equal(7)


func test_rings_fill_both_slots_then_replace_first() -> void:
	var loadout := EquipmentLoadout.new()
	var a := _item(loadout, "res://data/equipment/gel_ring.tres")
	var b := _item(loadout, "res://data/equipment/gel_ring.tres")
	var c := _item(loadout, "res://data/equipment/gel_ring.tres")
	loadout.equip(a.uid)
	loadout.equip(b.uid)
	assert_object(loadout.equipped_in(EquipmentLoadout.EquipSlot.RING_1)).is_same(a)
	assert_object(loadout.equipped_in(EquipmentLoadout.EquipSlot.RING_2)).is_same(b)
	loadout.equip(c.uid)
	assert_object(loadout.equipped_in(EquipmentLoadout.EquipSlot.RING_1)).is_same(c)
	assert_bool(loadout.is_equipped(a.uid)).is_false()


func test_every_base_item_has_a_recipe() -> void:
	var catalog: EquipmentCatalog = load("res://data/equipment/equipment_catalog.tres")
	var book: RecipeBook = load("res://data/recipes/recipe_book.tres")
	assert_int(catalog.items.size()).is_equal(10)
	for item in catalog.items:
		assert_bool(book.recipes.any(func(r: RecipeData) -> bool: return r.result == item)).override_failure_message("manca la ricetta di %s" % item.id).is_true()
