extends Node
## Progressione permanente (meta): materiali ed equipaggiamento, persistiti in user:// (ConfigFile).
## Il loot entra solo da deposit_run_loot(), chiamato solo dopo un'estrazione riuscita.

signal changed

const SAVE_PATH: String = "user://meta_progression.cfg"
## v1 (M2): solo materiali. v2 (M3): + equipaggiamento posseduto/equipaggiato. Un file v1 si carica con loadout vuoto.
const SAVE_VERSION: int = 2
const SECTION_META: String = "meta"
const SECTION_MATERIALS: String = "materials"
const SECTION_EQUIPMENT: String = "equipment"
const SECTION_EQUIPPED: String = "equipped"

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
		save_to_disk()
		changed.emit()


func unequip(slot: EquipmentData.Slot) -> void:
	loadout.unequip(slot)
	save_to_disk()
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
	config.set_value(SECTION_EQUIPMENT, "owned", PackedStringArray(loadout.owned_ids()))
	var equipped := loadout.equipped_ids()
	for slot in equipped:
		config.set_value(SECTION_EQUIPPED, _slot_key(slot), String(equipped[slot]))
	var error := config.save(save_path)
	if error != OK:
		push_error("MetaProgression: salvataggio fallito (%s): %s" % [save_path, error_string(error)])
	return error


## ERR_FILE_NOT_FOUND al primo avvio e' normale: inventario e loadout vuoti.
## Id di equipaggiamento sconosciuti al catalogo (o equipaggiati senza possederli) vengono scartati.
func load_from_disk() -> Error:
	var config := ConfigFile.new()
	var error := config.load(save_path)
	var amounts: Dictionary[StringName, int] = {}
	loadout.clear()
	if error == OK:
		if config.has_section(SECTION_MATERIALS):
			for key in config.get_section_keys(SECTION_MATERIALS):
				amounts[StringName(key)] = int(config.get_value(SECTION_MATERIALS, key, 0))
		_load_loadout(config)
	inventory.load_dictionary(amounts)
	changed.emit()
	return error


func _load_loadout(config: ConfigFile) -> void:
	for id in PackedStringArray(config.get_value(SECTION_EQUIPMENT, "owned", PackedStringArray())):
		if catalog.find(StringName(id)) != null:
			loadout.add_owned(StringName(id))
	for slot: int in EquipmentData.Slot.values():
		var item := catalog.find(StringName(config.get_value(SECTION_EQUIPPED, _slot_key(slot), "")))
		if item != null and item.slot == slot:
			loadout.equip(item)


func _slot_key(slot: int) -> String:
	return String(EquipmentData.Slot.find_key(slot)).to_lower()
