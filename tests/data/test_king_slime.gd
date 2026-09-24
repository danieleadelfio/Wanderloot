extends GdUnitTestSuite
## Re Slime (M8): dati coerenti con il sistema boss e con la Cripta.

const PLAYER_SPEED: float = 220.0


func test_crypt_has_king_slime_20s_after_extraction() -> void:
	var crypt: ArenaData = load("res://data/arenas/crypt.tres")
	assert_object(crypt.boss_scene).is_not_null()
	assert_float(crypt.boss_delay).is_equal(20.0)


func test_every_area_attack_is_escapable() -> void:
	var data: BossData = load("res://data/bosses/king_slime.tres")
	assert_int(data.attacks.size()).is_greater_equal(3)
	for attack in data.attacks:
		if attack.kind == BossAttack.Kind.LEAP_SLAM:
			# Anche dal centro del cerchio il player a velocita' base esce prima dell'impatto.
			var escape_time := attack.radius / PLAYER_SPEED
			assert_float(attack.telegraph_time + attack.leap_time).is_greater(escape_time * 1.5)


func test_phase_two_attacks_exist_and_drops_are_guaranteed() -> void:
	var data: BossData = load("res://data/bosses/king_slime.tres")
	assert_bool(data.attacks.any(func(a: BossAttack) -> bool: return a.min_phase == 2)).is_true()
	for entry in data.drops:
		assert_float(entry.chance).is_equal(1.0)
