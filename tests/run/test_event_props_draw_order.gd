extends GdUnitTestSuite
## Ordine di disegno degli oggetti degli eventi (M13, #86): pentagramma, candele e statua sono a terra e
## devono stare sotto il player (bug: il player finiva disegnato sotto a tutti e tre).


func test_pentagram_and_statue_are_not_top_level() -> void:
	var director: RunEventDirector = auto_free(RunEventDirector.new())
	add_child(director)
	assert_bool(director._pentagram.top_level).is_false()
	assert_bool(director._statue.top_level).is_false()


## Ordine dei nodi nella scena (testo del .tscn, senza istanziare l'arena intera).
func test_event_director_is_drawn_before_player_and_enemies() -> void:
	var text := FileAccess.get_file_as_string("res://scenes/run/Arena/Arena.tscn")
	var director := text.find('[node name="EventDirector" type="Node2D" parent="."]')
	assert_int(director).is_greater(-1)
	for name in ["Player", "Enemies", "PickupPool", "ProjectilePool"]:
		var at := text.find('[node name="%s" ' % name)
		assert_int(at).override_failure_message(name).is_greater(director)
