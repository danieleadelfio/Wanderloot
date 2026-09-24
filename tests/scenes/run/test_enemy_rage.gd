extends GdUnitTestSuite
## Rage: scatta dopo rage_after secondi in vita, aumenta velocita' e danno, si azzera tornando nel pool.

const TICK: float = 0.1


func _enemy() -> Enemy:
	var enemy: Enemy = auto_free(load("res://scenes/run/Enemies/EnemyBasic/EnemyBasic.tscn").instantiate())
	add_child(enemy)
	enemy.activate(Vector2.ZERO)
	enemy.set_physics_process(false)
	return enemy


func _live(enemy: Enemy, seconds: float) -> void:
	for i in roundi(seconds / TICK):
		enemy._physics_process(TICK)


func test_rage_starts_after_threshold() -> void:
	var enemy := _enemy()
	_live(enemy, enemy.data.rage_after - 0.2)
	assert_bool(enemy.is_raged).is_false()
	_live(enemy, 0.3)
	assert_bool(enemy.is_raged).is_true()


func test_rage_boosts_speed_and_contact_damage() -> void:
	var enemy := _enemy()
	var base_speed := enemy.current_speed()
	_live(enemy, enemy.data.rage_after + 0.1)
	assert_float(enemy.current_speed()).is_equal_approx(base_speed * enemy.data.rage_speed_multiplier, 0.001)
	assert_int(enemy._hitbox.damage).is_equal(enemy.data.contact_damage + enemy.data.rage_damage_bonus)


func test_rage_resets_when_reused_from_pool() -> void:
	var enemy := _enemy()
	_live(enemy, enemy.data.rage_after + 0.1)
	enemy.deactivate()
	enemy.activate(Vector2.ZERO)
	enemy.set_physics_process(false)
	assert_bool(enemy.is_raged).is_false()
	assert_int(enemy._hitbox.damage).is_equal(enemy.data.contact_damage)
	assert_float(enemy._rage_body.modulate.a).is_equal(0.0)
