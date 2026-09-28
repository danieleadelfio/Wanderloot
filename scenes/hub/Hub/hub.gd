extends Node2D
## Hub fuori dalla run (GDD §7): isole sospese esplorabili con fabbro, baule e portale. Composition root dell'hub.
## Il player cammina nella piazza; con E su un punto di interazione si apre la sua finestra (gioco in pausa), ESC o E la chiude.
## ESC senza finestre aperte apre il menu di pausa (Riprendi, Salva, Carica, Torna al menu).

## Apertura del Bag of Resources (M13, #86): icone in volo, durata del volo, ritardo tra una e l'altra.
const BAG_FLY_PIECES := 8
const BAG_FLY_TIME := 0.55
const BAG_FLY_STAGGER := 0.07

## Solo per mostrare i nomi nel baule; id sconosciuti vengono mostrati grezzi.
@export var materials: Array[MaterialData] = []
## Frazione dello schermo entro cui la finestra Inventario deve stare (stesso fix di
## RunInventory._fit_to_viewport, M13, #86: equipaggiare un pezzo puo' far crescere il baule/
## manichino oltre lo schermo - qui non c'era ancora, la finestra dell'hub non si ridimensionava mai).
@export_range(0.5, 1.0, 0.01) var max_inventory_viewport_fraction: float = 0.92

var _material_names: Dictionary[StringName, String] = {}
var _material_icons: Dictionary[StringName, Texture2D] = {}
## Apertura di un Bag of Resources in corso (M13, #86): la lista Risorse mostra questi valori (che
## salgono man mano che le icone arrivano) invece di quelli veri, gia' aggiornati da open_bag().
var _stash_override: Dictionary[StringName, int] = {}
var _bag_animating: bool = false
var _stash_labels: Dictionary[StringName, Label] = {}
var _stash_icons: Dictionary[StringName, TextureRect] = {}
var _interactables: Array[Interactable] = []
var _open_window: Control = null
var _pause_open: bool = false
var _autosave_tween: Tween

@onready var _stash_label: Label = %StashLabel
@onready var _stash_list: VBoxContainer = %StashList
@onready var _blacksmith: Blacksmith = %Blacksmith
@onready var _loadout_panel: LoadoutPanel = %LoadoutPanel
@onready var _arena_select: ArenaSelect = %ArenaSelect
@onready var _portal_window: Control = %PortalWindow
@onready var _sfx: SfxPlayer = %Sfx
@onready var _start_button: Button = %StartButton
@onready var _prompt: Control = %Prompt
@onready var _prompt_label: Label = %PromptLabel
@onready var _dim: ColorRect = %Dim
@onready var _pause_menu: PauseMenu = %PauseMenu
@onready var _inventory_window: Control = %InventoryWindow
@onready var _tabs: TabContainer = %Tabs
@onready var _hub_stats_grid: GridContainer = %HubStatsGrid
@onready var _player: Player = %Player
@onready var _autosave_toast: Label = %AutosaveToast
@onready var _hub_tutorial: HubTutorial = %HubTutorial
@onready var _codex_window: Control = %CodexWindow
@onready var _inventory_panel: PanelContainer = %Panel


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
	_blacksmith.salvage_all_trash_requested.connect(_on_salvage_all_trash_requested)
	_blacksmith.ascend_requested.connect(_on_ascend_requested)
	_loadout_panel.equip_requested.connect(MetaProgression.equip)
	_loadout_panel.unequip_requested.connect(MetaProgression.unequip)
	_loadout_panel.seen_requested.connect(MetaProgression.mark_seen)
	_loadout_panel.trash_toggled.connect(MetaProgression.toggle_trash)
	_loadout_panel.bag_open_requested.connect(_on_bag_open_requested)
	_loadout_panel.equip_requested.connect(_sfx.play.bind(&"ui_select").unbind(1))
	_loadout_panel.unequip_requested.connect(_sfx.play.bind(&"ui_select").unbind(1))
	_arena_select.arena_selected.connect(_on_arena_selected)
	_pause_menu.action_requested.connect(_on_pause_action)
	%InventoryIcon.pressed.connect(_toggle_inventory.bind(0))
	%StatsIcon.pressed.connect(_toggle_inventory.bind(1))
	%CodexIcon.pressed.connect(_toggle_codex)
	_tabs.set_tab_title(0, tr("TAB_INVENTORY"))
	_tabs.set_tab_title(1, tr("TAB_STATS"))
	_pause_menu.language_requested.connect(_on_language_requested)
	_pause_menu.set_hint(tr("PAUSE_HINT_HUB"))
	_pause_menu.set_can_abandon(false)  # Niente run da abbandonare nell'hub (M12, #86).
	_pause_menu.save_requested.connect(_on_save_requested)
	_pause_menu.load_requested.connect(GameSession.load_saved.bind(get_tree()))
	_pause_menu.menu_requested.connect(GameSession.quit_to_menu.bind(get_tree()))
	get_viewport().size_changed.connect(_fit_inventory_to_viewport)
	# Anche quando il contenuto cambia misura a finestra aperta (M13, #86): prima la scala restava quella
	# calcolata al primo frame, gonfia, e al primo avvio la finestra finiva fuori schermo o minuscola.
	_inventory_panel.minimum_size_changed.connect(_fit_inventory_after_frame)
	_refresh()
	_restore_saved_position()
	if MetaProgression.take_pending_autosave_notice():
		_show_autosave_toast()
	if not MetaProgression.has_seen_tutorial(&"hub_intro"):
		_start_hub_tutorial()


## Dopo Carica/Continua il player riappare dove aveva salvato nella piazza.
func _restore_saved_position() -> void:
	if not MetaProgression.has_pending_hub_position():
		return
	var saved := MetaProgression.take_pending_hub_position()
	# Un salvataggio fatto nella vecchia piazza (M7) puo' cadere nel vuoto tra le isole o dentro un oggetto:
	# in quel caso si resta al punto d'arrivo sulla piazza del portale.
	if not _is_walkable(saved):
		return
	var player: Node2D = %Player
	player.global_position = saved
	player.reset_physics_interpolation()
	(player.get_node("Camera2D") as Camera2D).reset_smoothing()


## Punto sul pavimento dell'hub e fuori dagli ostacoli (GDD §7): dentro il bordo calpestabile
## (`WalkEdge`, poligono a segmenti) e fuori da ogni poligono solido o cerchio di `Bounds`.
func _is_walkable(point: Vector2) -> bool:
	var bounds: Node2D = %Bounds
	var local := bounds.to_local(point)
	for child in bounds.get_children():
		if child is CollisionPolygon2D:
			var area := child as CollisionPolygon2D
			var inside := Geometry2D.is_point_in_polygon(local, area.polygon)
			if area.build_mode == CollisionPolygon2D.BUILD_SEGMENTS:
				if not inside:
					return false
			elif inside:
				return false
		elif child is CollisionShape2D and (child as CollisionShape2D).shape is CircleShape2D:
			var round_shape := child as CollisionShape2D
			if local.distance_to(round_shape.position) < (round_shape.shape as CircleShape2D).radius:
				return false
	return true


## Tour guidato della piazza alla prima nuova partita (M12, #86): la camera si stacca dal player e
## visita fabbro, baule e portale con una breve descrizione, skippabile in ogni momento.
func _start_hub_tutorial() -> void:
	var player: Node2D = %Player
	var camera := player.get_node("Camera2D") as Camera2D
	var steps: Array[Dictionary] = [{
		"title": tr("TUTORIAL_HUB_TITLE"),
		"body": tr("TUTORIAL_HUB_INTRO_BODY"),
		"position": player.global_position,
	}]
	for spot in _interactables:
		if spot.tutorial_title == "":
			continue
		steps.append({
			"title": tr(spot.tutorial_title),
			"body": tr(spot.tutorial_description),
			"position": spot.global_position,
		})
		# Subito dopo il fabbro: a cosa serve l'Ascensione delle abilita' (M13, #86).
		if spot.window and spot.window.is_ancestor_of(_blacksmith):
			steps.append({
				"title": tr("TUTORIAL_HUB_ASCENSION_TITLE"),
				"body": tr("TUTORIAL_HUB_ASCENSION_BODY"),
				"position": spot.global_position,
			})
	steps.append({
		"title": tr("TUTORIAL_HUB_END_TITLE"),
		"body": tr("TUTORIAL_HUB_END_BODY"),
		"position": player.global_position,
	})
	_hub_tutorial.finished.connect(_on_hub_tutorial_finished, CONNECT_ONE_SHOT)
	_hub_tutorial.start(camera, player, steps)


func _on_hub_tutorial_finished() -> void:
	MetaProgression.mark_tutorial_seen(&"hub_intro")


## Toast "Salvataggio automatico..." a fine run, successo o game over (M12, #86).
func _show_autosave_toast() -> void:
	_autosave_toast.text = tr("HUB_AUTOSAVE")
	_autosave_toast.modulate.a = 1.0
	_autosave_toast.visible = true
	if _autosave_tween:
		_autosave_tween.kill()
	_autosave_tween = create_tween()
	_autosave_tween.tween_interval(1.8)
	_autosave_tween.tween_property(_autosave_toast, "modulate:a", 0.0, 0.5)
	_autosave_tween.tween_callback(_autosave_toast.hide)


func _process(_delta: float) -> void:
	var spot := _nearest_spot()
	_prompt.visible = spot != null and _open_window == null and not _pause_open
	if spot:
		_prompt_label.text = spot.prompt


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


## Codex (M12, #86): manuale consultabile in ogni momento, non l'onboarding una tantum di HubTutorial.
func _toggle_codex() -> void:
	if _pause_open:
		return
	if _open_window == _codex_window:
		_close_window()
		return
	if _open_window:
		_close_window()
	_open(_codex_window)


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
	# Livello arena (§6.3b, M12 #86): ricalcolato qui (non solo nel refresh reattivo) cosi' l'hint
	# "prima volta" si segna visto solo quando il pannello e' davvero visibile, non in background.
	if window == _portal_window:
		_arena_select.refresh(MetaProgression.arena_catalog, MetaProgression.extractions, MetaProgression.current_arena().id, _arena_level())
	elif window == _inventory_window:
		_fit_inventory_after_frame()
	_dim.show()
	get_tree().paused = true
	_sfx.play(&"ui_select")
	_ensure_focus.call_deferred()


func _close_window() -> void:
	_open_window.hide()
	_open_window = null
	_dim.hide()
	get_tree().paused = false


## Finestra Inventario entro max_inventory_viewport_fraction dello schermo (M13, #86), stessa logica
## dell'inventario di run (UiFit). La dimensione del pannello e' fissa per costruzione (LoadoutPanel:
## riga abilita' ad altezza fissa, avviso "baule vuoto" che non esce dal layout), quindi equip/unequip
## non la cambiano piu'; qui si ricalcola solo la scala, mai resettata a 1 prima (dava un frame a
## grandezza piena a ogni refresh, visibile come un "salto" della finestra).
func _fit_inventory_to_viewport() -> void:
	if not _inventory_window.visible:
		return
	UiFit.fit(_inventory_window, _inventory_panel, get_viewport().get_visible_rect().size, max_inventory_viewport_fraction)


## Al frame successivo (vecchi tile/righe gia' liberati) rimette il pannello alla sua dimensione minima e
## lo ricentra: un contenuto cresciuto per un frame nella scheda nascosta (Statistiche) non notifica il
## CenterContainer quando torna piccolo, e la finestra restava alta il doppio finche' non la si riapriva.
func _fit_inventory_after_frame() -> void:
	await get_tree().process_frame
	if not is_inside_tree() or not _inventory_window.visible:
		return
	_inventory_panel.reset_size()
	_inventory_window.queue_sort()
	_fit_inventory_to_viewport()


func _refresh() -> void:
	_refresh_stash(_stash_override if _bag_animating else MetaProgression.inventory.to_dictionary())
	_blacksmith.refresh(MetaProgression.inventory, MetaProgression.loadout, _material_names, MetaProgression.ascension_caps)
	_loadout_panel.refresh(MetaProgression.loadout, [], MetaProgression.bags)
	_arena_select.refresh(MetaProgression.arena_catalog, MetaProgression.extractions, MetaProgression.current_arena().id, _arena_level())
	# Statistiche con l'equipaggiamento attuale: lo stesso calcolo di inizio run, sul player della piazza.
	var equip_modifiers := MetaProgression.equipped_modifiers()
	_player.begin_run(equip_modifiers)
	var rows := StatSheet.equip_rows(_player.base_stats(), _player.base_weapon_data(), _player.stats, _player.weapon_data(), equip_modifiers)
	StatSheet.fill_with_equip(_hub_stats_grid, rows, 18)
	if _inventory_window.visible:
		_fit_inventory_after_frame()
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
		# Staccato subito (M13, #86): con il solo queue_free() vecchi e nuovi figli convivono fino a
		# fine frame, il contenitore raddoppia la dimensione minima e la finestra resta gonfia.
		_stash_list.remove_child(child)
		child.queue_free()
	_stash_label.visible = amounts.is_empty()
	_stash_labels.clear()
	_stash_icons.clear()
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
		_stash_labels[id] = label
		_stash_icons[id] = icon


func _on_craft_requested(recipe: RecipeData) -> void:
	if MetaProgression.craft(recipe) == Crafting.Result.OK:
		_sfx.play(&"craft")


func _on_fuse_requested(uids: Array[int]) -> void:
	if MetaProgression.fuse(uids):
		_sfx.play(&"craft")


func _on_salvage_requested(uid: int) -> void:
	if MetaProgression.salvage(uid):
		_sfx.play(&"pickup_item")


func _on_salvage_all_trash_requested() -> void:
	if not MetaProgression.salvage_all_trash().is_empty():
		_sfx.play(&"pickup_item")


func _on_ascend_requested(id: StringName) -> void:
	if MetaProgression.ascend(id):
		_sfx.play(&"craft")


## Livello arena dalla potenza dell'equip indossato (§6.3b): unico punto di calcolo per il pannello Portale.
func _arena_level() -> int:
	return ArenaLevel.level_for(MetaProgression.loadout.equipped_items())


## Ricostruisce il pannello con la nuova scelta evidenziata (M12, #86): senza, il testo/evidenziazione
## di ARENA_SELECTED restava sull'arena di refresh() iniziale finche' l'hub non veniva ricreato.
func _on_arena_selected(id: StringName) -> void:
	if MetaProgression.select_arena(id):
		_sfx.play(&"ui_select")
		# Anche il livello arena (M13, #86): senza, dopo aver cambiato arena il pannello mostrava Livello 1
		# (valore di default del parametro) finche' non lo si riapriva.
		_arena_select.refresh(MetaProgression.arena_catalog, MetaProgression.extractions, MetaProgression.current_arena().id, _arena_level())


## Posizione aggiornata prima di entrare in run (M12, #86): senza, l'autosave a fine run
## salvava la posizione della piazza rimasta ferma all'ultimo salvataggio manuale.
func _on_start_pressed() -> void:
	MetaProgression.set_hub_position(%Player.global_position)
	get_tree().paused = false
	get_tree().change_scene_to_file(SceneRoutes.ARENA)



## Bag of Resources (M13, #86): il sacchetto si gonfia e si apre, le risorse volano verso la loro riga
## nella lista Risorse e il contatore sale man mano che arrivano. Lo stato vero cambia subito
## (MetaProgression.open_bag); l'animazione e' solo presentazione sopra una copia dei valori.

func _on_bag_open_requested(from_global: Vector2) -> void:
	if _bag_animating or MetaProgression.bags <= 0:
		return
	_bag_animating = true
	_stash_override = MetaProgression.inventory.to_dictionary()
	var content := MetaProgression.open_bag()
	for id in content:
		if not _stash_override.has(id):
			_stash_override[id] = 0
	_refresh()
	_sfx.play(&"pickup_item")
	await _play_bag_open(from_global)
	# Aspetta il layout della lista (riga nuova) prima di leggere dove stanno le icone.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var arrivals: Array[Signal] = []
	for id in content:
		arrivals.append(_fly_resources(from_global, id, content[id]))
	for arrival in arrivals:
		await arrival
	if not is_inside_tree():
		return
	_stash_override.clear()
	_bag_animating = false
	_refresh()


## Sacchetto che si gonfia, oscilla e sparisce sul punto del clic (nodo top_level: fuori dal layout).
func _play_bag_open(at: Vector2) -> Signal:
	var bag := _fly_node(MetaProgression.resource_bag.icon, at, 56.0)
	var tween := bag.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(bag, "scale", Vector2(1.35, 1.35), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(bag, "rotation", 0.25, 0.06)
	tween.tween_property(bag, "rotation", -0.25, 0.08)
	tween.tween_property(bag, "rotation", 0.0, 0.06)
	tween.parallel().tween_property(bag, "scale", Vector2(1.6, 1.6), 0.14)
	tween.parallel().tween_property(bag, "modulate:a", 0.0, 0.14)
	tween.tween_callback(bag.queue_free)
	return tween.finished


## Icone della risorsa che volano dal sacchetto alla sua riga; ogni arrivo aggiunge la sua parte al
## contatore mostrato. Ritorna il segnale di fine dell'ultima.
func _fly_resources(from_global: Vector2, id: StringName, amount: int) -> Signal:
	var icon_node: TextureRect = _stash_icons.get(id)
	var target := icon_node.get_global_rect().get_center() if icon_node else from_global
	var pieces := mini(BAG_FLY_PIECES, maxi(amount, 1))
	var last: Tween
	for i in pieces:
		var share := floori(float(amount) / pieces) + (1 if i < amount % pieces else 0)
		var piece := _fly_node(_material_icons.get(id), from_global, 28.0)
		var mid := from_global.lerp(target, 0.5) + Vector2(randf_range(-60.0, 60.0), randf_range(-90.0, -30.0))
		var tween := piece.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_interval(i * BAG_FLY_STAGGER)
		tween.tween_method(func(t: float) -> void:
			var a := from_global.lerp(mid, t)
			var b := mid.lerp(target, t)
			piece.global_position = a.lerp(b, t) - piece.size * 0.5, 0.0, 1.0, BAG_FLY_TIME).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(_on_resource_arrived.bind(id, share))
		tween.tween_callback(piece.queue_free)
		last = tween
	return last.finished


func _on_resource_arrived(id: StringName, share: int) -> void:
	_stash_override[id] = _stash_override.get(id, 0) + share
	var label: Label = _stash_labels.get(id)
	if label == null:
		return
	label.text = "%s × %d" % [_material_names.get(id, String(id)), _stash_override[id]]
	label.pivot_offset = label.size * 0.5
	var pulse := label.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pulse.tween_property(label, "scale", Vector2(1.15, 1.15), 0.05)
	pulse.tween_property(label, "scale", Vector2.ONE, 0.1)
	_sfx.play(&"pickup_item")


func _fly_node(texture: Texture2D, center: Vector2, side: float) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.top_level = true
	node.size = Vector2.ONE * side
	node.pivot_offset = node.size * 0.5
	node.z_index = 10
	_inventory_window.add_child(node)
	node.global_position = center - node.size * 0.5
	return node
