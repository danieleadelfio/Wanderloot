extends GdUnitTestSuite
## Freccia verso un indicatore piazzato sulla mappa (M13, #86). Solo logica pura: il disegno vero e
## proprio (BEST_PRACTICES: niente test sul rendering) e' verificato a mano.


func test_inactive_by_default() -> void:
	var arrow: MapIndicatorArrow = auto_free(MapIndicatorArrow.new())
	assert_bool(arrow.active).is_false()


## Bug (M13, #86): togliendo l'indicatore dalla mappa la freccia restava disegnata a schermo, perche'
## _process richiedeva un redraw solo "if active": spegnendo "active" nessuno cancellava piu' l'ultimo
## fotogramma. Qui verifichiamo solo lo stato esposto (il setter aggiorna sempre "active" com'e' atteso
## dal chiamante in Arena._on_map_indicator_placed); il redraw forzato dal setter non e' osservabile
## senza rendering.
func test_active_reflects_the_last_value_set_even_when_toggled_off() -> void:
	var arrow: MapIndicatorArrow = auto_free(MapIndicatorArrow.new())
	arrow.active = true
	assert_bool(arrow.active).is_true()
	arrow.active = false
	assert_bool(arrow.active).is_false()
	arrow.active = false
	assert_bool(arrow.active).is_false()
