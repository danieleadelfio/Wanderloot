extends GdUnitTestSuite
## Pannello Portale dell'hub (M13, #86): cambiando arena il livello arena mostrato resta quello
## dell'equip indossato (bug: tornava a "Livello 1" finche' non si riapriva il pannello).
## Stato di MetaProgression solo in memoria (new_game), mai scritto su disco.


func before_test() -> void:
	MetaProgression.new_game()
	MetaProgression.mark_tutorial_seen(&"hub_intro")
	for arena in MetaProgression.arena_catalog.arenas:
		MetaProgression.extractions[arena.unlock_arena] = 99
	for path in ["res://data/equipment/gel_wand.tres", "res://data/equipment/gel_ring.tres", "res://data/equipment/gel_ring.tres",
			"res://data/equipment/core_amulet.tres", "res://data/equipment/slime_boots.tres"]:
		var item := MetaProgression.loadout.add(ItemInstance.new(load(path), 3))
		MetaProgression.loadout.equip(item.uid)


func after_test() -> void:
	get_tree().paused = false
	MetaProgression.new_game()


func test_arena_level_survives_switching_arena_both_ways() -> void:
	var expected := ArenaLevel.level_for(MetaProgression.loadout.equipped_items())
	assert_int(expected).is_greater(1)
	var hub: Node2D = auto_free(load("res://scenes/hub/Hub/Hub.tscn").instantiate())
	add_child(hub)
	await get_tree().process_frame
	var label: Label = hub.get_node("%ArenaSelect")._level_label
	for arena_id: StringName in [&"ossuary", &"crypt", &"ossuary"]:
		hub._on_arena_selected(arena_id)
		assert_str(label.text).override_failure_message(String(arena_id)).is_equal(tr("ARENA_LEVEL_CURRENT") % expected)


## Tour della piazza (M13, #86): subito dopo il fabbro c'e' il passo che spiega a cosa serve l'Ascensione.
func test_hub_tour_explains_ascension_right_after_the_blacksmith() -> void:
	MetaProgression.new_game()
	var hub: Node2D = auto_free(load("res://scenes/hub/Hub/Hub.tscn").instantiate())
	add_child(hub)
	await get_tree().process_frame
	var steps: Array[Dictionary] = hub.get_node("%HubTutorial")._steps
	var titles: Array[String] = []
	for step in steps:
		titles.append(step["title"])
	var at := titles.find(tr("TUTORIAL_HUB_ASCENSION_TITLE"))
	assert_int(at).is_greater(0)
	assert_str(titles[at - 1]).is_equal(tr("TUTORIAL_FORGE_TITLE"))
	assert_str(steps[at]["body"]).is_equal(tr("TUTORIAL_HUB_ASCENSION_BODY"))
