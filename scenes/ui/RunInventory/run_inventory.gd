class_name RunInventory
extends CanvasLayer
## Inventario di run (tasto I): pagina a tutto schermo identica all'inventario dell'hub (M12, #86),
## a due schede (stesso Panel, ridimensionato per stare nello schermo, stesso TabContainer). Scheda
## Inventario: a sinistra il loot raccolto nella run (a rischio, si perde se muori) al posto del
## baule dell'hub; a destra il manichino con l'equipaggiamento indossato, sola lettura — pezzi
## dell'armadio scelti in run (M13, #86) mostrati indossati li', non nel loot, pur restando a
## rischio (`run_equipped`, mai scritti sul vero EquipmentLoadout). Scheda Statistiche: valori live
## con i potenziamenti di run (StatSheet.run_rows, come l'HUD). La pausa la gestisce la composition root.

## Per nomi e icone del loot; id sconosciuti non mostrati.
@export var materials: Array[MaterialData] = []
@export var resource_bag: ResourceBagData = preload("res://data/items/resource_bag.tres")
## Frazione dello schermo entro cui il pannello deve stare (M13, #86: prima aveva larghezza fissa
## 1080px e poteva eccedere lo schermo su risoluzioni piu' piccole).
@export_range(0.5, 1.0, 0.01) var max_viewport_fraction: float = 0.92

@onready var _window: Control = %Window
@onready var _panel: PanelContainer = %Panel
@onready var _tabs: TabContainer = %Tabs
@onready var _mannequin: LoadoutPanel = %Mannequin
@onready var _stats_grid: GridContainer = %StatsGrid
@onready var _loot_grid: GridContainer = %LootGrid
@onready var _empty: Label = %LootEmpty
@onready var _loot_total: Label = %LootTotal


func _ready() -> void:
	_window.hide()
	_tabs.set_tab_title(0, tr("TAB_INVENTORY"))
	_tabs.set_tab_title(1, tr("TAB_STATS"))
	get_viewport().size_changed.connect(_fit_to_viewport)
	_panel.minimum_size_changed.connect(_fit_to_viewport, CONNECT_DEFERRED)


func close() -> void:
	_window.hide()


func present(loadout: EquipmentLoadout, loot: Dictionary[StringName, int], items: Array[ItemInstance] = [], player: Player = null, equip_modifiers: Array[StatModifier] = [], run_equipped: Array[ItemInstance] = [], bags: int = 0) -> void:
	_tabs.current_tab = 0
	_mannequin.refresh(loadout, run_equipped)
	if player:
		var rows := StatSheet.run_rows(player.base_stats(), player.base_weapon_data(), equip_modifiers, player.stats, player.weapon_data())
		StatSheet.fill_with_equip(_stats_grid, rows, 14)
	for child in _loot_grid.get_children():
		_loot_grid.remove_child(child)
		child.queue_free()
	var total := 0
	var sorted := items.duplicate()
	sorted.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool: return a.rarity > b.rarity)
	for item: ItemInstance in sorted:
		# Gia' mostrato indossato sul manichino (armadio, M13, #86): non anche nel mucchio del loot.
		if run_equipped.has(item):
			continue
		var tile := ItemTile.for_item(item)
		for slot in EquipmentLoadout.slots_for(item.slot()):
			var worn := loadout.equipped_in(slot)
			if worn:
				tile.compare.append(worn)
		_loot_grid.add_child(tile)
		total += 1
	# Bag of Resources chiusi (M13, #86): a rischio come il resto, si aprono nella piazza.
	if bags > 0 and resource_bag:
		_loot_grid.add_child(ItemTile.for_bag(resource_bag, bags))
		total += bags
	for material in materials:
		var amount: int = loot.get(material.id, 0)
		if amount > 0:
			_loot_grid.add_child(ItemTile.for_material(material, amount))
			total += amount
	# Nel layout sempre, solo trasparente: mostrarlo/nasconderlo cambiava l'altezza della finestra (M13, #86).
	_empty.modulate.a = 1.0 if _loot_grid.get_child_count() == 0 else 0.0
	_loot_total.text = tr("RUNINV_TOTAL") % total
	_window.show()
	_window.queue_sort()
	await get_tree().process_frame
	if is_inside_tree():
		_fit_to_viewport()


## Rimpicciolisce il pannello (attorno al proprio centro, il CenterContainer lo ricentra da solo)
## se il suo contenuto eccede max_viewport_fraction dello schermo (M13, #86). Logica condivisa con la
## finestra Inventario dell'hub (UiFit).
func _fit_to_viewport() -> void:
	if not _window.visible:
		return
	UiFit.fit(_window, _panel, get_viewport().get_visible_rect().size, max_viewport_fraction)
