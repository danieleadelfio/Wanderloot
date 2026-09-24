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
