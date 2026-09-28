extends GdUnitTestSuite
## Sistema boss esteso (M11.3): vita x2, pioggia di cerchi, corsia della carica, evocazione, urlo, catena di salti.

var _boss: Boss
var _target: Node2D


func before_test() -> void:
	_boss = auto_free(load("res://scenes/run/Bosses/KingSlime/KingSlime.tscn").instantiate())
	_target = auto_free(Node2D.new())
	add_child(_target)
	_target.global_position = Vector2(300, 0)
	add_child(_boss)
	_boss.target = _target
	_boss.set_physics_process(false)


func test_boss_hp_is_doubled() -> void:
	assert_int(_boss.health.max_hp).is_equal(_boss.data.max_hp * 2)


func test_rain_marks_many_circles() -> void:
	var attack := BossAttack.new()
	attack.kind = BossAttack.Kind.RAIN
	attack.rain_count = 5
	attack.radius = 60.0
	_boss.start_attack(attack)
	assert_int(_boss.danger_zones().size()).is_equal(5)
	# Il primo cerchio e' sul player.
	assert_vector(Vector2(_boss.danger_zones()[0].x, _boss.danger_zones()[0].y)).is_equal(Vector2(300, 0))


func test_charge_shows_a_lane_towards_the_player() -> void:
	var attack := BossAttack.new()
	attack.kind = BossAttack.Kind.CHARGE
	attack.charge_distance = 320.0
	_boss.start_attack(attack)
	var zones := _boss.danger_zones()
	assert_int(zones.size()).is_equal(5)
	for zone in zones:
		assert_float(zone.y).is_equal_approx(_boss.global_position.y, 0.5)
		assert_float(zone.x).is_greater(_boss.global_position.x)


func test_summon_and_scream_emit_requests() -> void:
	var calls := [0, 0]
	_boss.summon_requested.connect(func(_s: PackedScene, count: int, _at: Vector2) -> void: calls[0] += count)
	_boss.scream_requested.connect(func() -> void: calls[1] += 1)
	var summon := BossAttack.new()
	summon.kind = BossAttack.Kind.SUMMON
	summon.summon_scene = load("res://scenes/run/Enemies/Ghoul/Ghoul.tscn")
	summon.summon_count = 4
	_boss.start_attack(summon)
	_boss._execute()
	var scream := BossAttack.new()
	scream.kind = BossAttack.Kind.SCREAM
	_boss.start_attack(scream)
	_boss._execute()
	assert_array(calls).is_equal([4, 1])


func test_chain_leap_repeats_before_recovering() -> void:
	var leap := BossAttack.new()
	leap.kind = BossAttack.Kind.LEAP_SLAM
	leap.repeats = 3
	_boss.start_attack(leap)
	for i in 2:
		_boss._execute()
		_boss._land()
		assert_int(_boss.state).is_equal(Boss.State.WINDUP)
	_boss._execute()
	_boss._land()
	assert_int(_boss.state).is_equal(Boss.State.RECOVER)


func _chain_leap() -> BossAttack:
	var leap := BossAttack.new()
	leap.kind = BossAttack.Kind.LEAP_SLAM
	leap.repeats = 3
	leap.radius = 100.0
	leap.damage = 200
	leap.telegraph_time = 0.8
	leap.leap_time = 0.35
	leap.repeat_interval = 0.55
	return leap


## Bug (M13, #86, video Regina dei Ghoul): all'atterraggio di un balzo a catena il cerchio successivo
## (centrato sul player) riusava lo stesso telegraph mentre stava infliggendo l'impulso di danno:
## colpiva subito il player anche fuori dal cerchio in cui il boss era atterrato.
func test_chain_leap_next_circle_is_harmless_and_landing_pulse_stays_on_the_old_circle() -> void:
	_boss.start_attack(_chain_leap())
	var first: Telegraph = _boss._impact
	first._process(1.2)  # fine del preavviso: impulso di danno sul primo cerchio
	assert_bool(first._hitbox.active).is_true()
	_boss._execute()
	_target.global_position = Vector2(700, 0)  # il player e' scappato dal cerchio
	_boss._land()
	# L'impulso resta sul cerchio d'atterraggio, non segue il player.
	assert_vector(first.global_position).is_equal(Vector2(300, 0))
	assert_bool(first._hitbox.active).is_true()
	# Il nuovo cerchio sul player e' un altro telegraph e nasce innocuo.
	var next: Telegraph = _boss._leap_telegraph
	assert_object(next).is_not_same(first)
	assert_vector(next.global_position).is_equal(Vector2(700, 0))
	assert_bool(next.is_running()).is_true()
	assert_bool(next._hitbox.active).is_false()


## Ogni balzo della catena alterna i due telegraph, anche al terzo.
func test_chain_leap_alternates_telegraphs() -> void:
	_boss.start_attack(_chain_leap())
	var seen: Array[Telegraph] = [_boss._leap_telegraph]
	for i in 2:
		_boss._execute()
		_boss._land()
		seen.append(_boss._leap_telegraph)
	assert_object(seen[0]).is_not_same(seen[1])
	assert_object(seen[1]).is_not_same(seen[2])
	assert_object(seen[0]).is_same(seen[2])


## Qualunque telegraph riavviato (anche fuori dai balzi, es. pestone) non tiene la Hitbox accesa.
func test_restarted_telegraph_never_keeps_a_live_hitbox() -> void:
	var telegraph: Telegraph = auto_free(load("res://scenes/run/Telegraph/Telegraph.tscn").instantiate())
	add_child(telegraph)
	telegraph.start(Vector2.ZERO, 80.0, 0.1, 100)
	telegraph._process(0.2)
	assert_bool(telegraph._hitbox.active).is_true()
	telegraph.start(Vector2(500, 0), 80.0, 1.0, 100)
	assert_bool(telegraph._hitbox.active).is_false()
