extends Node
## Progressione permanente (meta): materiali ed equipaggiamento, persistiti in user:// (ConfigFile).
## Il loot entra solo da deposit_run_loot(), chiamato solo dopo un'estrazione riuscita.

signal changed

const SAVE_PATH: String = "user://meta_progression.cfg"
const SAVE_VERSION: int = 1
const SECTION_META: String = "meta"
const SECTION_MATERIALS: String = "materials"

var inventory: MetaInventory = MetaInventory.new()
var loadout: EquipmentLoadout = EquipmentLoadout.new()
## Risolve gli id di equipaggiamento in Resource. Sovrascrivibile nei test.
var catalog: EquipmentCatalog = preload("res://data/equipment/equipment_catalog.tres")
## Sovrascrivibile nei test per non toccare il salvataggio reale.
var save_path: String = SAVE_PATH


func _ready() -> void:
	load_from_disk()


func deposit_run_loot(loot: Dictionary[StringName, int]) -> void:
	if loot.is_empty():
		return
	inventory.deposit(loot)
	save_to_disk()
	changed.emit()


## Unico punto di crafting: regole in Crafting (logica pura), qui solo salvataggio e notifica.
func craft(recipe: RecipeData) -> Crafting.Result:
	var result := Crafting.craft(recipe, inventory, loadout)
	if result == Crafting.Result.OK:
		save_to_disk()
		changed.emit()
	return result


func equip(item: EquipmentData) -> void:
	if loadout.equip(item):
		changed.emit()


func unequip(slot: EquipmentData.Slot) -> void:
	loadout.unequip(slot)
	changed.emit()


## Pezzi equipaggiati, risolti dal catalogo: e' cio' che la run applica alle stats iniziali.
func equipped_items() -> Array[EquipmentData]:
	var items: Array[EquipmentData] = []
	for id in loadout.equipped_ids().values():
		var item := catalog.find(id)
		if item != null:
			items.append(item)
	return items


func save_to_disk() -> Error:
	var config := ConfigFile.new()
	config.set_value(SECTION_META, "version", SAVE_VERSION)
	var amounts := inventory.to_dictionary()
	for id in amounts:
		config.set_value(SECTION_MATERIALS, String(id), amounts[id])
	var error := config.save(save_path)
	if error != OK:
		push_error("MetaProgression: salvataggio fallito (%s): %s" % [save_path, error_string(error)])
	return error


## ERR_FILE_NOT_FOUND al primo avvio e' normale: inventario vuoto.
func load_from_disk() -> Error:
	var config := ConfigFile.new()
	var error := config.load(save_path)
	var amounts: Dictionary[StringName, int] = {}
	if error == OK and config.has_section(SECTION_MATERIALS):
		for key in config.get_section_keys(SECTION_MATERIALS):
			amounts[StringName(key)] = int(config.get_value(SECTION_MATERIALS, key, 0))
	inventory.load_dictionary(amounts)
	changed.emit()
	return error
