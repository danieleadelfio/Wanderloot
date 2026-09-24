extends GdUnitTestSuite
## Oggetti trovati in run: probabilita', rarita' entro i limiti, boss con rarita' minima.

const RARITIES: RarityTable = preload("res://data/equipment/rarity_table.tres")

var _rng := RandomNumberGenerator.new()


func before_test() -> void:
	_rng.seed = 7


func test_arenas_have_item_drops() -> void:
	for path in ["res://data/arenas/crypt.tres", "res://data/arenas/ossuary.tres"]:
		var arena: ArenaData = load(path)
		assert_object(arena.item_drops).is_not_null()
		assert_bool(arena.item_drops.items.is_empty()).is_false()
		assert_int(arena.item_drops.max_tier).is_less(RARITIES.highest())


func test_chance_zero_and_one() -> void:
	var table := _table()
	table.drop_chance = 0.0
	assert_object(table.roll(_rng)).is_null()
	table.drop_chance = 1.0
	assert_object(table.roll(_rng)).is_not_null()


func test_tiers_stay_within_limits() -> void:
	var table := _table()
	for i in 300:
		var tier := table.roll_tier(RARITIES, _rng)
		assert_int(tier).is_between(0, table.max_tier)
		var boss_tier := table.roll_tier(RARITIES, _rng, true)
		assert_int(boss_tier).is_between(table.boss_min_tier, table.max_tier)


func _table() -> ItemDropTable:
	var table := ItemDropTable.new()
	table.items = [load("res://data/equipment/gel_wand.tres") as EquipmentData]
	return table
