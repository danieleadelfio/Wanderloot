extends GdUnitTestSuite
## Contatore su equip (M12, #86): era "N. proiettili" (PROJECTILE_COUNT) su Arma/Anello, intaccava
## l'attacco base come il Ventaglio; unificato col Contatore di run (COUNT_BONUS, solo abilita'),
## ora disponibile solo sull'Amuleto.


func test_counter_affix_is_count_bonus_amulet_only() -> void:
	var affixes: AffixTable = load("res://data/equipment/affix_table.tres")
	var counter := affixes.rolls.filter(func(r: AffixRoll) -> bool: return r.stat == UpgradeData.Stat.COUNT_BONUS)
	assert_int(counter.size()).is_equal(1)
	var roll: AffixRoll = counter[0]
	assert_bool(roll.allows(EquipmentData.Slot.ACCESSORY)).is_true()
	assert_bool(roll.allows(EquipmentData.Slot.WEAPON)).is_false()
	assert_bool(roll.allows(EquipmentData.Slot.RING)).is_false()


func test_no_affix_touches_base_weapon_projectile_count() -> void:
	var affixes: AffixTable = load("res://data/equipment/affix_table.tres")
	assert_bool(affixes.rolls.any(func(r: AffixRoll) -> bool: return r.stat == UpgradeData.Stat.PROJECTILE_COUNT)).is_false()
