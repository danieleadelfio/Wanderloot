extends GdUnitTestSuite
## Veleno: 1 danno ogni 1,5 s per 4,5 s = 3 danni; un nuovo colpo rinnova senza sommare.


func _run(state: PoisonState, seconds: float) -> int:
	var total := 0
	for i in roundi(seconds / 0.1):
		total += state.tick(0.1)
	return total


func test_poison_deals_three_damage_over_its_duration() -> void:
	var state := PoisonState.new()
	state.apply(4.5, 1.5, 1)
	assert_int(_run(state, 6.0)).is_equal(3)
	assert_bool(state.is_active()).is_false()


func test_new_hit_refreshes_without_stacking() -> void:
	var state := PoisonState.new()
	state.apply(4.5, 1.5, 1)
	assert_int(_run(state, 3.0)).is_equal(2)
	state.apply(4.5, 1.5, 1)
	assert_float(state.remaining).is_equal_approx(4.5, 0.01)
	assert_int(_run(state, 5.0)).is_equal(3)


func test_player_is_poisoned_by_a_poison_hitbox() -> void:
	var player: Player = auto_free(load("res://scenes/run/Player/Player.tscn").instantiate())
	add_child(player)
	assert_int(player.health.max_hp).is_equal(10)
	player.poison.apply(4.5, 1.5, 1)
	for i in 60:
		player.poison._physics_process(0.1)
	assert_int(player.health.current).is_equal(7)
