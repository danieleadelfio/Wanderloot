extends GdUnitTestSuite
## Hub "piattaforma arcana sospesa" (GDD §7): il punto d'arrivo e i punti di interazione sono raggiungibili,
## e una posizione salvata nel vuoto (vecchia piazza) non viene ripristinata.
## Stato di MetaProgression solo in memoria (new_game), mai scritto su disco.


func before_test() -> void:
	MetaProgression.new_game()
	MetaProgression.mark_tutorial_seen(&"hub_intro")


func after_test() -> void:
	get_tree().paused = false
	MetaProgression.new_game()


func _hub() -> Node2D:
	var hub: Node2D = auto_free(load("res://scenes/hub/Hub/Hub.tscn").instantiate())
	add_child(hub)
	return hub


func test_spawn_is_walkable() -> void:
	var hub := _hub()
	await get_tree().process_frame
	assert_bool(hub._is_walkable(hub.get_node("%Player").global_position)).is_true()


func test_void_and_obstacles_are_not_walkable() -> void:
	var hub := _hub()
	await get_tree().process_frame
	assert_bool(hub._is_walkable(Vector2(0, 470))).override_failure_message("vuoto sotto le isole").is_false()
	assert_bool(hub._is_walkable(hub.get_node("World/Vortex").global_position)).override_failure_message("vortice").is_false()


## Ogni punto di interazione ha pavimento calpestabile entro il proprio raggio (si puo' arrivare a premere E).
func test_every_interactable_has_walkable_floor_in_range() -> void:
	var hub := _hub()
	await get_tree().process_frame
	for spot: Interactable in hub._interactables:
		var radius := ((spot.get_node("Shape") as CollisionShape2D).shape as CircleShape2D).radius
		var found := false
		for i in 16:
			if hub._is_walkable(spot.global_position + Vector2.from_angle(i * TAU / 16.0) * radius * 0.8):
				found = true
				break
		assert_bool(found).override_failure_message(String(spot.name)).is_true()


func test_saved_position_in_the_void_is_ignored() -> void:
	# Come dopo Carica con un salvataggio della vecchia piazza (M7): punto oggi nel vuoto sotto le isole.
	MetaProgression._pending_hub_position = Vector2(0, 470)
	MetaProgression._has_pending_hub_position = true
	var hub := _hub()
	await get_tree().process_frame
	var player: Node2D = hub.get_node("%Player")
	assert_vector(player.global_position).is_not_equal(Vector2(0, 470))
	assert_bool(hub._is_walkable(player.global_position)).is_true()
