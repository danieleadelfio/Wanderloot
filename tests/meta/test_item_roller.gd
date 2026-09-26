extends GdUnitTestSuite


func test_no_item_repeats_a_stat() -> void:
	var catalog: EquipmentCatalog = load("res://data/equipment/equipment_catalog.tres")
	var rarities: RarityTable = load("res://data/equipment/rarity_table.tres")
	var affixes: AffixTable = load("res://data/equipment/affix_table.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for base in catalog.items:
		for i in 40:
			var item := ItemRoller.roll(base, rarities.highest(), rarities, affixes, null, rng)
			var seen: Array[int] = []
			for modifier in item.modifiers():
				assert_bool(seen.has(int(modifier.stat))).override_failure_message("%s ripete %d" % [base.id, modifier.stat]).is_false()
				seen.append(int(modifier.stat))
## Rarita' e bonus (M11): numero di bonus per rarita', valori negli intervalli, abilita' da Super raro.

var _rarities: RarityTable = load("res://data/equipment/rarity_table.tres")
var _affixes: AffixTable = load("res://data/equipment/affix_table.tres")
var _abilities: AbilityCatalog = load("res://data/abilities/ability_catalog.tres")


func test_six_rarities_with_growing_quality() -> void:
	assert_int(_rarities.tiers.size()).is_equal(6)
	for i in range(1, 6):
		assert_float(_rarities.tier(i).roll_max).is_greater_equal(_rarities.tier(i - 1).roll_max)
	assert_float(_rarities.tier(5).drop_weight).is_equal(0.0)


func test_affix_count_and_ability_by_rarity() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var base: EquipmentData = load("res://data/equipment/gel_wand.tres")
	for tier in 6:
		var item := ItemRoller.roll(base, tier, _rarities, _affixes, _abilities, rng)
		assert_int(item.rarity).is_equal(tier)
		assert_int(item.affixes.size()).is_equal(_rarities.tier(tier).affix_count)
		assert_bool(item.ability != null).is_equal(_rarities.tier(tier).ability_count > 0)


func test_values_stay_inside_ranges_and_differ_between_rolls() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var base: EquipmentData = load("res://data/equipment/smith_gloves.tres")
	var seen := {}
	for i in 40:
		var item := ItemRoller.roll(base, 2, _rarities, _affixes, _abilities, rng)
		var stats := {}
		for affix in item.affixes:
			assert_bool(stats.has(affix.stat)).override_failure_message("bonus ripetuto").is_false()
			stats[affix.stat] = true
			var source: AffixRoll = _affixes.rolls.filter(func(r: AffixRoll) -> bool: return r.stat == affix.stat and r.allows(base.slot))[0]
			assert_float(affix.amount).is_between(minf(source.min_value, 1.0), source.max_value + 0.001)
			seen[snappedf(affix.amount, 0.001)] = true
	assert_int(seen.size()).is_greater(5)


func test_affixes_respect_item_type() -> void:
	var rng := RandomNumberGenerator.new()
	var ring: EquipmentData = load("res://data/equipment/gel_ring.tres")
	for i in 30:
		for affix in ItemRoller.roll(ring, 4, _rarities, _affixes, _abilities, rng).affixes:
			assert_int(affix.stat).is_not_equal(UpgradeData.Stat.PIERCE)


## Danno e HP massimi degli oggetti base e dei bonus tirati non devono piu' essere flat (M12, #86):
## +1/+2 fisso era sproporzionato rispetto alla base (troppo su un'arma debole, trascurabile su una
## forte) e cambiava peso a ogni rescale della base. Sempre percentuale, come Cadenza di fuoco.
func test_gel_wand_and_bone_wand_damage_bonus_is_percentage() -> void:
	var gel_wand: EquipmentData = load("res://data/equipment/gel_wand.tres")
	var bone_wand: EquipmentData = load("res://data/equipment/bone_wand.tres")
	for wand in [gel_wand, bone_wand]:
		var damage_mod: StatModifier = wand.modifiers.filter(func(m: StatModifier) -> bool: return m.stat == UpgradeData.Stat.DAMAGE)[0]
		assert_bool(damage_mod.is_multiplier).is_true()


func test_max_hp_equip_bonus_is_percentage() -> void:
	for path in ["res://data/equipment/core_amulet.tres", "res://data/equipment/bone_armor.tres", "res://data/equipment/leather_pants.tres"]:
		var base: EquipmentData = load(path)
		var hp_mod: StatModifier = base.modifiers.filter(func(m: StatModifier) -> bool: return m.stat == UpgradeData.Stat.MAX_HP)[0]
		assert_bool(hp_mod.is_multiplier).is_true()


func test_damage_and_max_hp_affix_rolls_are_percentage() -> void:
	var damage_affix: AffixRoll = _affixes.rolls.filter(func(r: AffixRoll) -> bool: return r.stat == UpgradeData.Stat.DAMAGE)[0]
	var max_hp_affix: AffixRoll = _affixes.rolls.filter(func(r: AffixRoll) -> bool: return r.stat == UpgradeData.Stat.MAX_HP)[0]
	assert_bool(damage_affix.is_multiplier).is_true()
	assert_bool(max_hp_affix.is_multiplier).is_true()
