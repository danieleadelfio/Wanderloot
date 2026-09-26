extends GdUnitTestSuite
## Rescale baseline danno/HP/exp x100 (M12, #86): guardia contro un futuro edit che silenziosamente
## riporti un .tres o un default di script alla vecchia scala (i numeri sensati sono ora centinaia/migliaia,
## non unita'). Gli importi flat degli upgrade/affix/equip restano invariati (per scelta esplicita): pesano
## una % piu' piccola sulla base piu' grande, e' il punto di questo rescale.

func test_player_base_hp_is_rescaled() -> void:
	var stats: PlayerStats = load("res://data/player/player_default.tres")
	assert_int(stats.max_hp).is_equal(1000)


func test_starter_wand_damage_is_rescaled() -> void:
	var weapon: WeaponData = load("res://data/weapons/starter_wand.tres")
	assert_int(weapon.damage).is_equal(100)


func test_level_curve_base_exp_is_rescaled() -> void:
	var curve: LevelCurve = load("res://data/run/level_curve.tres")
	assert_int(curve.base_exp).is_equal(500)


func test_enemy_data_script_defaults_are_rescaled() -> void:
	var data := EnemyData.new()
	assert_int(data.max_hp).is_equal(300)
	assert_int(data.contact_damage).is_equal(100)
	assert_int(data.exp_reward).is_equal(100)
	assert_int(data.rage_damage_bonus).is_equal(100)


func test_boss_data_is_rescaled() -> void:
	var boss: BossData = load("res://data/bosses/bone_colossus.tres")
	assert_int(boss.max_hp).is_equal(60000)
	assert_int(boss.contact_damage).is_equal(300)
	assert_int(boss.exp_reward).is_equal(7000)


func test_heart_consumable_heal_is_rescaled() -> void:
	var heart: ConsumableData = load("res://data/consumables/heart.tres")
	assert_float(heart.amount).is_equal_approx(200.0, 0.01)
