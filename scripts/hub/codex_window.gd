class_name CodexWindow
extends PanelContainer
## Codex della piazza (M12, #86): manuale consultabile in ogni momento (bottone nella barra icone),
## non l'onboarding una tantum di HubTutorial. Contenuto da CodexData (logica pura, testata a parte);
## qui solo la lista a sinistra e il testo a destra.

@onready var _list: VBoxContainer = %CodexList
@onready var _entry_title: Label = %CodexEntryTitle
@onready var _entry_body: RichTextLabel = %CodexEntryBody

var _buttons_by_entry: Array[Dictionary] = []


func _ready() -> void:
	_build_list()
	if not _buttons_by_entry.is_empty():
		_show_entry(_buttons_by_entry[0].title, _buttons_by_entry[0].body)
		_buttons_by_entry[0].button.button_pressed = true


func _build_list() -> void:
	for child in _list.get_children():
		child.queue_free()
	_buttons_by_entry.clear()
	var group := ButtonGroup.new()
	for section in CodexData.sections():
		var header := Label.new()
		header.text = tr(section.title)
		header.add_theme_color_override("font_color", Color(1, 0.86, 0.6))
		header.add_theme_font_size_override("font_size", 16)
		_list.add_child(header)
		for entry in section.entries:
			var button := Button.new()
			button.text = tr(entry.title)
			button.toggle_mode = true
			button.button_group = group
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.focus_mode = Control.FOCUS_ALL
			button.pressed.connect(_show_entry.bind(entry.title, entry.body))
			_list.add_child(button)
			_buttons_by_entry.append({"title": entry.title, "body": entry.body, "button": button})


func _show_entry(title_key: String, body_key: String) -> void:
	_entry_title.text = tr(title_key)
	_entry_body.text = tr(body_key)
