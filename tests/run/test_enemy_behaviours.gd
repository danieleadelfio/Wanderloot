extends GdUnitTestSuite
## Nemici dell'Ossario: distanza di sicurezza dell'arciere, tiro con cooldown, inseguimento del ghoul.

const TICK: float = 0.1


func test_keep_distance_approaches_retreats_and_strafes() -> void:
	assert_vector(EnemyMovement.keep_distance(Vector2(500, 0), 280.0)).is_equal(Vector2.RIGHT)
	assert_vector(EnemyMovement.keep_distance(Vector2(100, 0), 280.0)).is_equal(Vector2.LEFT)
	var strafe := EnemyMovement.keep_distance(Vector2(280, 0), 280.0)
	assert_float(absf(strafe.x)).is_less(0.001)
	assert_float(absf(strafe.y)).is_greater(0.0)


func _spawn(scene_path: String, target_at: Vector2) -> Enemy:
	var target: Node2D = auto_free(Node2D.new())
	add_child(target)
	target.position = target_at
	var enemy: Enemy = auto_free(load(scene_path).instantiate())
	add_child(enemy)
	enemy.activate(Vector2.ZERO)
	enemy.target = target
	enemy.set_physics_process(false)
	return enemy


func test_archer_shoots_on_cooldown_when_in_range() -> void:
	var archer := _spawn("res://scenes/run/Enemies/SkeletonArcher/SkeletonArcher.tscn", Vector2(300, 0))
	var shots: Array[Vector2] = []
	archer.shot_requested.connect(func(_o: Vector2, d: Vector2, _w: WeaponData) -> void: shots.append(d))
	for i in 40:
		archer._physics_process(TICK)
	var expected := 1 + int(4.0 / archer.data.attack_interval)
	assert_int(shots.size()).is_between(expected - 1, expected)
	assert_float(shots[0].x).is_greater(0.9)


func test_archer_does_not_shoot_out_of_range() -> void:
	var archer := _spawn("res://scenes/run/Enemies/SkeletonArcher/SkeletonArcher.tscn", Vector2(2000, 0))
	var shots := [0]
	archer.shot_requested.connect(func(_o: Vector2, _d: Vector2, _w: WeaponData) -> void: shots[0] += 1)
	for i in 30:
		archer._physics_process(TICK)
	assert_int(shots[0]).is_equal(0)


func test_ghoul_chases_fast() -> void:
	var ghoul := _spawn("res://scenes/run/Enemies/Ghoul/Ghoul.tscn", Vector2(400, 0))
	ghoul._physics_process(TICK)
	assert_float(ghoul.velocity.x).is_equal_approx(ghoul.data.move_speed, 0.5)
	assert_float(ghoul.data.move_speed).is_greater(load("res://data/enemies/enemy_basic.tres").move_speed)


func test_skeleton_closet_is_invulnerable_to_player_damage() -> void:
	# Evento di sola schivata (M12, #86): non deve poter essere ucciso dal player, i proiettili lo
	# attraversano (Hurtbox.immune, gia' usato per l'invulnerabilita' dello scatto del Passo d'ombra).
	var skeleton := _spawn("res://scenes/run/Enemies/SkeletonCloset/SkeletonCloset.tscn", Vector2(300, 0))
	assert_bool(skeleton.data.invulnerable).is_true()
	var hurtbox := skeleton.get_node("%Hurtbox") as Hurtbox
	assert_bool(hurtbox.immune).is_true()
	var hitbox := Hitbox.new()
	hitbox.damage = 99
	hitbox.active = true
	var hp_before := skeleton.health.current
	hurtbox._try_hit(hitbox)
	assert_int(skeleton.health.current).is_equal(hp_before)
	hitbox.free()
