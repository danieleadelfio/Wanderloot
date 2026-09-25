class_name Blacksmith
extends PanelContainer
## Pannello del fabbro, a schede: Crafting, Fusione, Smontaggio (M11, #59).
## Mostra lo stato e chiede le azioni via segnale: non scrive su MetaProgression.

signal craft_requested(recipe: RecipeData)
## Fonde i due oggetti (uid) indicati.
signal fuse_requested(first_uid: int, second_uid: int)
signal salvage_requested(uid: int)

const RARITIES: RarityTable = ItemText.RARITIES

@export var recipe_book: RecipeBook
## Smontaggio in lavorazione (#60): la resa futura sono materiali ottenibili solo smontando, ancora da definire.
## Da falso l'elenco resta visibile ma non si puo' smontare.
@export var salvage_enabled: bool = false

## Smontaggio irreversibile: il primo clic chiede conferma, il secondo smonta.
var _pending_salvage: int = 0

@onready var _tabs: TabContainer = %Tabs
@onready var _recipe_list: VBoxContainer = %RecipeList
@onready var _fusion_list: VBoxContainer = %FusionList
@onready var _salvage_list: VBoxContainer = %SalvageList
@onready var _resources_label: Label = %ResourcesLabel


func _ready() -> void:
	_tabs.set_tab_title(0, tr("BLACKSMITH_TAB_CRAFT"))
	_tabs.set_tab_title(1, tr("BLACKSMITH_TAB_FUSION"))
	_tabs.set_tab_title(2, tr("BLACKSMITH_TAB_SALVAGE"))


func refresh(inventory: MetaInventory, loadout: EquipmentLoadout, material_names: Dictionary[StringName, String]) -> void:
	_refresh_resources(inventory, material_names)
	_refresh_recipes(inventory, loadout, material_names)
	_refresh_fusion(loadout)
	_refresh_salvage(loadout, material_names)


## Risorse (materiali) attualmente possedute, sempre visibili sopra le schede (M12, #86):
## prima si dovevano controllare nel baule per sapere cosa si poteva craftare.
func _refresh_resources(inventory: MetaInventory, material_names: Dictionary[StringName, String]) -> void:
	var amounts := inventory.to_dictionary()
	_resources_label.text = tr("BLACKSMITH_RESOURCES") % _amounts_text(amounts, material_names) if not amounts.is_empty() else tr("BLACKSMITH_RESOURCES_EMPTY")


func _refresh_recipes(inventory: MetaInventory, loadout: EquipmentLoadout, material_names: Dictionary[StringName, String]) -> void:
	_clear(_recipe_list)
	for recipe in recipe_book.recipes:
		var state := Crafting.check(recipe, inventory)
		var detail := _amounts_text(recipe.cost_dictionary(), material_names)
		var owned := loadout.count_of(recipe.result.id)
		if owned > 0:
			detail += "  ·  " + tr("BLACKSMITH_OWNED_COUNT") % owned
		var button := _button(recipe.result.icon, "%s  —  %s" % [tr(recipe.result.display_name), detail], tr(recipe.result.description))
		button.disabled = state != Crafting.Result.OK
		button.pressed.connect(craft_requested.emit.bind(recipe))
		_recipe_list.add_child(button)


func _refresh_fusion(loadout: EquipmentLoadout) -> void:
	_clear(_fusion_list)
	var groups := Forge.fusion_groups(loadout, RARITIES)
	for group in groups:
		var first: ItemInstance = group[0]
		var second: ItemInstance = group[1]
		var next := RARITIES.tier(first.rarity + 1)
		var text := "%s  ×%d  →  %s" % [ItemText.title(first), group.size(), tr(next.display_name)]
		var button := _button(first.base.icon, text, ItemText.tooltip(first) + "\n\n" + ItemText.tooltip(second))
		button.add_theme_color_override("font_color", next.color)
		button.pressed.connect(fuse_requested.emit.bind(first.uid, second.uid))
		_fusion_list.add_child(button)
	if groups.is_empty():
		_fusion_list.add_child(_hint(tr("BLACKSMITH_FUSION_EMPTY")))


func _refresh_salvage(loadout: EquipmentLoadout, material_names: Dictionary[StringName, String]) -> void:
	_clear(_salvage_list)
	_pending_salvage = 0
	var items := loadout.stash_items()
	for item: ItemInstance in items:
		var text := ItemText.title(item)
		if salvage_enabled:
			text += "  —  " + _amounts_text(Forge.salvage_yield(item, recipe_book, RARITIES), material_names)
		var button := _button(item.base.icon, text, ItemText.tooltip(item))
		button.add_theme_color_override("font_color", ItemText.color(item))
		button.disabled = not salvage_enabled
		button.pressed.connect(_on_salvage_pressed.bind(item.uid, button))
		_salvage_list.add_child(button)
	if items.is_empty():
		_salvage_list.add_child(_hint(tr("BLACKSMITH_SALVAGE_EMPTY")))


func _on_salvage_pressed(uid: int, button: Button) -> void:
	if _pending_salvage == uid:
		_pending_salvage = 0
		salvage_requested.emit(uid)
		return
	_pending_salvage = uid
	button.text = tr("BLACKSMITH_SALVAGE_CONFIRM") % button.text


func _button(icon: Texture2D, text: String, tooltip: String) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.icon = icon
	button.add_theme_constant_override("icon_max_width", 32)
	button.expand_icon = true
	button.custom_minimum_size.y = 36
	# Testo lungo: si tronca il testo, non l'icona.
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return button


func _hint(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	return label


func _amounts_text(amounts: Dictionary[StringName, int], material_names: Dictionary[StringName, String]) -> String:
	var parts: PackedStringArray = []
	for id in amounts:
		parts.append("%d %s" % [amounts[id], material_names.get(id, String(id))])
	return ", ".join(parts)


func _clear(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
