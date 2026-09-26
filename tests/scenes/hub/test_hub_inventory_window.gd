extends GdUnitTestSuite
## Finestra Inventario dell'hub (M13, #86): stessa dimensione e stessa scala qualunque cosa si equipaggi
## o disequipaggi a finestra aperta (bug: bacchetta e poi anello la facevano cambiare a ogni passo), e
## sempre dentro lo schermo. Percorso reale: MetaProgression.equip/unequip -> changed -> Hub._refresh.
## Stato di MetaProgression solo in memoria (new_game), mai scritto su disco.

const LOCALES: Array[String] = ["it", "en", "fr", "es"]
const SLOT_BASES: Array[String] = [
	"res://data/equipment/gel_wand.tres",
	"res://data/equipment/gel_ring.tres",
	"res://data/equipment/gel_ring.tres",
	"res://data/equipment/core_amulet.tres",
	"res://data/equipment/wanderer_hood.tres",
	"res://data/equipment/smith_gloves.tres",
	"res://data/equipment/bone_armor.tres",
	"res://data/equipment/leather_pants.tres",
	"res://data/equipment/slime_boots.tres",
]
const ABILITIES: Array[String] = [
	"res://data/abilities/wandering_lightning.tres",
	"res://data/abilities/arcane_ring.tres",
	"res://data/abilities/arcane_barrier.tres",
]

var _saved_locale: String


func before_test() -> void:
	_saved_locale = TranslationServer.get_locale()
	MetaProgression.new_game()
	MetaProgression.mark_tutorial_seen(&"hub_intro")


func after_test() -> void:
	# Aprire una finestra mette in pausa l'albero: se restasse cosi' il runner dei test si fermerebbe.
	get_tree().paused = false
	TranslationServer.set_locale(_saved_locale)
	MetaProgression.new_game()


## Bacchetta per prima e anello subito dopo (l'ordine del bug), poi il resto; tier con abilita'.
func _add_full_set() -> Array[ItemInstance]:
	var items: Array[ItemInstance] = []
	for i in SLOT_BASES.size():
		var item := ItemInstance.new(load(SLOT_BASES[i]), 4)
		item.ability = load(ABILITIES[i % ABILITIES.size()])
		items.append(MetaProgression.loadout.add(item))
	return items


func _open_hub() -> Node2D:
	var hub: Node2D = auto_free(load("res://scenes/hub/Hub/Hub.tscn").instantiate())
	add_child(hub)
	await get_tree().process_frame
	hub._toggle_inventory(0)
	await _settle()
	return hub


func _settle() -> void:
	for i in 3:
		await get_tree().process_frame


func _assert_window_unchanged(hub: Node2D, size: Vector2, scale: Vector2, step: String) -> void:
	var panel: Control = hub.get_node("%Panel")
	var window: Control = hub.get_node("%InventoryWindow")
	assert_vector(panel.size).override_failure_message("size dopo: " + step).is_equal(size)
	assert_vector(panel.size).override_failure_message("size != minima dopo: " + step).is_equal(panel.get_combined_minimum_size())
	assert_vector(window.scale).override_failure_message("scala dopo: " + step).is_equal(scale)
	assert_vector(panel.scale).override_failure_message("scala pannello dopo: " + step).is_equal(Vector2.ONE)
	var visible_size := panel.size * window.scale
	var screen: Vector2 = hub.get_viewport().get_visible_rect().size * hub.max_inventory_viewport_fraction
	assert_bool(visible_size.x <= screen.x + 0.5 and visible_size.y <= screen.y + 0.5).override_failure_message("fuori schermo dopo: " + step).is_true()


func test_window_keeps_size_and_scale_through_every_equip_and_unequip() -> void:
	var items := _add_full_set()
	var hub: Node2D = await _open_hub()
	var panel: Control = hub.get_node("%Panel")
	var size := panel.size
	var scale: Vector2 = hub.get_node("%InventoryWindow").scale
	_assert_window_unchanged(hub, size, scale, "apertura")
	for item in items:
		MetaProgression.equip(item.uid)
		await _settle()
		_assert_window_unchanged(hub, size, scale, "equip %s" % item.base.id)
	for slot: int in EquipmentLoadout.EquipSlot.values():
		MetaProgression.unequip(slot)
		await _settle()
		_assert_window_unchanged(hub, size, scale, "unequip slot %d" % slot)
	# Cambio scheda e riapertura: stessa finestra.
	hub._toggle_inventory(1)
	await _settle()
	_assert_window_unchanged(hub, size, scale, "scheda Statistiche")
	hub._toggle_inventory(1)
	hub._toggle_inventory(0)
	await _settle()
	_assert_window_unchanged(hub, size, scale, "riapertura")


func test_window_size_does_not_depend_on_gear_in_any_language() -> void:
	for locale in LOCALES:
		TranslationServer.set_locale(locale)
		MetaProgression.new_game()
		MetaProgression.mark_tutorial_seen(&"hub_intro")
		var items := _add_full_set()
		var hub: Node2D = await _open_hub()
		var panel: Control = hub.get_node("%Panel")
		var size := panel.size
		var scale: Vector2 = hub.get_node("%InventoryWindow").scale
		for item in items:
			MetaProgression.equip(item.uid)
		await _settle()
		_assert_window_unchanged(hub, size, scale, "%s: tutto equipaggiato" % locale)
		hub._toggle_inventory(0)
		get_tree().paused = false
		remove_child(hub)
		await get_tree().process_frame
