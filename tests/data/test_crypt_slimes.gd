extends GdUnitTestSuite
## Slime della Cripta: celeste base; verde e viola vita x2 stessa velocita' e sparano; grigio vita x4 velocita' /2.


func test_crypt_slime_family() -> void:
	var crypt: ArenaData = load("res://data/arenas/crypt.tres")
	assert_int(crypt.enemies.size()).is_equal(4)
	var base: EnemyData = load("res://data/enemies/enemy_basic.tres")
	var toxic: EnemyData = load("res://data/enemies/slime_toxic.tres")
	var void_slime: EnemyData = load("res://data/enemies/slime_void.tres")
	var stone: EnemyData = load("res://data/enemies/slime_stone.tres")
	for shooter in [toxic, void_slime]:
		assert_int(shooter.max_hp).is_equal(base.max_hp * 2)
		assert_float(shooter.move_speed).is_equal(base.move_speed)
		assert_object(shooter.ranged_weapon).is_not_null()
	assert_int(stone.max_hp).is_equal(base.max_hp * 4)
	assert_float(stone.move_speed).is_equal(base.move_speed / 2.0)
	assert_object(stone.ranged_weapon).is_null()
	assert_float(toxic.ranged_weapon.poison_duration).is_equal(4.5)
	assert_float(void_slime.ranged_weapon.grow_after).is_greater(0.0)
	# I celesti restano i piu' frequenti.
	for i in range(1, 4):
		assert_float(crypt.enemies[i].weight).is_less(crypt.enemies[0].weight)


func test_void_orb_grows_and_pulls() -> void:
	var pool: ProjectilePool = auto_free(ProjectilePool.new())
	pool.projectile_scene = load("res://scenes/run/Projectile/EnemyProjectile.tscn")
	add_child(pool)
	var player: Player = auto_free(load("res://scenes/run/Player/Player.tscn").instantiate())
	add_child(player)
	pool.pull_target = player
	pool.spawn(Vector2(-330, 0), Vector2.RIGHT, load("res://data/weapons/void_orb.tres"))
	var orb: Projectile = null
	for child in pool.get_children():
		if child is Projectile and child.visible:
			orb = child
	for i in 70:
		orb._physics_process(1.0 / 60.0)
	assert_bool(orb._grown).is_true()
	assert_float(player._pull.x).is_less(0.0)
