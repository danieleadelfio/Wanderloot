extends GdUnitTestSuite
## Re Slime (M8): dati coerenti con il sistema boss e con la Cripta.

const PLAYER_SPEED: float = 220.0


func test_crypt_has_king_slime_20s_after_extraction() -> void:
	var crypt: ArenaData = load("res://data/arenas/crypt.tres")
	assert_bool(crypt.has_boss()).is_true()
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


## Bug (M13, #86): la raffica a ventaglio (M12, #40) toglieva il cerchio di preavviso sul boss e non
## restava altro segnale dell'attacco in arrivo. Ripristinato: ogni attacco senza un proprio telegraph
## dedicato (LEAP_SLAM/STOMP/RAIN/CHARGE hanno il loro) mostra il cerchio di preavviso sul boss.
func test_every_attack_without_its_own_ground_telegraph_shows_the_windup_circle() -> void:
	var data: BossData = load("res://data/bosses/king_slime.tres")
	var own_telegraph: Array[BossAttack.Kind] = [BossAttack.Kind.LEAP_SLAM, BossAttack.Kind.STOMP, BossAttack.Kind.RAIN, BossAttack.Kind.CHARGE]
	for attack in data.attacks:
		if not own_telegraph.has(attack.kind):
			assert_bool(attack.show_windup).override_failure_message("nessun preavviso per: " + attack.display_name).is_true()
