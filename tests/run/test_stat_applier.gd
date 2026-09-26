extends GdUnitTestSuite
## Equip e upgrade passano da StatApplier: si applicano alle copie di run, mai ai .tres base.


func test_additive_and_multiplier_modifiers() -> void:
	var stats := PlayerStats.new()
	var weapon := WeaponData.new()
	stats.move_speed = 200.0
	weapon.damage = 1
	weapon.fire_rate = 4.0

	StatApplier.apply(UpgradeData.Stat.DAMAGE, 2.0, false, stats, weapon)
	StatApplier.apply(UpgradeData.Stat.FIRE_RATE, 1.25, true, stats, weapon)
	StatApplier.apply(UpgradeData.Stat.MOVE_SPEED, 1.1, true, stats, weapon)

	assert_int(weapon.damage).is_equal(3)
	assert_float(weapon.fire_rate).is_equal_approx(5.0, 0.001)
	assert_float(stats.move_speed).is_equal_approx(220.0, 0.001)


func test_max_hp_never_below_one() -> void:
	var stats := PlayerStats.new()
	stats.max_hp = 2
	StatApplier.apply(UpgradeData.Stat.MAX_HP, -5.0, false, stats, WeaponData.new())
	assert_int(stats.max_hp).is_equal(1)


func test_equipment_applies_to_copies_and_leaves_base_resources_untouched() -> void:
	var base_stats: PlayerStats = load("res://data/player/player_default.tres")
	var base_weapon: WeaponData = load("res://data/weapons/starter_wand.tres")
	var base_hp := base_stats.max_hp
	var base_damage := base_weapon.damage
	var stats: PlayerStats = base_stats.duplicate()
	var weapon: WeaponData = base_weapon.duplicate()
	var modifiers: Array[StatModifier] = []
	for path in ["res://data/equipment/gel_wand.tres", "res://data/equipment/core_amulet.tres"]:
		modifiers.append_array(ItemInstance.new(load(path)).modifiers())

	StatApplier.apply_modifiers(modifiers, stats, weapon)

	# gel_wand: +10% danno; core_amulet: +20% HP (M12, #86: equip fisso in percentuale, non piu' flat).
	assert_int(weapon.damage).is_equal(roundi(base_damage * 1.1))
	assert_int(stats.max_hp).is_equal(roundi(base_hp * 1.2))
	assert_int(base_weapon.damage).is_equal(base_damage)
	assert_int(base_stats.max_hp).is_equal(base_hp)


func test_projectile_speed_and_lifetime_modifiers() -> void:
	# Gittata (PROJECTILE_SPEED) e Persistenza (PROJECTILE_LIFETIME): non piu' ottenibili in game
	# (M12, #86 - weight=0 nei pool), ma il branch di StatApplier resta e va testato.
	var stats := PlayerStats.new()
	var weapon := WeaponData.new()
	weapon.projectile_speed = 400.0
	weapon.projectile_lifetime = 1.5

	StatApplier.apply(UpgradeData.Stat.PROJECTILE_SPEED, 50.0, false, stats, weapon)
	StatApplier.apply(UpgradeData.Stat.PROJECTILE_LIFETIME, 1.2, true, stats, weapon)

	assert_float(weapon.projectile_speed).is_equal_approx(450.0, 0.001)
	assert_float(weapon.projectile_lifetime).is_equal_approx(1.8, 0.001)


func test_pickup_radius_modifier() -> void:
	var stats := PlayerStats.new()
	stats.pickup_radius = 90.0
	StatApplier.apply(UpgradeData.Stat.PICKUP_RADIUS, 20.0, false, stats, WeaponData.new())
	assert_float(stats.pickup_radius).is_equal_approx(110.0, 0.001)


func test_exp_gain_modifier() -> void:
	# L'exp_multiplier e' cio' che moltiplica l'exp della singola gemma in Arena._on_exp_collected.
	var stats := PlayerStats.new()
	assert_float(stats.exp_multiplier).is_equal_approx(1.0, 0.001)
	StatApplier.apply(UpgradeData.Stat.EXP_GAIN, 1.3, true, stats, WeaponData.new())
	assert_float(stats.exp_multiplier).is_equal_approx(1.3, 0.001)

	# Formula di applicazione alla singola gemma (Arena._on_exp_collected): amount * exp_multiplier.
	var gem_amount := 5
	var gained := floori(gem_amount * stats.exp_multiplier)
	assert_int(gained).is_equal(6)


func test_drop_chance_modifier() -> void:
	var stats := PlayerStats.new()
	stats.drop_chance_multiplier = 1.0
	StatApplier.apply(UpgradeData.Stat.DROP_CHANCE, 1.25, true, stats, WeaponData.new())
	assert_float(stats.drop_chance_multiplier).is_equal_approx(1.25, 0.001)


func test_invulnerability_modifier_never_below_zero() -> void:
	var stats := PlayerStats.new()
	stats.invulnerability_time = 0.8
	StatApplier.apply(UpgradeData.Stat.INVULNERABILITY, 0.2, false, stats, WeaponData.new())
	assert_float(stats.invulnerability_time).is_equal_approx(1.0, 0.001)

	StatApplier.apply(UpgradeData.Stat.INVULNERABILITY, -5.0, false, stats, WeaponData.new())
	assert_float(stats.invulnerability_time).is_equal_approx(0.0, 0.001)


func test_knockback_modifier() -> void:
	var weapon := WeaponData.new()
	weapon.knockback = 100.0
	StatApplier.apply(UpgradeData.Stat.KNOCKBACK, 50.0, false, PlayerStats.new(), weapon)
	assert_float(weapon.knockback).is_equal_approx(150.0, 0.001)


func test_projectile_count_modifier() -> void:
	var stats := PlayerStats.new()
	var weapon := WeaponData.new()
	weapon.projectile_count = 1
	StatApplier.apply(UpgradeData.Stat.PROJECTILE_COUNT, 1.0, false, stats, weapon)
	assert_int(weapon.projectile_count).is_equal(2)


func test_projectile_count_is_not_scaled_by_count_bonus() -> void:
	# Il Contatore (COUNT_BONUS) tocca solo le abilita' (M12, #86): il Ventaglio (PROJECTILE_COUNT)
	# sull'attacco base non ne beneficia piu'.
	var stats := PlayerStats.new()
	var weapon := WeaponData.new()
	weapon.projectile_count = 1
	stats.count_bonus = 2

	StatApplier.apply(UpgradeData.Stat.PROJECTILE_COUNT, 1.0, false, stats, weapon)

	assert_int(weapon.projectile_count).is_equal(2)


func test_projectile_count_never_below_one() -> void:
	var stats := PlayerStats.new()
	var weapon := WeaponData.new()
	weapon.projectile_count = 1
	StatApplier.apply(UpgradeData.Stat.PROJECTILE_COUNT, -5.0, false, stats, weapon)
	assert_int(weapon.projectile_count).is_equal(1)


func test_count_bonus_modifier_updates_stats_but_not_weapon_projectile_count() -> void:
	# M12, #86: Contatore non tocca piu' l'attacco base, solo stats.count_bonus (letto dalle abilita').
	var stats := PlayerStats.new()
	var weapon := WeaponData.new()
	weapon.projectile_count = 3
	stats.count_bonus = 0

	StatApplier.apply(UpgradeData.Stat.COUNT_BONUS, 1.0, false, stats, weapon)

	assert_int(stats.count_bonus).is_equal(1)
	assert_int(weapon.projectile_count).is_equal(3)


func test_pierce_modifier_never_below_zero() -> void:
	var weapon := WeaponData.new()
	weapon.pierce = 1
	StatApplier.apply(UpgradeData.Stat.PIERCE, 2.0, false, PlayerStats.new(), weapon)
	assert_int(weapon.pierce).is_equal(3)

	StatApplier.apply(UpgradeData.Stat.PIERCE, -10.0, false, PlayerStats.new(), weapon)
	assert_int(weapon.pierce).is_equal(0)

func test_mana_regen_modifier_additive() -> void:
	var stats := PlayerStats.new()
	stats.mana_regen = 6.0
	StatApplier.apply(UpgradeData.Stat.MANA_REGEN, 2.0, false, stats, WeaponData.new())
	assert_float(stats.mana_regen).is_equal_approx(8.0, 0.001)


func test_mana_regen_modifier_never_below_zero() -> void:
	var stats := PlayerStats.new()
	stats.mana_regen = 1.0
	StatApplier.apply(UpgradeData.Stat.MANA_REGEN, -10.0, false, stats, WeaponData.new())
	assert_float(stats.mana_regen).is_equal_approx(0.0, 0.001)
