extends GdUnitTestSuite
## Righe delle statistiche (M9): valori letti da stats e arma, percentuali dei moltiplicatori.
## equip_rows() (M12, #86): base/bonus equip/finale a 3 numeri.


func test_rows_reflect_stats_and_weapon() -> void:
	var stats := PlayerStats.new()
	stats.max_hp = 7
	stats.exp_multiplier = 1.25
	var weapon := WeaponData.new()
	weapon.damage = 3
	weapon.fire_rate = 5.5
	var rows := StatSheet.rows(stats, weapon)
	var by_label := {}
	for row in rows:
		by_label[row[0]] = row[1]
	assert_str(by_label["STAT_MAX_HP"]).is_equal("7")
	assert_str(by_label["STAT_DAMAGE"]).is_equal("3")
	assert_str(by_label["STAT_FIRE_RATE"]).is_equal("5.5/s")
	assert_str(by_label["STAT_EXP_BONUS"]).is_equal("+25%")
	assert_str(by_label["STAT_DROP_BONUS"]).is_equal("+0%")


func test_upgrade_changes_rows() -> void:
	var stats := PlayerStats.new()
	var weapon := WeaponData.new()
	var before := StatSheet.rows(stats, weapon)
	StatApplier.apply(UpgradeData.Stat.DAMAGE, 2.0, false, stats, weapon)
	var after := StatSheet.rows(stats, weapon)
	assert_str(after[2][1]).is_equal(str(int(before[2][1]) + 2))



func test_equip_rows_bonus_is_percent_of_base() -> void:
	var base_stats := PlayerStats.new()
	var base_weapon := WeaponData.new()
	base_weapon.fire_rate = 4.0
	var stats := base_stats.duplicate()
	var weapon := base_weapon.duplicate()
	var bonus := StatModifier.new()
	bonus.stat = UpgradeData.Stat.FIRE_RATE
	bonus.amount = 1.16
	bonus.is_multiplier = true
	var modifiers: Array[StatModifier] = [bonus]
	StatApplier.apply_modifiers(modifiers, stats, weapon)
	var rows := StatSheet.equip_rows(base_stats, base_weapon, stats, weapon, modifiers)
	var by_label := {}
	for row in rows:
		by_label[row[0]] = row
	var fire_rate_row: PackedStringArray = by_label["STAT_FIRE_RATE"]
	assert_str(fire_rate_row[1]).is_equal("4.0/s")
	assert_str(fire_rate_row[2]).is_equal("+16%")
	assert_str(fire_rate_row[3]).is_equal("4.6/s")


func test_equip_rows_no_bonus_is_empty() -> void:
	var base_stats := PlayerStats.new()
	var base_weapon := WeaponData.new()
	var rows := StatSheet.equip_rows(base_stats, base_weapon, base_stats.duplicate(), base_weapon.duplicate(), [] as Array[StatModifier])
	for row in rows:
		assert_str(row[2]).is_equal("")


func test_equip_rows_zero_base_shows_absolute_delta() -> void:
	var base_stats := PlayerStats.new()
	base_stats.invulnerability_time = 0.0
	var base_weapon := WeaponData.new()
	var stats := base_stats.duplicate()
	var weapon := base_weapon.duplicate()
	var bonus := StatModifier.new()
	bonus.stat = UpgradeData.Stat.INVULNERABILITY
	bonus.amount = 0.1
	bonus.is_multiplier = false
	var modifiers: Array[StatModifier] = [bonus]
	StatApplier.apply_modifiers(modifiers, stats, weapon)
	var rows := StatSheet.equip_rows(base_stats, base_weapon, stats, weapon, modifiers)
	var by_label := {}
	for row in rows:
		by_label[row[0]] = row
	var invuln_row: PackedStringArray = by_label["STAT_INVULNERABILITY"]
	assert_str(invuln_row[1]).is_equal("0.00s")
	assert_str(invuln_row[2]).is_equal("+0.10s")
	assert_str(invuln_row[3]).is_equal("0.10s")
