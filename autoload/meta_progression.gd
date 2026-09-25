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
## v4 (M9): + posizione del player nella piazza (solo se si e' salvato dall'hub).
## v5 (M11): oggetti come istanze (sezione items, uid -> dizionario) e slot indossati per uid.
## Ogni versione carica le precedenti (sezioni mancanti = valori iniziali).
const SAVE_VERSION: int = 5
const SECTION_META: String = "meta"
const SECTION_MATERIALS: String = "materials"
const SECTION_EQUIPMENT: String = "equipment"
const SECTION_EQUIPPED: String = "equipped"
const SECTION_EXTRACTIONS: String = "extractions"
const SECTION_HUB: String = "hub"
const SECTION_ITEMS: String = "items"
const SECTION_ASCENSION: String = "ascension"

var inventory: MetaInventory = MetaInventory.new()
var loadout: EquipmentLoadout = EquipmentLoadout.new()
## Risolve gli id di equipaggiamento in Resource. Sovrascrivibile nei test.
var catalog: EquipmentCatalog = preload("res://data/equipment/equipment_catalog.tres")
## Arene disponibili. Sovrascrivibile nei test.
var arena_catalog: ArenaCatalog = preload("res://data/arenas/arena_catalog.tres")
## Per ritrovare le abilita' degli oggetti Super rari e superiori.
var ability_catalog: AbilityCatalog = preload("res://data/abilities/ability_catalog.tres")
var rarity_table: RarityTable = preload("res://data/equipment/rarity_table.tres")
var affix_table: AffixTable = preload("res://data/equipment/affix_table.tres")
var recipe_book: RecipeBook = preload("res://data/recipes/recipe_book.tres")
var _rng := RandomNumberGenerator.new()
## Estrazioni riuscite per id di arena.
var extractions: Dictionary[StringName, int] = {}
var selected_arena: StringName = &""
## Sovrascrivibile nei test per non toccare il salvataggio reale.
var save_path: String = SAVE_PATH
## Vero se lo stato in memoria differisce dall'ultimo salvataggio/caricamento.
var has_unsaved_changes: bool = false
## Posizione nella piazza da scrivere col prossimo salvataggio (impostata dall'hub prima di salvare).
var _hub_position: Vector2 = Vector2.ZERO
var _has_hub_position: bool = false
## Posizione letta dall'ultimo caricamento, consumata dall'hub alla sua apertura.
var _pending_hub_position: Vector2 = Vector2.ZERO
var _has_pending_hub_position: bool = false
## Autosave a fine run (M12, #86), consumato dall'hub alla sua apertura per mostrare il toast.
var _pending_autosave_notice: bool = false
## Cap sbloccato per abilita' (id -> livello, M12 #86 #16/#20): solo le voci > 1 (default implicito Lv1).
## Alzato dall'Ascensione (fabbro), consumato dalla run per il cap di WandAbilities.
var ascension_caps: Dictionary[StringName, int] = {}


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
	ascension_caps.clear()
	has_unsaved_changes = false
	_has_hub_position = false
	_has_pending_hub_position = false
	changed.emit()


## Salvando dalla piazza si memorizza la posizione del player; salvando in run no (la run non si riprende).
func set_hub_position(position: Vector2) -> void:
	_hub_position = position
	_has_hub_position = true


func clear_hub_position() -> void:
	_has_hub_position = false


func has_pending_hub_position() -> bool:
	return _has_pending_hub_position


## Posizione da ripristinare nella piazza dopo un caricamento; la consuma (vale una volta sola).
func take_pending_hub_position() -> Vector2:
	_has_pending_hub_position = false
	return _pending_hub_position


## Unico punto di scrittura su disco: chiamato dal giocatore (Salva nel menu di pausa) o in autonomia da autosave().
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


## Salvataggio automatico a fine run, successo o game over (M12, #86). Stessa scrittura di save_game();
## imposta solo il flag per il toast "Salvataggio automatico..." mostrato dall'hub al ritorno.
func autosave() -> bool:
	var ok := save_game() == OK
	if ok:
		_pending_autosave_notice = true
	return ok


func take_pending_autosave_notice() -> bool:
	if not _pending_autosave_notice:
		return false
	_pending_autosave_notice = false
	return true


func delete_save() -> Error:
	if not has_save():
		return ERR_FILE_NOT_FOUND
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func deposit_run_loot(loot: Dictionary[StringName, int]) -> void:
	if loot.is_empty():
		return
	inventory.deposit(loot)
	_mark_changed()



## Oggetti trovati in run, dopo un'estrazione riuscita: entrano nel baule con un uid nuovo.
func deposit_run_items(items: Array[ItemInstance]) -> void:
	if items.is_empty():
		return
	for item in items:
		item.is_new = true
		loadout.add(item)
	_mark_changed()


## Unico punto di crafting: regole in Crafting (logica pura), qui solo stato e notifica.
func craft(recipe: RecipeData) -> Crafting.Result:
	var result := Crafting.check(recipe, inventory)
	if result == Crafting.Result.OK:
		var crafted := Crafting.craft(recipe, inventory, loadout, make_item)
		if crafted:
			crafted.is_new = true
		_mark_changed()
	return result


## Crea l'istanza di un oggetto craftato: Comune con i bonus tirati.
func make_item(base: EquipmentData, tier: int = 0) -> ItemInstance:
	return ItemRoller.roll(base, tier, rarity_table, affix_table, ability_catalog, _rng)


## Fusione dal fabbro (regole in Forge): ritorna il nuovo oggetto o null.
func fuse(first_uid: int, second_uid: int) -> ItemInstance:
	var fused := Forge.fuse(loadout.get_item(first_uid), loadout.get_item(second_uid), loadout, rarity_table, make_item)
	if fused:
		fused.is_new = true
		_mark_changed()
	return fused


func salvage_yield(item: ItemInstance) -> Dictionary[StringName, int]:
	return Forge.salvage_yield(item, recipe_book, rarity_table)


## Smontaggio di un oggetto del baule in materiali.
func salvage(uid: int) -> bool:
	var item := loadout.get_item(uid)
	if item == null or not Forge.salvage(item, loadout, inventory, salvage_yield(item)):
		return false
	_mark_changed()
	return true


func equip(uid: int) -> void:
	var item := loadout.get_item(uid)
	if item:
		item.is_new = false
	if loadout.equip(uid):
		_mark_changed()


## Oggetto guardato (passaggio del mouse): perde la N. Da salvare, ma senza ridisegnare l'inventario.
func mark_seen(uid: int) -> void:
	var item := loadout.get_item(uid)
	if item and item.is_new:
		item.is_new = false
		has_unsaved_changes = true


func unequip(slot: int) -> void:
	loadout.unequip(slot)
	_mark_changed()


## Istanze indossate (per l'inventario di run e le statistiche).
func equipped_items() -> Array[ItemInstance]:
	return loadout.equipped_items()


## Modificatori di tutto l'equipaggiamento indossato: e' cio' che la run applica alle stats iniziali.
func equipped_modifiers() -> Array[StatModifier]:
	var result: Array[StatModifier] = []
	for item in loadout.equipped_items():
		result.append_array(item.modifiers())
	return result


## Abilita' date dagli oggetti indossati (Super raro e superiori): attive per tutta la run.
func equipped_abilities() -> Array[WandAbility]:
	var result: Array[WandAbility] = []
	for item in loadout.equipped_items():
		if item.ability and not result.has(item.ability):
			result.append(item.ability)
	return result



## Livelli delle abilita' degli oggetti indossati, sommati per abilita' (id -> [abilita', livello]).
func equipped_ability_levels() -> Dictionary:
	var result := {}
	for item in loadout.equipped_items():
		if item.ability:
			var entry: Array = result.get(item.ability.id, [item.ability, 0])
			entry[1] += item.ability_level(rarity_table)
			result[item.ability.id] = entry
	return result


## Cap sbloccato per l'abilita' (#20): default Lv1, alzabile con ascend() fino a WandAbility.MAX_LEVEL.
func ascension_cap(id: StringName) -> int:
	return ascension_caps.get(id, 1)


## Costo per alzare di un livello il cap dell'abilita'; vuoto se gia' al tetto assoluto.
func ascension_cost(id: StringName) -> Dictionary[StringName, int]:
	return Ascension.cost_for(ascension_cap(id) + 1)


func can_ascend(id: StringName) -> bool:
	var cost := ascension_cost(id)
	return not cost.is_empty() and inventory.can_afford(cost)


## Spende i materiali e alza il cap sbloccato dell'abilita' di 1 (fabbro, scheda Ascensione).
func ascend(id: StringName) -> bool:
	if not can_ascend(id):
		return false
	inventory.spend(ascension_cost(id))
	ascension_caps[id] = ascension_cap(id) + 1
	_mark_changed()
	return true


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
	for item in loadout.all_items():
		config.set_value(SECTION_ITEMS, str(item.uid), item.to_dict())
	var equipped := loadout.equipped_slots()
	for slot in equipped:
		config.set_value(SECTION_EQUIPPED, EquipmentLoadout.slot_key(slot), equipped[slot])
	for arena_id in extractions:
		config.set_value(SECTION_EXTRACTIONS, String(arena_id), extractions[arena_id])
	for ability_id in ascension_caps:
		config.set_value(SECTION_ASCENSION, String(ability_id), ascension_caps[ability_id])
	config.set_value(SECTION_META, "selected_arena", String(selected_arena))
	if _has_hub_position:
		config.set_value(SECTION_HUB, "player_position", _hub_position)
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
	ascension_caps.clear()
	if error == OK:
		if config.has_section(SECTION_EXTRACTIONS):
			for key in config.get_section_keys(SECTION_EXTRACTIONS):
				extractions[StringName(key)] = int(config.get_value(SECTION_EXTRACTIONS, key, 0))
		if config.has_section(SECTION_ASCENSION):
			for key in config.get_section_keys(SECTION_ASCENSION):
				ascension_caps[StringName(key)] = int(config.get_value(SECTION_ASCENSION, key, 1))
		selected_arena = StringName(config.get_value(SECTION_META, "selected_arena", ""))
		_has_pending_hub_position = config.has_section_key(SECTION_HUB, "player_position")
		if _has_pending_hub_position:
			_pending_hub_position = config.get_value(SECTION_HUB, "player_position", Vector2.ZERO)
			_hub_position = _pending_hub_position
		_has_hub_position = _has_pending_hub_position
		if config.has_section(SECTION_MATERIALS):
			for key in config.get_section_keys(SECTION_MATERIALS):
				amounts[StringName(key)] = int(config.get_value(SECTION_MATERIALS, key, 0))
		_load_loadout(config)
	inventory.load_dictionary(amounts)
	changed.emit()
	return error


func _load_loadout(config: ConfigFile) -> void:
	var version := int(config.get_value(SECTION_META, "version", 1))
	if version >= 5:
		if config.has_section(SECTION_ITEMS):
			for key in config.get_section_keys(SECTION_ITEMS):
				var item := ItemInstance.from_dict(config.get_value(SECTION_ITEMS, key, {}), catalog, ability_catalog)
				if item:
					item.uid = int(key)
					loadout.add(item)
		if config.has_section(SECTION_EQUIPPED):
			for key in config.get_section_keys(SECTION_EQUIPPED):
				var slot := EquipmentLoadout.EquipSlot.keys().find(key.to_upper())
				var item := loadout.get_item(int(config.get_value(SECTION_EQUIPPED, key, 0)))
				if slot >= 0 and item and EquipmentLoadout.slots_for(item.slot()).has(slot):
					loadout.equip(item.uid)
		return
	# v2-v4: pezzi posseduti per id -> un'istanza Comune ciascuno, equipaggiati come prima.
	var migrated: Dictionary[StringName, int] = {}
	for id in PackedStringArray(config.get_value(SECTION_EQUIPMENT, "owned", PackedStringArray())):
		var base := catalog.find(StringName(id))
		if base != null and not migrated.has(base.id):
			migrated[base.id] = loadout.add(ItemInstance.new(base)).uid
	for key in ["weapon", "accessory"]:
		var equipped_id := StringName(config.get_value(SECTION_EQUIPPED, key, ""))
		if migrated.has(equipped_id):
			loadout.equip(migrated[equipped_id])


func _mark_changed() -> void:
	has_unsaved_changes = true
	changed.emit()
