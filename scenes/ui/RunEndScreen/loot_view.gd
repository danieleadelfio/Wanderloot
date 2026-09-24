class_name LootView
extends Control
## Loot della run appena finita (M11.3, #68): icone di materiali e oggetti con tooltip al passaggio del mouse.
## Indietro torna al riepilogo; Torna all'hub resta sempre disponibile.

signal back_requested
signal hub_requested

@onready var _title: Label = %LootViewTitle
@onready var _grid: GridContainer = %LootGrid
@onready var _empty: Label = %LootEmpty


func _ready() -> void:
	hide()
	%LootBackButton.pressed.connect(back_requested.emit)
	%LootHubButton.pressed.connect(hub_requested.emit)


func present(extracted: bool, materials: Array[MaterialData], amounts: Dictionary, items: Array[ItemInstance]) -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_title.text = tr("LOOT_VIEW_EXTRACTED") if extracted else tr("LOOT_VIEW_LOST")
	_title.add_theme_color_override("font_color", Color(0.55, 1, 0.6) if extracted else Color(1, 0.45, 0.4))
	var sorted := items.duplicate()
	sorted.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool: return a.rarity > b.rarity)
	for value: ItemInstance in sorted:
		_grid.add_child(ItemTile.for_item(value))
	for material in materials:
		if amounts.get(material.id, 0) > 0:
			_grid.add_child(ItemTile.for_material(material, amounts[material.id]))
	_empty.visible = _grid.get_child_count() == 0
	show()
	%LootHubButton.grab_focus()
