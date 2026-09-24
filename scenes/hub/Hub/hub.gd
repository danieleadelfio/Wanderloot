extends Node2D
## Hub fuori dalla run (GDD §7): piazza esplorabile con fabbro, baule e portale. Composition root dell'hub.
## Il player cammina nella piazza; con E su un punto di interazione si apre la sua finestra (gioco in pausa), ESC o E la chiude.

## Solo per mostrare i nomi nel baule; id sconosciuti vengono mostrati grezzi.
@export var materials: Array[MaterialData] = []

var _material_names: Dictionary[StringName, String] = {}
var _material_icons: Dictionary[StringName, Texture2D] = {}
var _interactables: Array[Interactable] = []
var _open_window: Control = null

@onready var _stash_label: Label = %StashLabel
@onready var _stash_list: VBoxContainer = %StashList
@onready var _blacksmith: Blacksmith = %Blacksmith
@onready var _loadout_panel: LoadoutPanel = %LoadoutPanel
@onready var _arena_select: ArenaSelect = %ArenaSelect
@onready var _sfx: SfxPlayer = %Sfx
@onready var _start_button: Button = %StartButton
@onready var _prompt: Label = %Prompt
@onready var _dim: ColorRect = %Dim


func _ready() -> void:
	get_tree().paused = false
	for material in materials:
		_material_names[material.id] = material.display_name
		_material_icons[material.id] = material.icon
	for node in find_children("*", "Interactable", true, false):
		var spot := node as Interactable
		_interactables.append(spot)
		spot.window.hide()
	_dim.hide()
	MetaProgression.changed.connect(_refresh)
	_start_button.pressed.connect(_on_start_pressed)
	_blacksmith.craft_requested.connect(_on_craft_requested)
	_loadout_panel.equip_requested.connect(MetaProgression.equip)
	_loadout_panel.unequip_requested.connect(MetaProgression.unequip)
	_loadout_panel.equip_requested.connect(_sfx.play.bind(&"ui_select").unbind(1))
	_loadout_panel.unequip_requested.connect(_sfx.play.bind(&"ui_select").unbind(1))
	_arena_select.arena_selected.connect(_on_arena_selected)
	_refresh()


func _process(_delta: float) -> void:
	var spot := _nearest_spot()
	_prompt.visible = spot != null and _open_window == null
	if spot:
		_prompt.text = spot.prompt


func _unhandled_input(event: InputEvent) -> void:
	if _open_window:
		if event.is_action_pressed("menu") or event.is_action_pressed("interact"):
			_close_window()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		var spot := _nearest_spot()
		if spot:
			_open(spot.window)
			get_viewport().set_input_as_handled()


func _nearest_spot() -> Interactable:
	var in_range: Array[Interactable] = _interactables.filter(func(s: Interactable) -> bool: return s.player_in_range)
	var points := PackedVector2Array()
	for spot in in_range:
		points.append(spot.global_position)
	var index := Interactable.nearest_index(points, %Player.global_position)
	return in_range[index] if index >= 0 else null


func _open(window: Control) -> void:
	_open_window = window
	window.show()
	_dim.show()
	get_tree().paused = true
	_sfx.play(&"ui_select")
	_ensure_focus.call_deferred()


func _close_window() -> void:
	_open_window.hide()
	_open_window = null
	_dim.hide()
	get_tree().paused = false


func _refresh() -> void:
	_refresh_stash(MetaProgression.inventory.to_dictionary())
	_blacksmith.refresh(MetaProgression.inventory, MetaProgression.loadout, _material_names)
	_loadout_panel.refresh(MetaProgression.loadout)
	_arena_select.refresh(MetaProgression.arena_catalog, MetaProgression.extractions, MetaProgression.current_arena().id)
	_ensure_focus.call_deferred()


## Il refresh ricrea i bottoni: se il focus e' andato perso (tastiera/pad), torna sul primo bottone attivo della finestra aperta.
func _ensure_focus() -> void:
	# Chiamata differita: se nel frattempo si e' cambiata scena l'hub non e' piu' nell'albero.
	if not is_inside_tree() or _open_window == null:
		return
	var owner_control := get_viewport().gui_get_focus_owner()
	if owner_control and _open_window.is_ancestor_of(owner_control):
		return
	for node in _open_window.find_children("*", "Button", true, false):
		var button := node as Button
		if button.is_visible_in_tree() and not button.disabled:
			button.grab_focus()
			return


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
	get_tree().paused = false
	get_tree().change_scene_to_file(SceneRoutes.ARENA)
