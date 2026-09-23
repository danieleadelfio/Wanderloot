extends Node
## Progressione permanente (meta): inventario materiali persistito in user:// (ConfigFile).
## Unico punto di scrittura dall'esterno: deposit_run_loot(), chiamato solo dopo un'estrazione riuscita.

signal changed

const SAVE_PATH: String = "user://meta_progression.cfg"
const SAVE_VERSION: int = 1
const SECTION_META: String = "meta"
const SECTION_MATERIALS: String = "materials"

var inventory: MetaInventory = MetaInventory.new()
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
