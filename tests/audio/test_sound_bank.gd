extends GdUnitTestSuite
## Ogni suono usato dal codice esiste nel banco con uno stream; id sconosciuti non rompono SfxPlayer.

const USED_IDS: Array[StringName] = [
	&"shoot", &"enemy_hit", &"enemy_die", &"player_hurt", &"level_up",
	&"extract", &"player_death", &"craft", &"ui_select", &"pickup_exp", &"pickup_item",
]


func test_all_used_sounds_exist_with_stream() -> void:
	var bank: SoundBank = load("res://data/audio/sound_bank.tres")
	for id in USED_IDS:
		var entry := bank.find(id)
		assert_object(entry).override_failure_message("manca il suono %s" % id).is_not_null()
		assert_object(entry.stream).is_not_null()


func test_unknown_id_is_ignored() -> void:
	var sfx: SfxPlayer = auto_free(SfxPlayer.new())
	sfx.bank = load("res://data/audio/sound_bank.tres")
	add_child(sfx)
	sfx.play(&"does_not_exist")
	sfx.bank = null
	sfx.play(&"shoot")
	assert_bool(true).is_true()
