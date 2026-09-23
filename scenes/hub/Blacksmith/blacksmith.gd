class_name Blacksmith
extends PanelContainer
## Pannello del fabbro: mostra le ricette e chiede il craft via segnale. Non scrive su MetaProgression.

signal craft_requested(recipe: RecipeData)

@export var recipe_book: RecipeBook

@onready var _recipe_list: VBoxContainer = %RecipeList


func refresh(inventory: MetaInventory, loadout: EquipmentLoadout, material_names: Dictionary[StringName, String]) -> void:
	for child in _recipe_list.get_children():
		child.queue_free()
	for recipe in recipe_book.recipes:
		var state := Crafting.check(recipe, inventory, loadout)
		var button := Button.new()
		var detail := "posseduto" if state == Crafting.Result.ALREADY_OWNED else _cost_text(recipe, material_names)
		button.text = "%s  —  %s" % [recipe.result.display_name, detail]
		button.tooltip_text = recipe.result.description
		button.icon = recipe.result.icon
		button.add_theme_constant_override("icon_max_width", 32)
		button.expand_icon = true
		button.custom_minimum_size.y = 36
		# Testo lungo: si tronca il testo, non l'icona.
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.disabled = state != Crafting.Result.OK
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(craft_requested.emit.bind(recipe))
		_recipe_list.add_child(button)


func _cost_text(recipe: RecipeData, material_names: Dictionary[StringName, String]) -> String:
	var parts: PackedStringArray = []
	var costs := recipe.cost_dictionary()
	for id in costs:
		parts.append("%d %s" % [costs[id], material_names.get(id, String(id))])
	return ", ".join(parts)
