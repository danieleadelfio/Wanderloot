class_name LoadoutPanel
extends PanelContainer
## Equipaggiamento con manichino (M11): 9 slot attorno alla sagoma e, a destra, gli oggetti nel baule.
## Clic su un oggetto del baule = va nel suo slot (anelli: prima lo slot libero); clic su uno slot occupato
## = l'oggetto torna nel baule. Solo presentazione: le richieste escono via segnale.

signal equip_requested(uid: int)
signal unequip_requested(slot: int)

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

@onready var _slots: Control = %Slots
@onready var _grid: GridContainer = %ItemGrid
@onready var _empty_hint: Label = %EmptyHint


func refresh(loadout: EquipmentLoadout) -> void:
	for child in _slots.get_children():
		child.queue_free()
	for slot: int in SLOT_POSITIONS:
		var item := loadout.equipped_in(slot)
		var button := _item_button(item, tr(SLOT_NAMES[slot]))
		button.position = SLOT_POSITIONS[slot]
		if item:
			button.pressed.connect(unequip_requested.emit.bind(slot))
		else:
			button.disabled = true
		_slots.add_child(button)
	for child in _grid.get_children():
		child.queue_free()
	var stash := loadout.stash_items()
	_empty_hint.visible = stash.is_empty()
	for item in stash:
		var button := _item_button(item, "")
		button.pressed.connect(equip_requested.emit.bind(item.uid))
		_grid.add_child(button)


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
