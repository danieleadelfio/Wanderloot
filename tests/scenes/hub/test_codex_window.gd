extends GdUnitTestSuite
## Finestra Codex (M12, #86): costruisce la lista da CodexData e mostra la voce selezionata.
## Qui solo la logica di selezione, non il rendering.

var _window: CodexWindow


func before_test() -> void:
	_window = auto_free((load("res://scenes/hub/Codex/CodexWindow.tscn") as PackedScene).instantiate())
	add_child(_window)


func test_first_entry_shown_on_ready() -> void:
	var first_section: Dictionary = CodexData.sections()[0]
	var first_entry: Dictionary = first_section.entries[0]
	var title := _window.get_node("%CodexEntryTitle") as Label
	var body := _window.get_node("%CodexEntryBody") as RichTextLabel
	assert_str(title.text).is_equal(tr(first_entry.title as String))
	assert_str(body.text).is_equal(tr(first_entry.body as String))


func test_selecting_another_entry_updates_detail() -> void:
	var list := _window.get_node("%CodexList") as VBoxContainer
	var buttons: Array = list.get_children().filter(func(n: Node) -> bool: return n is Button)
	assert_int(buttons.size()).is_greater(1)
	var second_button := buttons[1] as Button
	second_button.pressed.emit()
	var title := _window.get_node("%CodexEntryTitle") as Label
	assert_str(title.text).is_equal(tr("CODEX_CHEST_TITLE"))
