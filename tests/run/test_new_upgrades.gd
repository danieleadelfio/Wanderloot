extends GdUnitTestSuite
## Nuovi potenziamenti M5: cumulabili senza tetto, ventaglio, perforazione, fortuna.


func test_new_stats_stack_without_cap() -> void:
	var stats := PlayerStats.new()
	var weapon := WeaponData.new()
	for i in 10:
		StatApplier.apply(UpgradeData.Stat.PROJECTILE_COUNT, 1.0, false, stats, weapon)
		StatApplier.apply(UpgradeData.Stat.PIERCE, 1.0, false, stats, weapon)
		StatApplier.apply(UpgradeData.Stat.RICOCHET, 1.0, false, stats, weapon)
		StatApplier.apply(UpgradeData.Stat.EXP_GAIN, 0.15, false, stats, weapon)
		StatApplier.apply(UpgradeData.Stat.PICKUP_RADIUS, 1.3, true, stats, weapon)
	assert_int(weapon.projectile_count).is_equal(11)
	assert_int(weapon.pierce).is_equal(10)
	assert_int(weapon.ricochet_bounces).is_equal(10)
	assert_float(stats.exp_multiplier).is_equal_approx(2.5, 0.001)
	assert_float(stats.pickup_radius).is_greater(90.0 * 13.0)


func test_multishot_fires_a_centered_fan() -> void:
	var weapon: Weapon = auto_free(Weapon.new())
	weapon.data = WeaponData.new()
	weapon.data.projectile_count = 3
	weapon.data.spread_degrees = 10.0
	add_child(weapon)
	weapon.set_physics_process(false)
	var directions: Array[Vector2] = []
	weapon.fired.connect(func(_o: Vector2, d: Vector2, _w: WeaponData) -> void: directions.append(d))
	assert_int(weapon.try_fire(Vector2.RIGHT)).is_equal(1)
	assert_int(directions.size()).is_equal(3)
	assert_float(rad_to_deg(directions[0].angle())).is_equal_approx(-10.0, 0.01)
	assert_float(rad_to_deg(directions[1].angle())).is_equal_approx(0.0, 0.01)
	assert_float(rad_to_deg(directions[2].angle())).is_equal_approx(10.0, 0.01)


func test_huge_fan_is_compressed_into_a_circle() -> void:
	var weapon: Weapon = auto_free(Weapon.new())
	weapon.data = WeaponData.new()
	weapon.data.projectile_count = 72
	add_child(weapon)
	weapon.set_physics_process(false)
	var directions: Array[Vector2] = []
	weapon.fired.connect(func(_o: Vector2, d: Vector2, _w: WeaponData) -> void: directions.append(d))
	weapon.try_fire(Vector2.RIGHT)
	assert_int(directions.size()).is_equal(72)
	assert_float(rad_to_deg(directions[0].angle_to(directions[1]))).is_equal_approx(5.0, 0.01)


func test_pierce_keeps_projectile_alive_for_extra_hits() -> void:
	var projectile: Projectile = auto_free(load("res://scenes/run/Projectile/Projectile.tscn").instantiate())
	add_child(projectile)
	var weapon := WeaponData.new()
	weapon.pierce = 1
	projectile.activate(Vector2.ZERO, Vector2.RIGHT, weapon)
	projectile._on_hit(null)
	assert_bool(projectile._active).is_true()
	projectile._on_hit(null)
	assert_bool(projectile._active).is_false()


func test_luck_multiplier_raises_drop_chance() -> void:
	var entry := DropEntry.new()
	entry.material = MaterialData.new()
	entry.chance = 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for i in 50:
		assert_int(entry.roll(rng, 2.0)).is_equal(1)


func test_all_upgrades_in_table() -> void:
	var table: UpgradeTable = load("res://data/upgrades/upgrade_table.tres")
	assert_int(table.upgrades.size()).is_equal(17)


## Ricochet (M13, #86): dopo il primo bersaglio si ridirige sul piu' vicino tra gli altri vivi
## (mai quello appena colpito), fino a ricochet_bounces volte.
func test_ricochet_redirects_toward_nearest_other_target() -> void:
	var projectile: Projectile = auto_free(load("res://scenes/run/Projectile/Projectile.tscn").instantiate())
	add_child(projectile)
	var weapon := WeaponData.new()
	weapon.ricochet_bounces = 1
	projectile.activate(Vector2.ZERO, Vector2.RIGHT, weapon)

	var hit_enemy: Node2D = auto_free(Node2D.new())
	add_child(hit_enemy)
	hit_enemy.global_position = Vector2(50.0, 0.0)
	var hurtbox: Hurtbox = auto_free(Hurtbox.new())
	hit_enemy.add_child(hurtbox)

	var far: Node2D = auto_free(Node2D.new())
	add_child(far)
	far.global_position = Vector2(500.0, 0.0)
	var near: Node2D = auto_free(Node2D.new())
	add_child(near)
	near.global_position = Vector2(0.0, 40.0)

	projectile.targets = func() -> Array[Node2D]: return [hit_enemy, far, near]
	projectile._on_hit(hurtbox)
	assert_bool(projectile._active).is_true()
	assert_vector(projectile._velocity.normalized()).is_equal_approx(Vector2(0.0, 1.0), Vector2(0.01, 0.01))
	# Un solo rimbalzo concesso: al secondo colpo sparisce come sempre.
	projectile._on_hit(hurtbox)
	assert_bool(projectile._active).is_false()


## Nessuna funzione di bersagli impostata (pool dei nemici): niente rimbalzo anche con bounces > 0.
func test_ricochet_without_targets_callable_just_deactivates() -> void:
	var projectile: Projectile = auto_free(load("res://scenes/run/Projectile/Projectile.tscn").instantiate())
	add_child(projectile)
	var weapon := WeaponData.new()
	weapon.ricochet_bounces = 3
	projectile.activate(Vector2.ZERO, Vector2.RIGHT, weapon)
	projectile._on_hit(null)
	assert_bool(projectile._active).is_false()
