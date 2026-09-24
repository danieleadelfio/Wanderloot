extends Node
## Progressione permanente (meta): materiali ed equipaggiamento, persistiti in user:// (ConfigFile).
## Da M8 i salvataggi sono solo manuali: le modifiche restano in memoria finche' non si chiama save_game().
## Il loot entra solo da deposit_run_loot(), chiamato solo dopo un'estrazione riuscita.
## Da M7 tiene anche le estrazioni riuscite per arena (sblocchi) e l'arena scelta al portale.

signal changed
signal saved

const SAVE_PATH: String = "user://save.cfg"
## File dei salvataggi automatici fino a M7: rimosso all'avvio (M8, si riparte da zero).
const LEGACY_SAVE_PATH: String = "user://meta_progression.cfg"
## v1 (M2): solo materiali. v2 (M3): + equipaggiamento. v3 (M7): + estrazioni per arena e arena scelta.
## Ogni versione carica le precedenti (sezioni mancanti = valori iniziali).
const SAVE_VERSION: int = 3
const SECTION_META: String = "meta"
const SECTION_MATERIALS: String = "materials"
const SECTION_EQUIPMENT: String = "equipment"
const SECTION_EQUIPPED: String = "equipped"
const SECTION_EXTRACTIONS: String = "extractions"

var inventory: MetaInventory = MetaInventory.new()
var loadout: EquipmentLoadout = EquipmentLoadout.new()
## Risolve gli id di equipaggiamento in Resource. Sovrascrivibile nei test.
var catalog: EquipmentCatalog = preload("res://data/equipment/equipment_catalog.tres")
## Arene disponibili. Sovrascrivibile nei test.
var arena_catalog: ArenaCatalog = preload("res://data/arenas/arena_catalog.tres")
## Estrazioni riuscite per id di arena.
var extractions: Dictionary[StringName, int] = {}
var selected_arena: StringName = &""
## Sovrascrivibile nei test per non toccare il salvataggio reale.
var save_path: String = SAVE_PATH
## Vero se lo stato in memoria differisce dall'ultimo salvataggio/caricamento.
var has_unsaved_changes: bool = false


func _ready() -> void:
	if FileAccess.file_exists(LEGACY_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SAVE_PATH))


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


## Nuova partita: stato vuoto in memoria. Il file su disco resta finche' non si salva o si cancella.
func new_game() -> void:
	inventory.load_dictionary({} as Dictionary[StringName, int])
	loadout.clear()
	extractions.clear()
	selected_arena = &""
	has_unsaved_changes = false
	changed.emit()


## Unico punto di scrittura su disco richiesto dal giocatore (Salva nel menu di pausa).
func save_game() -> Error:
	var error := save_to_disk()
	if error == OK:
		has_unsaved_changes = false
		saved.emit()
	return error


func load_game() -> Error:
	var error := load_from_disk()
	has_unsaved_changes = false
	return error


func delete_save() -> Error:
	if not has_save():
		return ERR_FILE_NOT_FOUND
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func deposit_run_loot(loot: Dictionary[StringName, int]) -> void:
	if loot.is_empty():
		return
	inventory.deposit(loot)
	_mark_changed()


## Unico punto di crafting: regole in Crafting (logica pura), qui solo stato e notifica.
func craft(recipe: RecipeData) -> Crafting.Result:
	var result := Crafting.craft(recipe, inventory, loadout)
	if result == Crafting.Result.OK:
		_mark_changed()
	return result


func equip(item: EquipmentData) -> void:
	if loadout.equip(item):
		_mark_changed()


func unequip(slot: EquipmentData.Slot) -> void:
	loadout.unequip(slot)
	_mark_changed()


## Pezzi equipaggiati, risolti dal catalogo: e' cio' che la run applica alle stats iniziali.
func equipped_items() -> Array[EquipmentData]:
	var items: Array[EquipmentData] = []
	for id in loadout.equipped_ids().values():
		var item := catalog.find(id)
		if item != null:
			items.append(item)
	return items


func register_extraction(arena_id: StringName) -> void:
	extractions[arena_id] = extractions.get(arena_id, 0) + 1
	_mark_changed()


## Seleziona l'arena per la prossima run; false se sconosciuta o bloccata.
func select_arena(arena_id: StringName) -> bool:
	var arena := arena_catalog.find(arena_id)
	if arena == null or not arena.is_unlocked(extractions):
		return false
	selected_arena = arena_id
	_mark_changed()
	return true


## Arena della prossima run: quella scelta se ancora valida e sbloccata, altrimenti la prima.
func current_arena() -> ArenaData:
	var arena := arena_catalog.find(selected_arena)
	if arena == null or not arena.is_unlocked(extractions):
		return arena_catalog.first()
	return arena


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
	for arena_id in extractions:
		config.set_value(SECTION_EXTRACTIONS, String(arena_id), extractions[arena_id])
	config.set_value(SECTION_META, "selected_arena", String(selected_arena))
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
	extractions.clear()
	selected_arena = &""
	if error == OK:
		if config.has_section(SECTION_EXTRACTIONS):
			for key in config.get_section_keys(SECTION_EXTRACTIONS):
				extractions[StringName(key)] = int(config.get_value(SECTION_EXTRACTIONS, key, 0))
		selected_arena = StringName(config.get_value(SECTION_META, "selected_arena", ""))
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


func _mark_changed() -> void:
	has_unsaved_changes = true
	changed.emit()


func _slot_key(slot: int) -> String:
	return String(EquipmentData.Slot.find_key(slot)).to_lower()
