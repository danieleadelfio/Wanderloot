extends GdUnitTestSuite
## Ogni suono usato dal codice esiste nel banco con uno stream; id sconosciuti non rompono SfxPlayer.

const USED_IDS: Array[StringName] = [
	&"shoot", &"enemy_hit", &"enemy_die", &"player_hurt", &"level_up",
	&"extract", &"player_death", &"craft", &"ui_select", &"pickup_exp", &"pickup_item",
	&"enemy_shoot", &"boss_appear", &"boss_warn", &"boss_slam", &"event_start", &"lightning", &"power_up", &"candle_out",
	&"drop_common", &"drop_uncommon", &"drop_rare", &"drop_super_rare", &"drop_legendary", &"drop_mythic",
	&"overtime_warn", &"overtime_start", &"dash",
]


func test_all_used_sounds_exist_with_stream() -> void:
	var bank: SoundBank = load("res://data/audio/sound_bank.tres")
	for id in USED_IDS:
		var entry := bank.find(id)
		assert_object(entry).override_failure_message("manca il suono %s" % id).is_not_null()
		assert_object(entry.stream).is_not_null()


func test_every_rarity_has_a_drop_sound() -> void:
	var bank: SoundBank = load("res://data/audio/sound_bank.tres")
	var rarities: RarityTable = load("res://data/equipment/rarity_table.tres")
	var last_glow := 0.0
	for tier in rarities.tiers:
		assert_object(bank.find(tier.drop_sound)).override_failure_message("manca %s" % tier.drop_sound).is_not_null()
		assert_float(tier.glow_scale).is_greater(last_glow)
		last_glow = tier.glow_scale


func test_unknown_id_is_ignored() -> void:
	var sfx: SfxPlayer = auto_free(SfxPlayer.new())
	sfx.bank = load("res://data/audio/sound_bank.tres")
	add_child(sfx)
	sfx.play(&"does_not_exist")
	sfx.bank = null
	sfx.play(&"shoot")
	assert_bool(true).is_true()
