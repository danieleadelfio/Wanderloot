class_name LoadoutPanel
extends PanelContainer
## Pannello equipaggiamento: per ogni slot i pezzi posseduti; click = equipaggia/togli. Richieste via segnale.

signal equip_requested(item: EquipmentData)
signal unequip_requested(slot: EquipmentData.Slot)

const SLOT_NAMES: Dictionary[int, String] = {
	EquipmentData.Slot.WEAPON: "Arma",
	EquipmentData.Slot.ACCESSORY: "Accessorio",
}

@export var catalog: EquipmentCatalog

@onready var _slot_list: VBoxContainer = %SlotList


func refresh(loadout: EquipmentLoadout) -> void:
	for child in _slot_list.get_children():
		child.queue_free()
	for slot: int in EquipmentData.Slot.values():
		var header := Label.new()
		var equipped := catalog.find(loadout.equipped_id(slot))
		header.text = "%s: %s" % [SLOT_NAMES[slot], equipped.display_name if equipped else "nessuno"]
		_slot_list.add_child(header)
		var owned_any := false
		for item in catalog.items:
			if item.slot != slot or not loadout.owns(item.id):
				continue
			owned_any = true
			_slot_list.add_child(_item_button(item, loadout.is_equipped(item.id)))
		if not owned_any:
			var hint := Label.new()
			hint.text = "  nessun pezzo: craftalo dal fabbro"
			hint.modulate = Color(1, 1, 1, 0.5)
			_slot_list.add_child(hint)


func _item_button(item: EquipmentData, equipped: bool) -> Button:
	var button := Button.new()
	button.text = "%s  —  %s" % [item.display_name, "equipaggiato" if equipped else item.description]
	button.tooltip_text = item.description
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.icon = item.icon
	button.add_theme_constant_override("icon_max_width", 32)
	button.expand_icon = true
	button.custom_minimum_size.y = 36
	# Testo lungo: si tronca il testo, non l'icona.
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if equipped:
		button.pressed.connect(unequip_requested.emit.bind(item.slot))
	else:
		button.pressed.connect(equip_requested.emit.bind(item))
	return button
