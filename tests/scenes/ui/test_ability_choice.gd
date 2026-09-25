extends GdUnitTestSuite
## Scelta abilita' della bacchetta (M10, M12 #86/#20): se gia' posseduta e al cap sbloccato, la carta
## mostra Bag of Resources invece della carta normale, cosi' si vede subito che il livello e' inutile
## (prima si vedeva solo a run finita, dai materiali ottenuti senza capire da dove venissero).

var _choice: AbilityChoice


func before_test() -> void:
	_choice = auto_free((load("res://scenes/ui/AbilityChoice/AbilityChoice.tscn") as PackedScene).instantiate())
	add_child(_choice)


func _ability(id: StringName) -> WandAbility:
	var ability := WandAbility.new()
	ability.id = id
	ability.display_name = "ABILITY_ARCANE_RING"
	ability.description = "ABILITY_ARCANE_RING_DESC"
	return ability


func test_capped_ability_shows_bag_of_resources() -> void:
	var ability := _ability(&"arcane_ring")
	_choice.present([ability], [] as Array[WandAbility], false, {&"arcane_ring": 1}, {&"arcane_ring": 1})
	var button := _choice.get_node("%Choices").get_child(0) as Button
	assert_str(button.text).contains(tr("ABILITY_CHOICE_BAG_DESC"))
	assert_object(button.icon).is_equal(load("res://assets/sprites/icon_bag.png"))


func test_below_cap_ability_shows_normal_card() -> void:
	var ability := _ability(&"arcane_ring")
	_choice.present([ability], [] as Array[WandAbility], false, {&"arcane_ring": 1}, {&"arcane_ring": 2})
	var button := _choice.get_node("%Choices").get_child(0) as Button
	assert_str(button.text).contains(tr("ABILITY_ARCANE_RING_DESC"))
	assert_str(button.text).not_contains(tr("ABILITY_CHOICE_BAG_DESC"))


func test_new_ability_never_owned_shows_normal_card() -> void:
	var ability := _ability(&"arcane_ring")
	_choice.present([ability], [] as Array[WandAbility], false, {} as Dictionary, {&"arcane_ring": 1})
	var button := _choice.get_node("%Choices").get_child(0) as Button
	assert_str(button.text).contains(tr("ABILITY_ARCANE_RING_DESC"))
