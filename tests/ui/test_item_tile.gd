extends GdUnitTestSuite
## Caselle del loot e del baule: icona, bordo e tooltip per oggetti e materiali.


func test_item_and_material_tiles() -> void:
	var item := ItemInstance.new(load("res://data/equipment/gel_ring.tres"), 4)
	var tile: ItemTile = auto_free(ItemTile.for_item(item))
	assert_object(tile.icon).is_not_null()
	assert_str(tile.tooltip_text).contains(ItemText.title(item))
	var gel: MaterialData = load("res://data/materials/slime_gel.tres")
	var stack: ItemTile = auto_free(ItemTile.for_material(gel, 12))
	assert_int(stack.amount).is_equal(12)
	assert_object(stack.item_material).is_same(gel)
	assert_str(stack.tooltip_text).contains("12")


func test_loot_view_lists_everything() -> void:
	var screen: RunEndScreen = auto_free(load("res://scenes/ui/RunEndScreen/RunEndScreen.tscn").instantiate())
	add_child(screen)
	var items: Array[ItemInstance] = []
	for i in 20:
		items.append(ItemInstance.new(load("res://data/equipment/gel_wand.tres"), i % 5))
	screen.present(true, 5, 100.0, 50, 30, 30, items, {&"slime_gel": 10, &"slime_core": 2})
	screen._show_loot()
	assert_int(screen.get_node("%LootGrid").get_child_count()).is_equal(22)

func test_trash_badge_shown_for_tagged_item() -> void:
	var item := ItemInstance.new(load("res://data/equipment/gel_ring.tres"), 0)
	item.is_trash = true
	var tile: ItemTile = auto_free(ItemTile.for_item(item))
	assert_bool(tile.has_node("TrashBadge")).is_true()


func test_right_click_toggles_trash_tag_and_emits_signal() -> void:
	var item := ItemInstance.new(load("res://data/equipment/gel_ring.tres"), 0)
	var tile: ItemTile = auto_free(ItemTile.for_item(item))
	# Array invece di variabile locale: le lambda GDScript catturano le variabili per valore, non per
	# riferimento, quindi una var locale mutata dentro la lambda non si vedrebbe fuori.
	var toggled: Array = []
	tile.trash_toggled.connect(func(uid: int) -> void: toggled.append(uid))
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	tile._on_gui_input(event)
	assert_bool(item.is_trash).is_true()
	assert_bool(tile.has_node("TrashBadge")).is_true()
	assert_array(toggled).is_equal([item.uid])
	tile._on_gui_input(event)
	assert_bool(item.is_trash).is_false()
	# _remove_trash_badge() usa queue_free(): la rimozione e' effettiva al prossimo frame, non subito.
	await get_tree().process_frame
	assert_bool(tile.has_node("TrashBadge")).is_false()


func test_left_click_does_not_toggle_trash_tag() -> void:
	var item := ItemInstance.new(load("res://data/equipment/gel_ring.tres"), 0)
	var tile: ItemTile = auto_free(ItemTile.for_item(item))
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	tile._on_gui_input(event)
	assert_bool(item.is_trash).is_false()
