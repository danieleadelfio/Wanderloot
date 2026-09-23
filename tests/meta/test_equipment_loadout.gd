extends GdUnitTestSuite

var _loadout: EquipmentLoadout


func before_test() -> void:
	_loadout = EquipmentLoadout.new()


func test_cannot_equip_what_is_not_owned() -> void:
	assert_bool(_loadout.equip(_item(&"wand", EquipmentData.Slot.WEAPON))).is_false()
	assert_str(String(_loadout.equipped_id(EquipmentData.Slot.WEAPON))).is_empty()


func test_equip_replaces_same_slot_only() -> void:
	for id in [&"wand_a", &"wand_b", &"ring"]:
		_loadout.add_owned(id)
	_loadout.equip(_item(&"wand_a", EquipmentData.Slot.WEAPON))
	_loadout.equip(_item(&"ring", EquipmentData.Slot.ACCESSORY))
	_loadout.equip(_item(&"wand_b", EquipmentData.Slot.WEAPON))

	assert_str(String(_loadout.equipped_id(EquipmentData.Slot.WEAPON))).is_equal("wand_b")
	assert_str(String(_loadout.equipped_id(EquipmentData.Slot.ACCESSORY))).is_equal("ring")
	assert_bool(_loadout.is_equipped(&"wand_a")).is_false()


func test_unequip_and_owned_are_unique() -> void:
	_loadout.add_owned(&"ring")
	_loadout.add_owned(&"ring")
	_loadout.equip(_item(&"ring", EquipmentData.Slot.ACCESSORY))
	_loadout.unequip(EquipmentData.Slot.ACCESSORY)

	assert_array(_loadout.owned_ids()).has_size(1)
	assert_bool(_loadout.is_equipped(&"ring")).is_false()


func _item(id: StringName, slot: EquipmentData.Slot) -> EquipmentData:
	var item := EquipmentData.new()
	item.id = id
	item.slot = slot
	return item
