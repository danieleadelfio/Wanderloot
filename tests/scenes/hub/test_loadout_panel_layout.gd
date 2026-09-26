extends GdUnitTestSuite
## Dimensione del LoadoutPanel (baule + manichino, hub e inventario di run) invariata qualunque cosa si
## equipaggi (M13, #86). Bug: equipaggiando la bacchetta e poi un anello la finestra Inventario dell'hub
## cambiava dimensione a ogni passo. Cause: la riga "Abilita' dall'equip" (autowrap) andava a capo su piu'
## righe quando cresceva l'elenco delle abilita', l'avviso "baule vuoto" entrava/usciva dal layout
## (visible) e la scala della finestra era ricalcolata sulla size corrente (gonfia per un frame).
## Qui si provano tutte le combinazioni rilevanti: ogni slot da solo, tutti gli slot, tutte le abilita'
## al massimo, ogni quantita' di oggetti nel baule, ogni filtro/ordinamento, in ogni lingua.

const LOCALES: Array[String] = ["it", "en", "fr", "es"]
const SLOT_BASES: Dictionary[int, String] = {
	EquipmentLoadout.EquipSlot.WEAPON: "res://data/equipment/gel_wand.tres",
	EquipmentLoadout.EquipSlot.AMULET: "res://data/equipment/core_amulet.tres",
	EquipmentLoadout.EquipSlot.HEAD: "res://data/equipment/wanderer_hood.tres",
	EquipmentLoadout.EquipSlot.GLOVES: "res://data/equipment/smith_gloves.tres",
	EquipmentLoadout.EquipSlot.ARMOR: "res://data/equipment/bone_armor.tres",
	EquipmentLoadout.EquipSlot.PANTS: "res://data/equipment/leather_pants.tres",
	EquipmentLoadout.EquipSlot.BOOTS: "res://data/equipment/slime_boots.tres",
	EquipmentLoadout.EquipSlot.RING_1: "res://data/equipment/gel_ring.tres",
	EquipmentLoadout.EquipSlot.RING_2: "res://data/equipment/gel_ring.tres",
}
const ABILITIES: Array[String] = [
	"res://data/abilities/wandering_lightning.tres",
	"res://data/abilities/arcane_ring.tres",
	"res://data/abilities/arcane_barrier.tres",
]

var _saved_locale: String
var _saved_sort: StashSort.Mode
var _saved_filter: String


func before_test() -> void:
	_saved_locale = TranslationServer.get_locale()
	_saved_sort = LoadoutPanel.sort_mode
	_saved_filter = LoadoutPanel.filter_key


func after_test() -> void:
	TranslationServer.set_locale(_saved_locale)
	LoadoutPanel.sort_mode = _saved_sort
	LoadoutPanel.filter_key = _saved_filter


func _panel() -> LoadoutPanel:
	var panel: LoadoutPanel = auto_free(load("res://scenes/hub/LoadoutPanel/LoadoutPanel.tscn").instantiate())
	add_child(panel)
	return panel


## Refresh + un paio di frame: le label con autowrap si rimisurano sulla larghezza reale solo dopo il layout.
func _size_after_refresh(panel: LoadoutPanel, loadout: EquipmentLoadout) -> Vector2:
	panel.refresh(loadout)
	await get_tree().process_frame
	await get_tree().process_frame
	return panel.get_combined_minimum_size()


## Un pezzo per ogni slot del manichino (due anelli), tutti nel baule; tier alto + abilita' opzionale.
func _full_set(loadout: EquipmentLoadout, tier: int, with_abilities: bool) -> Dictionary[int, ItemInstance]:
	var items: Dictionary[int, ItemInstance] = {}
	var i := 0
	for slot: int in SLOT_BASES:
		var item := ItemInstance.new(load(SLOT_BASES[slot]), tier)
		if with_abilities:
			item.ability = load(ABILITIES[i % ABILITIES.size()])
		items[slot] = loadout.add(item)
		i += 1
	return items


func test_every_slot_equipped_alone_keeps_the_same_size() -> void:
	for locale in LOCALES:
		TranslationServer.set_locale(locale)
		var loadout := EquipmentLoadout.new()
		var items := _full_set(loadout, 3, true)
		var panel := _panel()
		var baseline: Vector2 = await _size_after_refresh(panel, loadout)
		for slot: int in items:
			loadout.equip(items[slot].uid)
			assert_vector(await _size_after_refresh(panel, loadout)).override_failure_message("%s: equip slot %d" % [locale, slot]).is_equal(baseline)
			for equipped_slot: int in SLOT_BASES:
				loadout.unequip(equipped_slot)
			assert_vector(await _size_after_refresh(panel, loadout)).override_failure_message("%s: unequip slot %d" % [locale, slot]).is_equal(baseline)


## Il caso segnalato: bacchetta, poi anello, poi il secondo anello, poi tutto il resto uno alla volta.
func test_equipping_one_piece_after_another_keeps_the_same_size() -> void:
	for locale in LOCALES:
		TranslationServer.set_locale(locale)
		var loadout := EquipmentLoadout.new()
		var items := _full_set(loadout, 4, true)
		var panel := _panel()
		var baseline: Vector2 = await _size_after_refresh(panel, loadout)
		for slot: int in items:
			loadout.equip(items[slot].uid)
			assert_vector(await _size_after_refresh(panel, loadout)).override_failure_message("%s: +slot %d" % [locale, slot]).is_equal(baseline)
		# Tutto indossato = baule vuoto (compare l'avviso) e abilita' al massimo accumulabile.
		assert_bool(loadout.stash_items().is_empty()).is_true()
		for slot: int in items:
			loadout.unequip(slot)
			assert_vector(await _size_after_refresh(panel, loadout)).override_failure_message("%s: -slot %d" % [locale, slot]).is_equal(baseline)


## Testo delle abilita' piu' lungo possibile (tre abilita' su tutti i 9 slot, rarita' massima): altezza uguale,
## testo intero nel tooltip.
func test_longest_ability_row_does_not_grow_the_panel() -> void:
	for locale in LOCALES:
		TranslationServer.set_locale(locale)
		var loadout := EquipmentLoadout.new()
		var panel := _panel()
		var baseline: Vector2 = await _size_after_refresh(panel, loadout)
		for copy in 4:
			var items := _full_set(loadout, ItemText.RARITIES.tiers.size() - 1, true)
			for slot: int in items:
				loadout.equip(items[slot].uid)
		assert_vector(await _size_after_refresh(panel, loadout)).override_failure_message(locale).is_equal(baseline)
		var ability_label: Label = panel.get_node("%AbilityLevels")
		assert_str(ability_label.tooltip_text).is_equal(ability_label.text)


func test_any_stash_count_keeps_the_same_size() -> void:
	var loadout := EquipmentLoadout.new()
	var panel := _panel()
	var baseline: Vector2 = await _size_after_refresh(panel, loadout)
	var total := 0
	for count in [1, 4, 5, 6, 11, 40]:
		while total < count:
			loadout.add(ItemInstance.new(load("res://data/equipment/gel_ring.tres"), total % 5))
			total += 1
		assert_vector(await _size_after_refresh(panel, loadout)).override_failure_message("stash %d" % count).is_equal(baseline)


func test_every_filter_and_sort_keeps_the_same_size() -> void:
	var loadout := EquipmentLoadout.new()
	_full_set(loadout, 2, false)
	var panel := _panel()
	var baseline: Vector2 = await _size_after_refresh(panel, loadout)
	var filter: OptionButton = panel.get_node("%Filter")
	for mode: StashSort.Mode in [StashSort.Mode.ARRIVAL, StashSort.Mode.RARITY, StashSort.Mode.CATEGORY]:
		LoadoutPanel.sort_mode = mode
		for index in filter.item_count:
			panel._on_filter_selected(index)
			assert_vector(await _size_after_refresh(panel, loadout)).override_failure_message("sort %d filter %d" % [mode, index]).is_equal(baseline)
