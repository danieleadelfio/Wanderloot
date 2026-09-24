extends GdUnitTestSuite
## Impostazioni audio (M8): valori limitati a 0..1 e salvati su file dedicato.

const TEST_PATH: String = "user://test_settings.cfg"


func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_volume_is_clamped() -> void:
	var settings := AudioSettings.new()
	settings.set_volume(&"Music", 1.7)
	settings.set_volume(&"SFX", -0.2)
	assert_float(settings.volume(&"Music")).is_equal(1.0)
	assert_float(settings.volume(&"SFX")).is_equal(0.0)


func test_save_and_load_roundtrip() -> void:
	var settings := AudioSettings.new()
	settings.path = TEST_PATH
	settings.set_volume(&"Music", 0.25)
	settings.set_volume(&"SFX", 0.8)
	assert_int(settings.save_file()).is_equal(OK)
	var loaded := AudioSettings.new()
	loaded.path = TEST_PATH
	assert_int(loaded.load_file()).is_equal(OK)
	assert_float(loaded.volume(&"Music")).is_equal_approx(0.25, 0.001)
	assert_float(loaded.volume(&"SFX")).is_equal_approx(0.8, 0.001)


func test_missing_file_keeps_full_volume() -> void:
	var settings := AudioSettings.new()
	settings.path = TEST_PATH
	assert_int(settings.load_file()).is_equal(ERR_FILE_NOT_FOUND)
	assert_float(settings.volume(&"Music")).is_equal(1.0)


func test_half_volume_is_about_minus_six_db() -> void:
	assert_float(AudioSettings.to_db(0.5)).is_equal_approx(-6.02, 0.05)
