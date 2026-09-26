class_name LoadoutPanel
extends PanelContainer
## Equipaggiamento con manichino (M11): 9 slot attorno alla sagoma e, a destra, gli oggetti nel baule.
## Clic su un oggetto del baule = va nel suo slot (anelli: prima lo slot libero); clic su uno slot occupato
## = l'oggetto torna nel baule. Solo presentazione: le richieste escono via segnale.

signal equip_requested(uid: int)
signal unequip_requested(slot: int)
## Oggetto nuovo guardato (perde la N).
signal seen_requested(uid: int)
## Tasto destro su un'icona del baule: segna/dissegna come spazzatura (M12, #86).
signal trash_toggled(uid: int)

const SLOT_SIZE := Vector2(60, 60)
## Posizione di ogni slot sul manichino (area 360x440).
const SLOT_POSITIONS: Dictionary[int, Vector2] = {
	EquipmentLoadout.EquipSlot.HEAD: Vector2(150, 8),
	EquipmentLoadout.EquipSlot.AMULET: Vector2(236, 60),
	EquipmentLoadout.EquipSlot.ARMOR: Vector2(150, 150),
	EquipmentLoadout.EquipSlot.GLOVES: Vector2(28, 190),
	EquipmentLoadout.EquipSlot.WEAPON: Vector2(272, 190),
	EquipmentLoadout.EquipSlot.RING_1: Vector2(28, 270),
	EquipmentLoadout.EquipSlot.RING_2: Vector2(272, 270),
	EquipmentLoadout.EquipSlot.PANTS: Vector2(150, 262),
	EquipmentLoadout.EquipSlot.BOOTS: Vector2(150, 372),
}
## Nome di ogni tipo di oggetto (filtro per categoria).
const CATEGORY_NAMES: Dictionary[int, String] = {
	EquipmentData.Slot.WEAPON: "SLOT_WEAPON", EquipmentData.Slot.ACCESSORY: "SLOT_ACCESSORY",
	EquipmentData.Slot.HEAD: "SLOT_HEAD", EquipmentData.Slot.GLOVES: "SLOT_GLOVES",
	EquipmentData.Slot.ARMOR: "SLOT_ARMOR", EquipmentData.Slot.PANTS: "SLOT_PANTS",
	EquipmentData.Slot.BOOTS: "SLOT_BOOTS", EquipmentData.Slot.RING: "SLOT_RING",
}
const SLOT_NAMES: Dictionary[int, String] = {
	EquipmentLoadout.EquipSlot.WEAPON: "SLOT_WEAPON",
	EquipmentLoadout.EquipSlot.AMULET: "SLOT_ACCESSORY",
	EquipmentLoadout.EquipSlot.HEAD: "SLOT_HEAD",
	EquipmentLoadout.EquipSlot.GLOVES: "SLOT_GLOVES",
	EquipmentLoadout.EquipSlot.ARMOR: "SLOT_ARMOR",
	EquipmentLoadout.EquipSlot.PANTS: "SLOT_PANTS",
	EquipmentLoadout.EquipSlot.BOOTS: "SLOT_BOOTS",
	EquipmentLoadout.EquipSlot.RING_1: "SLOT_RING",
	EquipmentLoadout.EquipSlot.RING_2: "SLOT_RING",
}

## Falso nell'inventario di run: solo il manichino (niente baule), in sola lettura (M11.4, #80).
@export var show_stash: bool = true
@export var read_only: bool = false
## Ridimensiona il manichino (area 360x440 e slot compresi): usato dall'inventario di run (M12, #86)
## per non eccedere lo schermo quando il baule e' nascosto e resta solo il manichino.
@export var figure_scale: float = 1.0

## Ordine del baule scelto: resta finche' il gioco e' aperto.
static var sort_mode: StashSort.Mode = StashSort.Mode.ARRIVAL
## Filtro del baule scelto (vedi StashSort.filtered).
static var filter_key: String = "all"
var _filter_keys: Array[String] = []

var _loadout: EquipmentLoadout

@onready var _figure: Control = %Figure
@onready var _slots: Control = %Slots
@onready var _grid: GridContainer = %ItemGrid
@onready var _empty_hint: Label = %EmptyHint
@onready var _ability_levels: Label = %AbilityLevels


func _ready() -> void:
	%Stash.visible = show_stash
	if figure_scale != 1.0:
		_figure.custom_minimum_size *= figure_scale
		_figure.scale = Vector2(figure_scale, figure_scale)
	_fill_filter()
	var group := ButtonGroup.new()
	for pair in [[%SortArrival, StashSort.Mode.ARRIVAL], [%SortRarity, StashSort.Mode.RARITY], [%SortCategory, StashSort.Mode.CATEGORY]]:
		var button: Button = pair[0]
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = pair[1] == sort_mode
		button.pressed.connect(_on_sort_pressed.bind(pair[1]))


func _fill_filter() -> void:
	var option: OptionButton = %Filter
	option.clear()
	_filter_keys.clear()
	var entries: Array = [["all", tr("FILTER_ALL")], ["new", tr("FILTER_NEW")]]
	for i in ItemText.RARITIES.tiers.size():
		entries.append(["rarity:%d" % i, tr(ItemText.RARITIES.tier(i).display_name)])
	for slot: int in EquipmentData.Slot.values():
		entries.append(["slot:%d" % slot, tr(CATEGORY_NAMES[slot])])
	for entry in entries:
		option.add_item(entry[1])
		_filter_keys.append(entry[0])
	option.select(maxi(_filter_keys.find(filter_key), 0))
	if not option.item_selected.is_connected(_on_filter_selected):
		option.item_selected.connect(_on_filter_selected)


func _on_filter_selected(index: int) -> void:
	filter_key = _filter_keys[index]
	if _loadout:
		refresh(_loadout)


func _on_sort_pressed(mode: StashSort.Mode) -> void:
	sort_mode = mode
	if _loadout:
		refresh(_loadout)


## overlay_items: pezzi mostrati indossati sul manichino senza toccare `loadout` (M13, #86: pezzo
## dell'armadio scelto in run, a rischio finche' non si estrae con successo, mai scritto nel vero
## EquipmentLoadout ne' nell'uid dell'ItemInstance). Primo slot libero tra quelli del suo tipo,
## altrimenti sostituisce visivamente il primo (sola presentazione, sempre read_only in pratica).
func refresh(loadout: EquipmentLoadout, overlay_items: Array[ItemInstance] = []) -> void:
	_loadout = loadout
	_refresh_ability_levels(loadout)
	# Bug (M12, #86): queue_free() lascia il nodo nell'albero fino a fine frame. Se refresh() viene
	# richiamato nello stesso frame (equip/unequip -> segnale -> refresh), i tile vecchi restavano
	# sovrapposti a quelli nuovi finche' non venivano liberati: un oggetto poteva apparire spostato in
	# cima alla griglia e non piu' cliccabile (il tile sopra era quello vecchio, gia' disconnesso).
	# Rimozione immediata invece che differita, cosi' la griglia non contiene mai doppioni.
	for child in _slots.get_children():
		_slots.remove_child(child)
		child.free()
	var overlay_by_slot := _assign_overlay_slots(overlay_items)
	for slot: int in SLOT_POSITIONS:
		var overlaid: bool = overlay_by_slot.has(slot)
		var item: ItemInstance = overlay_by_slot[slot] if overlaid else loadout.equipped_in(slot)
		var button: Button = ItemTile.for_item(item) if item else _item_button(null, tr(SLOT_NAMES[slot]))
		button.size = button.custom_minimum_size
		button.position = SLOT_POSITIONS[slot]
		if overlaid:
			button.focus_mode = Control.FOCUS_NONE
			button.tooltip_text += "\n" + tr("RUNINV_TEMP_EQUIP")
		elif item and not read_only:
			button.pressed.connect(unequip_requested.emit.bind(slot))
		elif item:
			button.focus_mode = Control.FOCUS_NONE
		else:
			button.disabled = true
		_slots.add_child(button)
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.free()
	var stash := StashSort.sorted(StashSort.filtered(loadout.stash_items(), filter_key), sort_mode)
	_empty_hint.visible = stash.is_empty()
	for item in stash:
		var tile := ItemTile.for_item(item)
		tile.focus_mode = Control.FOCUS_ALL
		for slot in EquipmentLoadout.slots_for(item.slot()):
			var worn := loadout.equipped_in(slot)
			if worn:
				tile.compare.append(worn)
		tile.pressed.connect(equip_requested.emit.bind(item.uid))
		tile.seen.connect(seen_requested.emit)
		tile.trash_toggled.connect(trash_toggled.emit)
		_grid.add_child(tile)


## Livelli totali di ogni abilita' data dai pezzi indossati (M12, #86), sommati come in run.
func _assign_overlay_slots(overlay_items: Array[ItemInstance]) -> Dictionary[int, ItemInstance]:
	var result: Dictionary[int, ItemInstance] = {}
	for item in overlay_items:
		var slots := EquipmentLoadout.slots_for(item.slot())
		var target: int = slots[0]
		for slot in slots:
			if not result.has(slot):
				target = slot
				break
		result[target] = item
	return result


func _refresh_ability_levels(loadout: EquipmentLoadout) -> void:
	var levels: Dictionary = {}
	for item in loadout.equipped_items():
		if item.ability:
			var entry: Array = levels.get(item.ability.id, [item.ability, 0])
			entry[1] += item.ability_level(ItemText.RARITIES)
			levels[item.ability.id] = entry
	if levels.is_empty():
		_ability_levels.text = tr("LOADOUT_ABILITY_NONE")
		return
	var parts: Array[String] = []
	for entry: Array in levels.values():
		var ability: WandAbility = entry[0]
		parts.append("%s Lv%d" % [TranslationServer.translate(ability.display_name), entry[1]])
	_ability_levels.text = tr("LOADOUT_ABILITY_LEVELS") % ", ".join(parts)


func _item_button(item: ItemInstance, empty_label: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = SLOT_SIZE
	button.size = SLOT_SIZE
	button.focus_mode = Control.FOCUS_ALL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.09, 0.14, 0.92)
	style.set_border_width_all(2)
	style.border_color = ItemText.color(item) if item else Color(0.4, 0.38, 0.48)
	style.set_corner_radius_all(6)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, style)
	if item:
		button.icon = item.base.icon
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.tooltip_text = ItemText.tooltip(item)
	else:
		button.text = empty_label
		button.add_theme_font_size_override("font_size", 10)
		button.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.8, 0.6))
		button.tooltip_text = empty_label
	return button
