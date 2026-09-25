extends GdUnitTestSuite
## Potenza dell'equip -> livello arena (M12, #86): formula, moltiplicatori per livello 1-5 e
## composizione con overtime (moltiplicativa) e Pentagramma di sangue (additiva sui boss).

const GEL_WAND: EquipmentData = preload("res://data/equipment/gel_wand.tres")


func _items(rarity: int, count: int) -> Array[ItemInstance]:
	var result: Array[ItemInstance] = []
	for i in count:
		var item := ItemInstance.new(GEL_WAND)
		item.rarity = rarity
		result.append(item)
	return result


func test_no_equipment_is_level_1() -> void:
	assert_int(ArenaLevel.level_for([] as Array[ItemInstance])).is_equal(1)


func test_fewer_than_4_pieces_is_level_1() -> void:
	assert_int(ArenaLevel.level_for(_items(0, 3))).is_equal(1)


func test_4_common_is_level_2() -> void:
	assert_int(ArenaLevel.level_for(_items(0, 4))).is_equal(2)


func test_4_uncommon_is_level_3() -> void:
	assert_int(ArenaLevel.level_for(_items(1, 4))).is_equal(3)


func test_4_rare_is_level_4() -> void:
	assert_int(ArenaLevel.level_for(_items(2, 4))).is_equal(4)


func test_4_super_rare_is_level_5() -> void:
	assert_int(ArenaLevel.level_for(_items(3, 4))).is_equal(5)


func test_4_legendary_raw_level_is_6_but_clamped_to_5() -> void:
	assert_int(ArenaLevel.raw_level(_items(4, 4))).is_equal(6)
	assert_int(ArenaLevel.level_for(_items(4, 4))).is_equal(ArenaLevel.MAX_LEVEL)


func test_4_mythic_raw_level_is_7_but_clamped_to_5() -> void:
	assert_int(ArenaLevel.raw_level(_items(5, 4))).is_equal(7)
	assert_int(ArenaLevel.level_for(_items(5, 4))).is_equal(ArenaLevel.MAX_LEVEL)


func test_mixed_rarities_take_the_highest_satisfied_threshold() -> void:
	# 4 pezzi >= Comune (soddisfa T=1) e 4 >= Non comune tra questi (soddisfa T=2): livello = 3.
	var items: Array[ItemInstance] = []
	items.append_array(_items(0, 2))
	items.append_array(_items(1, 4))
	assert_int(ArenaLevel.level_for(items)).is_equal(3)


func test_3_pieces_of_a_rarity_do_not_satisfy_its_threshold() -> void:
	assert_int(ArenaLevel.level_for(_items(3, 3))).is_equal(1)


func test_enemy_hp_multiplier_is_1_5_per_level_above_1() -> void:
	assert_float(ArenaLevel.enemy_hp_multiplier(1)).is_equal_approx(1.0, 0.001)
	assert_float(ArenaLevel.enemy_hp_multiplier(2)).is_equal_approx(1.5, 0.001)
	assert_float(ArenaLevel.enemy_hp_multiplier(3)).is_equal_approx(2.25, 0.001)
	assert_float(ArenaLevel.enemy_hp_multiplier(4)).is_equal_approx(3.375, 0.001)
	assert_float(ArenaLevel.enemy_hp_multiplier(5)).is_equal_approx(5.0625, 0.001)


func test_spawn_rate_multiplier_is_10_percent_per_level_above_1() -> void:
	assert_float(ArenaLevel.spawn_rate_multiplier(1)).is_equal_approx(1.0, 0.001)
	assert_float(ArenaLevel.spawn_rate_multiplier(2)).is_equal_approx(1.1, 0.001)
	assert_float(ArenaLevel.spawn_rate_multiplier(3)).is_equal_approx(1.2, 0.001)
	assert_float(ArenaLevel.spawn_rate_multiplier(4)).is_equal_approx(1.3, 0.001)
	assert_float(ArenaLevel.spawn_rate_multiplier(5)).is_equal_approx(1.4, 0.001)


func test_boss_bonus_is_1_per_level_above_1() -> void:
	for level in 5:
		assert_int(ArenaLevel.boss_bonus(level + 1)).is_equal(level)


func test_out_of_range_levels_are_clamped_before_scaling() -> void:
	assert_float(ArenaLevel.enemy_hp_multiplier(0)).is_equal_approx(1.0, 0.001)
	assert_float(ArenaLevel.enemy_hp_multiplier(99)).is_equal_approx(ArenaLevel.enemy_hp_multiplier(5), 0.001)
	assert_int(ArenaLevel.boss_bonus(99)).is_equal(ArenaLevel.boss_bonus(5))


func test_max_drop_tier_unlocks_one_rarity_per_level() -> void:
	assert_int(ArenaLevel.max_drop_tier(1, 4)).is_equal(0)
	assert_int(ArenaLevel.max_drop_tier(2, 4)).is_equal(1)
	assert_int(ArenaLevel.max_drop_tier(3, 4)).is_equal(2)
	assert_int(ArenaLevel.max_drop_tier(4, 4)).is_equal(3)
	assert_int(ArenaLevel.max_drop_tier(5, 4)).is_equal(4)


func test_max_drop_tier_never_exceeds_arena_own_ceiling() -> void:
	# Un'arena col tetto piu' basso del livello (es. max_tier=1) non sale mai oltre, anche a livello 5.
	assert_int(ArenaLevel.max_drop_tier(5, 1)).is_equal(1)
	assert_int(ArenaLevel.max_drop_tier(3, 1)).is_equal(1)


## Composizione col Pentagramma di sangue (additivo: arena.boss_count + extra pentagramma + bonus livello),
## per tutti e 5 i livelli, con e senza i boss del Pentagramma.
func test_boss_count_composes_additively_with_pentagram_for_all_levels() -> void:
	var base_boss_count := 1
	for level in range(1, ArenaLevel.MAX_LEVEL + 1):
		var without_pentagram := base_boss_count + 0 + ArenaLevel.boss_bonus(level)
		var with_pentagram := base_boss_count + 1 + ArenaLevel.boss_bonus(level)
		assert_int(without_pentagram).is_equal(base_boss_count + level - 1)
		assert_int(with_pentagram).is_equal(without_pentagram + 1)


## Composizione con l'overtime (moltiplicativa su vita e ritmo di spawn), per tutti e 5 i livelli,
## con e senza overtime attivo (overtime a x1.0 = nessun bonus, tipico livello overtime 0).
func test_hp_and_rate_compose_multiplicatively_with_overtime_for_all_levels() -> void:
	var overtime_hp_off := 1.0
	var overtime_hp_on := 2.0  # es. overtime livello 1 con hp_bonus 1.0 -> 1.0 + 1.0*1
	var overtime_rate_off := 1.0
	var overtime_rate_on := 1.5
	for level in range(1, ArenaLevel.MAX_LEVEL + 1):
		var level_hp := ArenaLevel.enemy_hp_multiplier(level)
		var level_rate := ArenaLevel.spawn_rate_multiplier(level)
		assert_float(level_hp * overtime_hp_off).is_equal_approx(level_hp, 0.001)
		assert_float(level_hp * overtime_hp_on).is_equal_approx(level_hp * 2.0, 0.001)
		assert_float(level_rate * overtime_rate_off).is_equal_approx(level_rate, 0.001)
		assert_float(level_rate * overtime_rate_on).is_equal_approx(level_rate * 1.5, 0.001)
