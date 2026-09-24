extends GdUnitTestSuite
## Tutti i boss (data/bosses/*.tres): moveset con fase 2, drop garantiti, attacchi ad area schivabili,
## evocazioni con nemici dell'arena. L'Ossario ha i suoi boss.

const PLAYER_SPEED: float = 220.0


func _bosses() -> Array[BossData]:
	var result: Array[BossData] = []
	for file in DirAccess.get_files_at("res://data/bosses"):
		if file.ends_with(".tres"):
			result.append(load("res://data/bosses/" + file))
	return result


func test_every_boss_is_complete() -> void:
	for data in _bosses():
		assert_int(data.attacks.size()).override_failure_message(String(data.id)).is_greater_equal(3)
		assert_bool(data.attacks.any(func(a: BossAttack) -> bool: return a.min_phase == 2) or data.phase_two_summon_scene != null).is_true()
		for entry in data.drops:
			assert_float(entry.chance).is_equal(1.0)
		assert_str(tr(data.display_name)).is_not_equal(data.display_name)


func test_area_attacks_are_escapable() -> void:
	for data in _bosses():
		for attack in data.attacks:
			var warning := attack.telegraph_time
			if attack.kind == BossAttack.Kind.LEAP_SLAM:
				warning += attack.leap_time
			if attack.kind in [BossAttack.Kind.LEAP_SLAM, BossAttack.Kind.RAIN, BossAttack.Kind.STOMP]:
				assert_float(warning).override_failure_message("%s/%s" % [data.id, attack.display_name]).is_greater(attack.radius / PLAYER_SPEED * 1.2)


func test_ossuary_summons_use_ossuary_enemies() -> void:
	var ossuary: ArenaData = load("res://data/arenas/ossuary.tres")
	assert_int(ossuary.boss_scenes.size()).is_greater_equal(1)
	var scenes: Array = ossuary.enemies.map(func(s: EnemySpawn) -> PackedScene: return s.scene)
	for scene in ossuary.boss_scenes:
		var boss: Boss = scene.instantiate()
		for attack in boss.data.attacks:
			if attack.kind == BossAttack.Kind.SUMMON:
				assert_bool(scenes.has(attack.summon_scene)).is_true()
		if boss.data.phase_two_summon_scene:
			assert_bool(scenes.has(boss.data.phase_two_summon_scene)).is_true()
		boss.free()
