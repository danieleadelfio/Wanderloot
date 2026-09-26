extends GdUnitTestSuite
## Verifica che i tiri di ItemRoller siano davvero casuali e non sempre la stessa statistica (dubbio
## segnalato per i Guanti del fabbro, M13, #86): su molti tiri alla stessa rarita' devono comparire
## affissi diversi, non sempre lo stesso.

const RARITIES: RarityTable = preload("res://data/equipment/rarity_table.tres")
const AFFIXES: AffixTable = preload("res://data/equipment/affix_table.tres")
const ABILITIES: AbilityCatalog = preload("res://data/abilities/ability_catalog.tres")


func test_smith_gloves_rolls_vary_across_many_pulls() -> void:
	var gloves: EquipmentData = load("res://data/equipment/smith_gloves.tres")
	var seen: Dictionary = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for i in 60:
		var item := ItemRoller.roll(gloves, 0, RARITIES, AFFIXES, ABILITIES, rng)
		assert_int(item.affixes.size()).is_equal(1)
		seen[item.affixes[0].stat] = true
	# Con 4 affissi ammessi per i Guanti (Danno, Magnete, Bonus exp, Bonus drop) su 60 tiri, vederne
	# sempre e solo uno significherebbe un bug nella scelta pesata, non solo sfortuna statistica.
	assert_int(seen.size()).is_greater(1)


func test_any_equipment_slot_rolls_vary_across_many_pulls() -> void:
	var wand: EquipmentData = load("res://data/equipment/gel_wand.tres")
	var seen: Dictionary = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	for i in 60:
		var item := ItemRoller.roll(wand, 1, RARITIES, AFFIXES, ABILITIES, rng)
		for affix in item.affixes:
			seen[affix.stat] = true
	assert_int(seen.size()).is_greater(1)
