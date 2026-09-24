extends GdUnitTestSuite
## Traduzioni (M9): ogni chiave ha le 4 lingue e ogni chiave usata da scene, dati e codice esiste.

const CSV_PATH: String = "res://data/i18n/strings.csv"
const TEST_SETTINGS: String = "user://test_locale_settings.cfg"


func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))


func _rows() -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() > 1:
			result.append(row)
	return result


func _keys() -> Dictionary:
	var keys := {}
	for row in _rows().slice(1):
		keys[row[0]] = true
	return keys


func test_every_key_has_all_languages() -> void:
	var rows := _rows()
	assert_array(Array(rows[0])).is_equal(["keys", "it", "en", "fr", "es"])
	var seen := {}
	for row in rows.slice(1):
		assert_int(row.size()).override_failure_message("riga %s" % row[0]).is_equal(5)
		for i in range(1, 5):
			assert_str(row[i].strip_edges()).override_failure_message("%s senza %s" % [row[0], rows[0][i]]).is_not_empty()
		assert_bool(seen.has(row[0])).override_failure_message("chiave duplicata %s" % row[0]).is_false()
		seen[row[0]] = true


func test_keys_used_in_scenes_data_and_code_exist() -> void:
	var keys := _keys()
	var field := RegEx.create_from_string('(?m)^(?:text|tooltip_text|prompt|display_name|description) = "([A-Z][A-Z0-9]*_[A-Z0-9_]+)"$')
	var code := RegEx.create_from_string('(?:tr|translate)\\("([A-Z][A-Z0-9]*_[A-Z0-9_]+)"\\)|"((?:STAT|SLOT)_[A-Z_]+)"')
	var missing: Array[String] = []
	for path in _files("res://scenes", [".tscn"]) + _files("res://data", [".tres"]):
		for m in field.search_all(FileAccess.get_file_as_string(path)):
			if not keys.has(m.get_string(1)):
				missing.append("%s: %s" % [path, m.get_string(1)])
	for path in _files("res://scenes", [".gd"]) + _files("res://scripts", [".gd"]):
		for m in code.search_all(FileAccess.get_file_as_string(path)):
			var key := m.get_string(1) if m.get_string(1) != "" else m.get_string(2)
			if not keys.has(key):
				missing.append("%s: %s" % [path, key])
	assert_array(missing).is_empty()


func test_translations_are_loaded() -> void:
	var before := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	assert_str(TranslationServer.translate("MENU_CONTINUE")).is_equal("Continue")
	TranslationServer.set_locale("fr")
	assert_str(TranslationServer.translate("MENU_CONTINUE")).is_equal("Continuer")
	TranslationServer.set_locale(before)


func test_locale_is_saved_without_losing_audio() -> void:
	var audio := AudioSettings.new()
	audio.path = TEST_SETTINGS
	audio.set_volume(&"Music", 0.3)
	audio.save_file()
	assert_int(LocaleSettings.save_locale("es", TEST_SETTINGS)).is_equal(OK)
	audio.set_volume(&"SFX", 0.6)
	audio.save_file()
	assert_str(LocaleSettings.load_saved(TEST_SETTINGS)).is_equal("es")
	var loaded := AudioSettings.new()
	loaded.path = TEST_SETTINGS
	loaded.load_file()
	assert_float(loaded.volume(&"Music")).is_equal_approx(0.3, 0.001)


func test_unsupported_locale_falls_back_to_english() -> void:
	assert_str(LocaleSettings.normalize("de_DE")).is_equal("en")
	assert_str(LocaleSettings.normalize("it_IT")).is_equal("it")


func _files(root: String, extensions: Array) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(root)
	if dir == null:
		return result
	for sub in dir.get_directories():
		result.append_array(_files(root.path_join(sub), extensions))
	for file in dir.get_files():
		for ext in extensions:
			if file.ends_with(ext):
				result.append(root.path_join(file))
	return result
