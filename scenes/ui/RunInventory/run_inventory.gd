class_name RunInventory
extends CanvasLayer
## Inventario di run (tasto I): manichino con l'equipaggiamento indossato (tooltip con statistiche) e,
## accanto, il loot raccolto nella run (a rischio) in una griglia scorrevole con tooltip e confronto.
## Occupa la meta' destra dello schermo; la pausa la gestisce la composition root.

const LOOT_COLOR: Color = Color(1, 0.8, 0.35)

## Per nomi e icone del loot; id sconosciuti non mostrati.
@export var materials: Array[MaterialData] = []

@onready var _panel: Control = %Panel
@onready var _mannequin: LoadoutPanel = %Mannequin
@onready var _stats_grid: GridContainer = %StatsGrid
@onready var _loot_grid: GridContainer = %LootGrid
@onready var _empty: Label = %LootEmpty
@onready var _loot_total: Label = %LootTotal


func _ready() -> void:
	_panel.hide()


func close() -> void:
	_panel.hide()


func present(loadout: EquipmentLoadout, loot: Dictionary[StringName, int], items: Array[ItemInstance] = [], player: Player = null, equip_modifiers: Array[StatModifier] = []) -> void:
	_mannequin.refresh(loadout)
	if player:
		var rows := StatSheet.equip_rows(player.base_stats(), player.base_weapon_data(), player.stats, player.weapon_data(), equip_modifiers)
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
	_panel.show()
