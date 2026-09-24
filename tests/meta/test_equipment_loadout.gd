extends GdUnitTestSuite
## Loadout a istanze (M11): piu' copie dello stesso oggetto, equip per slot, rimozione.


func _base(id: StringName, slot: EquipmentData.Slot) -> EquipmentData:
	var data := EquipmentData.new()
	data.id = id
	data.slot = slot
	return data


func test_add_assigns_unique_uids_and_allows_duplicates() -> void:
	var loadout := EquipmentLoadout.new()
	var wand := _base(&"wand", EquipmentData.Slot.WEAPON)
	var a := loadout.add(ItemInstance.new(wand))
	var b := loadout.add(ItemInstance.new(wand))
	assert_int(a.uid).is_not_equal(b.uid)
	assert_int(loadout.count_of(&"wand")).is_equal(2)


func test_equip_replaces_in_same_slot_and_unequip_returns_to_stash() -> void:
	var loadout := EquipmentLoadout.new()
	var a := loadout.add(ItemInstance.new(_base(&"wand_a", EquipmentData.Slot.WEAPON)))
	var b := loadout.add(ItemInstance.new(_base(&"wand_b", EquipmentData.Slot.WEAPON)))
	assert_bool(loadout.equip(a.uid)).is_true()
	assert_bool(loadout.equip(b.uid)).is_true()
	assert_object(loadout.equipped_in(EquipmentLoadout.EquipSlot.WEAPON)).is_same(b)
	assert_bool(loadout.is_equipped(a.uid)).is_false()
	loadout.unequip(EquipmentLoadout.EquipSlot.WEAPON)
	assert_int(loadout.stash_items().size()).is_equal(2)


func test_unknown_uid_and_remove() -> void:
	var loadout := EquipmentLoadout.new()
	assert_bool(loadout.equip(99)).is_false()
	var a := loadout.add(ItemInstance.new(_base(&"amulet", EquipmentData.Slot.ACCESSORY)))
	loadout.equip(a.uid)
	loadout.remove(a.uid)
	assert_array(loadout.equipped_items()).is_empty()
	assert_array(loadout.all_items()).is_empty()


func test_instance_dict_roundtrip() -> void:
	var catalog: EquipmentCatalog = load("res://data/equipment/equipment_catalog.tres")
	var item := ItemInstance.new(catalog.find(&"gel_wand"), 2)
	var affix := StatModifier.new()
	affix.stat = UpgradeData.Stat.FIRE_RATE
	affix.amount = 1.15
	affix.is_multiplier = true
	item.affixes.append(affix)
	item.ability = load("res://data/abilities/arcane_ring.tres")
	var back := ItemInstance.from_dict(item.to_dict(), catalog, load("res://data/abilities/ability_catalog.tres"))
	assert_str(String(back.base.id)).is_equal("gel_wand")
	assert_int(back.rarity).is_equal(2)
	assert_float(back.affixes[0].amount).is_equal_approx(1.15, 0.0001)
	assert_str(String(back.ability.id)).is_equal("arcane_ring")
	assert_int(back.modifiers().size()).is_equal(item.base.modifiers.size() + 1)
	assert_object(ItemInstance.from_dict({"base": "removed"}, catalog, null)).is_null()
