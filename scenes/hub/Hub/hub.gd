extends Control
## Hub fuori dalla run (GDD §7): baule permanente, fabbro, equipaggiamento e partenza della run. Composition root dell'hub.

## Solo per mostrare i nomi nel baule; id sconosciuti vengono mostrati grezzi.
@export var materials: Array[MaterialData] = []

var _material_names: Dictionary[StringName, String] = {}
var _material_icons: Dictionary[StringName, Texture2D] = {}

@onready var _stash_label: Label = %StashLabel
@onready var _stash_list: VBoxContainer = %StashList
@onready var _blacksmith: Blacksmith = %Blacksmith
@onready var _loadout_panel: LoadoutPanel = %LoadoutPanel
@onready var _arena_select: ArenaSelect = %ArenaSelect
@onready var _sfx: SfxPlayer = %Sfx
@onready var _start_button: Button = %StartButton


func _ready() -> void:
	get_tree().paused = false
	for material in materials:
		_material_names[material.id] = material.display_name
		_material_icons[material.id] = material.icon
	MetaProgression.changed.connect(_refresh)
	_start_button.pressed.connect(_on_start_pressed)
	_blacksmith.craft_requested.connect(_on_craft_requested)
	_loadout_panel.equip_requested.connect(MetaProgression.equip)
	_loadout_panel.unequip_requested.connect(MetaProgression.unequip)
	_loadout_panel.equip_requested.connect(_sfx.play.bind(&"ui_select").unbind(1))
	_loadout_panel.unequip_requested.connect(_sfx.play.bind(&"ui_select").unbind(1))
	_arena_select.arena_selected.connect(_on_arena_selected)
	_refresh()
	_start_button.grab_focus()


func _refresh() -> void:
	_refresh_stash(MetaProgression.inventory.to_dictionary())
	_blacksmith.refresh(MetaProgression.inventory, MetaProgression.loadout, _material_names)
	_loadout_panel.refresh(MetaProgression.loadout)
	_arena_select.refresh(MetaProgression.arena_catalog, MetaProgression.extractions, MetaProgression.current_arena().id)
	_ensure_focus.call_deferred()


## Il refresh ricrea i bottoni: se il focus e' andato perso (tastiera/pad), torna su "Parti".
func _ensure_focus() -> void:
	# Chiamata differita: se nel frattempo si e' cambiata scena l'hub non e' piu' nell'albero.
	if not is_inside_tree():
		return
	if get_viewport().gui_get_focus_owner() == null:
		_start_button.grab_focus()


func _refresh_stash(amounts: Dictionary[StringName, int]) -> void:
	for child in _stash_list.get_children():
		child.queue_free()
	_stash_label.visible = amounts.is_empty()
	for id in amounts:
		var row := HBoxContainer.new()
		var icon := TextureRect.new()
		icon.texture = _material_icons.get(id)
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var label := Label.new()
		label.text = "%s × %d" % [_material_names.get(id, String(id)), amounts[id]]
		label.add_theme_color_override("font_color", Color(1, 0.8, 0.35))
		row.add_child(icon)
		row.add_child(label)
		_stash_list.add_child(row)


func _on_craft_requested(recipe: RecipeData) -> void:
	if MetaProgression.craft(recipe) == Crafting.Result.OK:
		_sfx.play(&"craft")


func _on_arena_selected(id: StringName) -> void:
	if MetaProgression.select_arena(id):
		_sfx.play(&"ui_select")


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(SceneRoutes.ARENA)
