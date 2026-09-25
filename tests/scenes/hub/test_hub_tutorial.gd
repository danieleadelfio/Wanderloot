extends GdUnitTestSuite
## Tour guidato della piazza (M12, #86): sequenza di passi, avanzamento, skip e segnale finale. Camera
## e player sono nodi minimi (non serve la scena Hub intera): qui si copre solo la logica del tour.

var _tutorial: HubTutorial
var _camera: Camera2D
var _player: Node2D


func before_test() -> void:
	_tutorial = auto_free((load("res://scenes/hub/HubTutorial/HubTutorial.tscn") as PackedScene).instantiate())
	add_child(_tutorial)
	_camera = auto_free(Camera2D.new())
	add_child(_camera)
	_player = auto_free(Node2D.new())
	add_child(_player)
	_player.global_position = Vector2(10, 20)


func _steps() -> Array[Dictionary]:
	return [
		{"title": "Uno", "body": "Corpo uno", "position": Vector2(100, 0)},
		{"title": "Due", "body": "Corpo due", "position": Vector2(200, 0)},
	]


func test_start_shows_first_step() -> void:
	_tutorial.start(_camera, _player, _steps())
	assert_bool(_tutorial.visible).is_true()
	assert_str((_tutorial.get_node("%Title") as Label).text).is_equal("Uno")


func test_player_movement_is_frozen_while_running() -> void:
	_tutorial.start(_camera, _player, _steps())
	assert_bool(_player.is_physics_processing()).is_false()


func test_finish_emits_signal_and_restores_player() -> void:
	var received := [false]
	_tutorial.finished.connect(func() -> void: received[0] = true)
	_tutorial.start(_camera, _player, _steps())
	_tutorial._finish()
	assert_bool(received[0]).is_true()
	assert_bool(_player.is_physics_processing()).is_true()
	assert_bool(_tutorial.visible).is_false()
	assert_vector(_camera.global_position).is_equal(_player.global_position)


func test_advancing_past_last_step_finishes() -> void:
	_tutorial.start(_camera, _player, _steps())
	_tutorial._advance()  # passo 2 (Due)
	assert_bool(_tutorial.visible).is_true()
	_tutorial._advance()  # oltre l'ultimo -> finisce
	assert_bool(_tutorial.visible).is_false()


func test_empty_steps_finishes_immediately() -> void:
	var received := [false]
	_tutorial.finished.connect(func() -> void: received[0] = true)
	_tutorial.start(_camera, _player, [] as Array[Dictionary])
	assert_bool(received[0]).is_true()
