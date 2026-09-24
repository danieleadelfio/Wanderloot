class_name LoadoutPanel
extends PanelContainer
## Pannello equipaggiamento: per ogni slot l'istanza indossata e quelle nel baule; click = equipaggia/togli.
## Richieste via segnale (sostituito dal manichino in M11 #56).

signal equip_requested(uid: int)
signal unequip_requested(slot: int)

const SLOT_NAMES: Dictionary[int, String] = {
	EquipmentLoadout.EquipSlot.WEAPON: "SLOT_WEAPON",
	EquipmentLoadout.EquipSlot.AMULET: "SLOT_ACCESSORY",
}

@onready var _slot_list: VBoxContainer = %SlotList


func refresh(loadout: EquipmentLoadout) -> void:
	for child in _slot_list.get_children():
		child.queue_free()
	for slot: int in EquipmentLoadout.EquipSlot.values():
		var header := Label.new()
		var equipped := loadout.equipped_in(slot)
		header.text = "%s: %s" % [tr(SLOT_NAMES[slot]), tr(equipped.base.display_name) if equipped else tr("SLOT_NONE")]
		_slot_list.add_child(header)
		if equipped:
			_slot_list.add_child(_item_button(equipped, true, slot))
		var any := false
		for item in loadout.stash_items():
			if EquipmentLoadout.slots_for(item.slot()).has(slot):
				any = true
				_slot_list.add_child(_item_button(item, false, slot))
		if not any and equipped == null:
			var hint := Label.new()
			hint.text = tr("LOADOUT_NO_ITEM")
			hint.modulate = Color(1, 1, 1, 0.5)
			_slot_list.add_child(hint)


func _item_button(item: ItemInstance, equipped: bool, slot: int) -> Button:
	var button := Button.new()
	button.text = "%s  —  %s" % [tr(item.base.display_name), tr("LOADOUT_EQUIPPED") if equipped else tr(item.base.description)]
	button.tooltip_text = tr(item.base.description)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.icon = item.base.icon
	button.add_theme_constant_override("icon_max_width", 32)
	button.expand_icon = true
	button.custom_minimum_size.y = 36
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if equipped:
		button.pressed.connect(unequip_requested.emit.bind(slot))
	else:
		button.pressed.connect(equip_requested.emit.bind(item.uid))
	return button
