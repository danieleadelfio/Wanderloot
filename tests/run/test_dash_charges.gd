extends GdUnitTestSuite
## Scatto: 6 cariche, una per scatto, una torna ogni 2 s; niente scatto senza cariche.


func test_charges_are_used_and_recharge_one_every_interval() -> void:
	var dash := DashCharges.new()
	dash.reset(6, 2.0)
	for i in 6:
		assert_bool(dash.try_use()).is_true()
	assert_bool(dash.try_use()).is_false()
	dash.tick(1.0)
	assert_int(dash.charges).is_equal(0)
	assert_float(dash.partial()).is_equal_approx(0.5, 0.001)
	dash.tick(1.0)
	assert_int(dash.charges).is_equal(1)
	dash.tick(20.0)
	assert_int(dash.charges).is_equal(6)
	assert_float(dash.partial()).is_equal(0.0)


func test_player_dash_mode_blocks_shooting_and_grants_iframes() -> void:
	var player: Player = auto_free(load("res://scenes/run/Player/Player.tscn").instantiate())
	add_child(player)
	var event: RunEventData = load("res://data/events/shadow_step.tres")
	player.start_dash_mode(event)
	assert_bool(player.dash_mode).is_true()
	assert_bool(player.try_dash(Vector2.RIGHT)).is_true()
	assert_bool(player.is_dashing()).is_true()
	assert_bool(player.is_immune()).is_true()
	assert_int(player.dash_charges.charges).is_equal(event.dash_charges - 1)
	player.stop_dash_mode()
	assert_bool(player.is_dashing()).is_false()
	assert_bool(player.is_immune()).is_false()
	assert_bool(player.try_dash(Vector2.RIGHT)).is_false()
