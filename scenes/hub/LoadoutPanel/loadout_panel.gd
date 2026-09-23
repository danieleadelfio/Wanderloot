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
	button.text = "%s  (%s)%s" % [item.display_name, item.description, "  [equipaggiato]" if equipped else ""]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if equipped:
		button.pressed.connect(unequip_requested.emit.bind(item.slot))
	else:
		button.pressed.connect(equip_requested.emit.bind(item))
	return button
