class_name RunInventory
extends CanvasLayer
## Inventario di run (tasto I): pagina a tutto schermo identica all'inventario dell'hub (M12, #86),
## a due schede (stesso Panel 1080px, stesso TabContainer). Scheda Inventario: a sinistra il loot
## raccolto nella run (a rischio, si perde se muori) al posto del baule dell'hub; a destra il
## manichino con l'equipaggiamento indossato, sola lettura. Scheda Statistiche: valori live con i
## potenziamenti di run (StatSheet.run_rows, come l'HUD). La pausa la gestisce la composition root.

## Per nomi e icone del loot; id sconosciuti non mostrati.
@export var materials: Array[MaterialData] = []

@onready var _window: Control = %Window
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


func close() -> void:
	_window.hide()


func present(loadout: EquipmentLoadout, loot: Dictionary[StringName, int], items: Array[ItemInstance] = [], player: Player = null, equip_modifiers: Array[StatModifier] = []) -> void:
	_tabs.current_tab = 0
	_mannequin.refresh(loadout)
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
		var tile := ItemTile.for_item(item)
		for slot in EquipmentLoadout.slots_for(item.slot()):
			var worn := loadout.equipped_in(slot)
			if worn:
				tile.compare.append(worn)
		_loot_grid.add_child(tile)
		total += 1
	for material in materials:
		var amount: int = loot.get(material.id, 0)
		if amount > 0:
			_loot_grid.add_child(ItemTile.for_material(material, amount))
			total += amount
	_empty.visible = _loot_grid.get_child_count() == 0
	_loot_total.text = tr("RUNINV_TOTAL") % total
	_window.show()
