extends GdUnitTestSuite


func test_escape_opens_and_closes_menu() -> void:
	var state := PauseState.new()
	assert_int(state.handle(PauseState.Action.MENU)).is_equal(PauseState.Mode.MENU)
	assert_bool(state.is_paused()).is_true()
	assert_int(state.handle(PauseState.Action.MENU)).is_equal(PauseState.Mode.NONE)


func test_p_toggles_direct_pause_and_escape_closes_it() -> void:
	var state := PauseState.new()
	assert_int(state.handle(PauseState.Action.PAUSE)).is_equal(PauseState.Mode.PAUSED)
	assert_int(state.handle(PauseState.Action.PAUSE)).is_equal(PauseState.Mode.NONE)
	state.handle(PauseState.Action.PAUSE)
	assert_int(state.handle(PauseState.Action.MENU)).is_equal(PauseState.Mode.NONE)


func test_inventory_toggles_and_escape_closes_it() -> void:
	var state := PauseState.new()
	assert_int(state.handle(PauseState.Action.INVENTORY)).is_equal(PauseState.Mode.INVENTORY)
	assert_bool(state.is_paused()).is_true()
	assert_int(state.handle(PauseState.Action.INVENTORY)).is_equal(PauseState.Mode.NONE)
	state.handle(PauseState.Action.INVENTORY)
	assert_int(state.handle(PauseState.Action.MENU)).is_equal(PauseState.Mode.NONE)


func test_menu_pause_option_switches_to_direct_pause() -> void:
	var state := PauseState.new()
	state.handle(PauseState.Action.MENU)
	assert_int(state.handle(PauseState.Action.PAUSE)).is_equal(PauseState.Mode.PAUSED)
	assert_int(state.handle(PauseState.Action.RESUME)).is_equal(PauseState.Mode.NONE)
