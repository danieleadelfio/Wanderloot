extends Node2D
## Hub fuori dalla run (GDD §7): piazza esplorabile con fabbro, baule e portale. Composition root dell'hub.
## Il player cammina nella piazza; con E su un punto di interazione si apre la sua finestra (gioco in pausa), ESC o E la chiude.
## ESC senza finestre aperte apre il menu di pausa (Riprendi, Salva, Carica, Torna al menu).

## Solo per mostrare i nomi nel baule; id sconosciuti vengono mostrati grezzi.
@export var materials: Array[MaterialData] = []

var _material_names: Dictionary[StringName, String] = {}
var _material_icons: Dictionary[StringName, Texture2D] = {}
var _interactables: Array[Interactable] = []
var _open_window: Control = null
var _pause_open: bool = false

@onready var _stash_label: Label = %StashLabel
@onready var _stash_list: VBoxContainer = %StashList
@onready var _blacksmith: Blacksmith = %Blacksmith
@onready var _loadout_panel: LoadoutPanel = %LoadoutPanel
@onready var _arena_select: ArenaSelect = %ArenaSelect
@onready var _sfx: SfxPlayer = %Sfx
@onready var _start_button: Button = %StartButton
@onready var _prompt: Label = %Prompt
@onready var _dim: ColorRect = %Dim
@onready var _pause_menu: PauseMenu = %PauseMenu
@onready var _inventory_window: Control = %InventoryWindow
@onready var _tabs: TabContainer = %Tabs
@onready var _hub_stats_grid: GridContainer = %HubStatsGrid
@onready var _player: Player = %Player


func _ready() -> void:
	get_tree().paused = false
	for material in materials:
		_material_names[material.id] = tr(material.display_name)
		_material_icons[material.id] = material.icon
	for node in find_children("*", "Interactable", true, false):
		var spot := node as Interactable
		_interactables.append(spot)
		spot.window.hide()
	_dim.hide()
	MetaProgression.changed.connect(_refresh)
	_start_button.pressed.connect(_on_start_pressed)
	_blacksmith.craft_requested.connect(_on_craft_requested)
	_blacksmith.fuse_requested.connect(_on_fuse_requested)
	_blacksmith.salvage_requested.connect(_on_salvage_requested)
	_loadout_panel.equip_requested.connect(MetaProgression.equip)
	_loadout_panel.unequip_requested.connect(MetaProgression.unequip)
	_loadout_panel.equip_requested.connect(_sfx.play.bind(&"ui_select").unbind(1))
	_loadout_panel.unequip_requested.connect(_sfx.play.bind(&"ui_select").unbind(1))
	_arena_select.arena_selected.connect(_on_arena_selected)
	_pause_menu.action_requested.connect(_on_pause_action)
	%InventoryIcon.pressed.connect(_toggle_inventory.bind(0))
	%StatsIcon.pressed.connect(_toggle_inventory.bind(1))
	_tabs.set_tab_title(0, tr("TAB_INVENTORY"))
	_tabs.set_tab_title(1, tr("TAB_STATS"))
	_pause_menu.language_requested.connect(_on_language_requested)
	_pause_menu.set_hint(tr("PAUSE_HINT_HUB"))
	_pause_menu.save_requested.connect(_on_save_requested)
	_pause_menu.load_requested.connect(GameSession.load_saved.bind(get_tree()))
	_pause_menu.menu_requested.connect(GameSession.quit_to_menu.bind(get_tree()))
	_refresh()
	_restore_saved_position()


## Dopo Carica/Continua il player riappare dove aveva salvato nella piazza.
func _restore_saved_position() -> void:
	if not MetaProgression.has_pending_hub_position():
		return
	var player: Node2D = %Player
	player.global_position = MetaProgression.take_pending_hub_position()
	player.reset_physics_interpolation()
	(player.get_node("Camera2D") as Camera2D).reset_smoothing()


func _process(_delta: float) -> void:
	var spot := _nearest_spot()
	_prompt.visible = spot != null and _open_window == null and not _pause_open
	if spot:
		_prompt.text = spot.prompt


func _unhandled_input(event: InputEvent) -> void:
	if _pause_open:
		if event.is_action_pressed("menu"):
			_set_pause_open(false)
			get_viewport().set_input_as_handled()
	elif _open_window:
		if _open_window == _inventory_window and (event.is_action_pressed("inventory") or event.is_action_pressed("character")):
			_toggle_inventory(0 if event.is_action_pressed("inventory") else 1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("menu") or event.is_action_pressed("interact"):
			_close_window()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu"):
		_set_pause_open(true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory") or event.is_action_pressed("character"):
		_toggle_inventory(0 if event.is_action_pressed("inventory") else 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		var spot := _nearest_spot()
		if spot:
			if spot.window == _inventory_window:
				_tabs.current_tab = 0
			_open(spot.window)
			get_viewport().set_input_as_handled()


func _nearest_spot() -> Interactable:
	var in_range: Array[Interactable] = _interactables.filter(func(s: Interactable) -> bool: return s.player_in_range)
	var points := PackedVector2Array()
	for spot in in_range:
		points.append(spot.global_position)
	var index := Interactable.nearest_index(points, %Player.global_position)
	return in_range[index] if index >= 0 else null


## Finestra Inventario (scheda 0) / Statistiche (scheda 1): I, C, icone in alto a destra, baule.
## Stesso tasto sulla scheda aperta = chiude; tasto dell'altra scheda = cambia scheda.
func _toggle_inventory(tab: int) -> void:
	if _pause_open:
		return
	if _open_window == _inventory_window:
		if _tabs.current_tab == tab:
			_close_window()
			return
		_tabs.current_tab = tab
		return
	if _open_window:
		_close_window()
	_tabs.current_tab = tab
	_open(_inventory_window)


func _set_pause_open(open: bool) -> void:
	_pause_open = open
	_pause_menu.set_can_load(MetaProgression.has_save())
	_pause_menu.set_unsaved_changes(MetaProgression.has_unsaved_changes)
	_pause_menu.show_mode(PauseState.Mode.MENU if open else PauseState.Mode.NONE)
	get_tree().paused = open


func _on_pause_action(action: PauseState.Action) -> void:
	if action == PauseState.Action.RESUME:
		_set_pause_open(false)


func _on_save_requested() -> void:
	MetaProgression.set_hub_position(%Player.global_position)
	var ok := GameSession.save()
	_pause_menu.show_status(tr("SAVE_OK") if ok else tr("SAVE_FAIL"))
	_pause_menu.set_can_load(MetaProgression.has_save())
	_pause_menu.set_unsaved_changes(MetaProgression.has_unsaved_changes)
	_sfx.play(&"ui_select")


## Cambio lingua dal menu di pausa: salva (con la posizione nella piazza) e torna al menu iniziale.
func _on_language_requested(locale: String) -> void:
	MetaProgression.set_hub_position(%Player.global_position)
	GameSession.change_language(get_tree(), locale)


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
	# Statistiche con l'equipaggiamento attuale: lo stesso calcolo di inizio run, sul player della piazza.
	_player.begin_run(MetaProgression.equipped_modifiers())
	StatSheet.fill(_hub_stats_grid, StatSheet.rows(_player.stats, _player.weapon_data()), 18)
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


func _on_fuse_requested(first_uid: int, second_uid: int) -> void:
	if MetaProgression.fuse(first_uid, second_uid):
		_sfx.play(&"craft")


func _on_salvage_requested(uid: int) -> void:
	if MetaProgression.salvage(uid):
		_sfx.play(&"pickup_item")


func _on_arena_selected(id: StringName) -> void:
	if MetaProgression.select_arena(id):
		_sfx.play(&"ui_select")


func _on_start_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(SceneRoutes.ARENA)
