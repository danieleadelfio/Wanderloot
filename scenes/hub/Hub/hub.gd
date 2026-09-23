extends Control
## Hub fuori dalla run (GDD §7): baule permanente e partenza della run. Composition root dell'hub.

## Solo per mostrare i nomi nel baule; id sconosciuti vengono mostrati grezzi.
@export var materials: Array[MaterialData] = []

var _material_names: Dictionary[StringName, String] = {}

@onready var _stash_label: Label = %StashLabel
@onready var _start_button: Button = %StartButton


func _ready() -> void:
	get_tree().paused = false
	for material in materials:
		_material_names[material.id] = material.display_name
	MetaProgression.changed.connect(_refresh)
	_start_button.pressed.connect(_on_start_pressed)
	_refresh()
	_start_button.grab_focus()


func _refresh() -> void:
	_stash_label.text = _format_stash(MetaProgression.inventory.to_dictionary())


func _format_stash(amounts: Dictionary[StringName, int]) -> String:
	if amounts.is_empty():
		return "Baule vuoto: estrai loot da una run."
	var lines: PackedStringArray = []
	for id in amounts:
		lines.append("%s × %d" % [_material_names.get(id, String(id)), amounts[id]])
	return "\n".join(lines)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(SceneRoutes.ARENA)
