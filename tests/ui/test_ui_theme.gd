extends GdUnitTestSuite
## Tema di progetto (M13, #86): unico posto degli stili della UI, in vista del reskin (docs/UI_ASSETS.md).
## Guardie: nessuno stile scritto a mano in scene/script, ogni tipo usato esiste nel tema, i ruoli
## principali mantengono l'aspetto attuale finche' non arrivano le nuove cornici.

const THEME_PATH := "res://data/ui/wanderloot_theme.tres"
## Unico script autorizzato a toccare StyleBox (copie tinte degli stili del tema).
const ALLOWED := ["res://scripts/ui/ui_theme.gd"]
const FORBIDDEN := ["StyleBoxFlat", "StyleBoxTexture", "theme_override_styles"]


func _files(dir: String, extensions: Array[String]) -> Array[String]:
	var result: Array[String] = []
	var access := DirAccess.open(dir)
	if access == null:
		return result
	for sub in access.get_directories():
		result.append_array(_files(dir.path_join(sub), extensions))
	for file in access.get_files():
		if file.get_extension() in extensions:
			result.append(dir.path_join(file))
	return result


func _ui_files() -> Array[String]:
	var files := _files("res://scenes", ["tscn", "gd"] as Array[String])
	files.append_array(_files("res://scripts", ["gd"] as Array[String]))
	return files


func test_project_theme_is_the_wanderloot_theme() -> void:
	assert_str(ProjectSettings.get_setting("gui/theme/custom")).is_equal(THEME_PATH)
	assert_object(UiTheme.project_theme()).is_not_null()
	assert_str(UiTheme.project_theme().resource_path).is_equal(THEME_PATH)


func test_no_hand_written_styles_in_scenes_or_scripts() -> void:
	for path in _ui_files():
		if path in ALLOWED:
			continue
		var text := FileAccess.get_file_as_string(path)
		for word in FORBIDDEN:
			assert_bool(text.contains(word)).override_failure_message("%s contiene %s: usa un tipo del tema" % [path, word]).is_false()


func test_every_theme_type_used_exists_in_the_theme() -> void:
	var theme := UiTheme.project_theme()
	var regex := RegEx.create_from_string("theme_type_variation = &\"(\\w+)\"")
	var used := 0
	for path in _ui_files():
		for found in regex.search_all(FileAccess.get_file_as_string(path)):
			used += 1
			var type := found.get_string(1)
			assert_str(String(theme.get_type_variation_base(type))).override_failure_message("%s usa il tipo sconosciuto %s" % [path, type]).is_not_empty()
	assert_int(used).is_greater(10)


func test_roles_keep_the_current_look() -> void:
	var theme := UiTheme.project_theme()
	var window := theme.get_stylebox(&"panel", &"WindowPanel") as StyleBoxFlat
	assert_object(window.border_color).is_equal(Color(0.78, 0.62, 0.36, 1))
	assert_float(window.content_margin_left).is_equal(20.0)
	assert_object((theme.get_stylebox(&"fill", &"HpBar") as StyleBoxFlat).bg_color).is_equal(Color(0.86, 0.2, 0.25, 1))
	assert_object((theme.get_stylebox(&"fill", &"ManaBar") as StyleBoxFlat).bg_color).is_equal(Color(0.25, 0.75, 0.95, 1))
	assert_object((theme.get_stylebox(&"fill", &"ExpBar") as StyleBoxFlat).bg_color).is_equal(Color(0.25, 0.55, 1, 1))
	assert_object((theme.get_stylebox(&"fill", &"BossBar") as StyleBoxFlat).bg_color).is_equal(Color(0.62, 0.2, 0.85, 1))
	for bar: StringName in [&"HpBar", &"ManaBar", &"ExpBar", &"EventBar", &"BossBar"]:
		assert_str(String(theme.get_type_variation_base(bar))).is_equal("ProgressBar")
		assert_bool(theme.has_stylebox(&"background", bar)).is_true()


## Rarita': copia tinta, lo stile del tema resta intatto (bianco) per tutti gli altri oggetti.
func test_item_tile_border_follows_rarity_without_touching_the_theme() -> void:
	var item := ItemInstance.new(load("res://data/equipment/gel_ring.tres"), 4)
	var tile: ItemTile = auto_free(ItemTile.for_item(item))
	add_child(tile)
	assert_str(String(tile.theme_type_variation)).is_equal("ItemSlot")
	for state: StringName in [&"normal", &"hover", &"pressed"]:
		assert_object((tile.get_theme_stylebox(state) as StyleBoxFlat).border_color).is_equal(ItemText.color(item))
	assert_object((UiTheme.project_theme().get_stylebox(&"normal", &"ItemSlot") as StyleBoxFlat).border_color).is_equal(Color.WHITE)


func test_tint_colors_flat_borders_and_texture_frames_on_a_copy() -> void:
	var flat := StyleBoxFlat.new()
	flat.border_color = Color.WHITE
	var tinted_flat := UiTheme.tint(flat, Color.RED) as StyleBoxFlat
	assert_object(tinted_flat.border_color).is_equal(Color.RED)
	assert_object(flat.border_color).is_equal(Color.WHITE)
	# Percorso del reskin: cornice a texture chiara, colore della rarita' da modulate_color.
	var frame := StyleBoxTexture.new()
	var tinted_frame := UiTheme.tint(frame, Color.GREEN) as StyleBoxTexture
	assert_object(tinted_frame.modulate_color).is_equal(Color.GREEN)
	assert_object(frame.modulate_color).is_equal(Color.WHITE)
