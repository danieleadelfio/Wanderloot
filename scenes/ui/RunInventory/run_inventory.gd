class_name RunInventory
extends CanvasLayer
## Inventario di run (tasto I): equipaggiamento indossato e loot raccolto nella run (a rischio).
## Occupa la meta' destra dello schermo; la pausa la gestisce la composition root.

const SLOT_NAMES: Dictionary[int, String] = {
	EquipmentData.Slot.WEAPON: "Arma",
	EquipmentData.Slot.ACCESSORY: "Accessorio",
}
const ICON_SIZE: Vector2 = Vector2(32, 32)
const LOOT_COLOR: Color = Color(1, 0.8, 0.35)

## Per nomi e icone del loot; id sconosciuti mostrati grezzi.
@export var materials: Array[MaterialData] = []

@onready var _panel: Control = %Panel
@onready var _equip_list: VBoxContainer = %EquipList
@onready var _loot_list: VBoxContainer = %LootList
@onready var _loot_total: Label = %LootTotal


func _ready() -> void:
	_panel.hide()


func close() -> void:
	_panel.hide()


func present(equipped: Array[EquipmentData], loot: Dictionary[StringName, int]) -> void:
	_clear(_equip_list)
	_clear(_loot_list)
	for slot: int in EquipmentData.Slot.values():
		var item: EquipmentData = null
		for candidate in equipped:
			if candidate.slot == slot:
				item = candidate
		var text := "%s: %s" % [SLOT_NAMES[slot], ("%s  (%s)" % [item.display_name, item.description]) if item else "nessuno"]
		_equip_list.add_child(_row(item.icon if item else null, text, Color.WHITE))
	var total := 0
	for id in loot:
		var material := _material(id)
		var name := material.display_name if material else String(id)
		_loot_list.add_child(_row(material.icon if material else null, "%s × %d" % [name, loot[id]], LOOT_COLOR))
		total += loot[id]
	if loot.is_empty():
		_loot_list.add_child(_row(null, "Niente, per ora.", Color(1, 1, 1, 0.5)))
	_loot_total.text = "Totale a rischio: %d  ·  si perde tutto se muori" % total
	_panel.show()


func _material(id: StringName) -> MaterialData:
	for material in materials:
		if material.id == id:
			return material
	return null


func _row(icon: Texture2D, text: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	var picture := TextureRect.new()
	picture.texture = icon
	picture.custom_minimum_size = ICON_SIZE
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(picture)
	row.add_child(label)
	return row


func _clear(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
