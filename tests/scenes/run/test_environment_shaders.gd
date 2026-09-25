extends GdUnitTestSuite
## Shader di movimento ambientale (M12, #86): niente da nessuna parte verifica queste scene a runtime
## (rendering/asset, fuori dalla regola generale di test) - qui solo un controllo di caricamento e
## instanziazione, per intercettare risorse .tscn/shader malformate che altrimenti passerebbero
## inosservate finche' qualcuno non gioca la scena giusta.

func test_torch_and_candle_load_with_flame_shader() -> void:
	for path in ["res://scenes/run/Torch/Torch.tscn", "res://scenes/run/Candle/Candle.tscn"]:
		var scene: PackedScene = load(path)
		assert_object(scene).is_not_null()
		var instance: Node2D = auto_free(scene.instantiate())
		var sprite := instance.get_node("Sprite") as Sprite2D
		assert_object(sprite.material).is_not_null()
		assert_object((sprite.material as ShaderMaterial).shader).is_not_null()


func test_environment_drip_loads_and_exposes_growing_stain() -> void:
	var scene: PackedScene = load("res://scenes/run/EnvironmentDrip/EnvironmentDrip.tscn")
	var instance: Node2D = auto_free(scene.instantiate())
	var stain := instance.get_node("Stain") as GrowingStain
	assert_object(stain).is_not_null()
	assert_object(stain.material).is_not_null()
	stain.set_stain_color(Color(0.35, 0.03, 0.03, 0.6))
	var applied: Color = (stain.material as ShaderMaterial).get_shader_parameter(&"stain_color")
	assert_that(applied.is_equal_approx(Color(0.35, 0.03, 0.03, 0.6))).is_true()


func test_growing_stain_progress_starts_at_zero_and_grows() -> void:
	var scene: PackedScene = load("res://scenes/run/EnvironmentDrip/EnvironmentDrip.tscn")
	var instance: Node2D = auto_free(scene.instantiate())
	var stain := instance.get_node("Stain") as GrowingStain
	stain.growth_seconds = 1.0
	stain._ready()
	assert_float((stain.material as ShaderMaterial).get_shader_parameter(&"progress")).is_equal(0.0)
	stain._process(0.5)
	assert_float((stain.material as ShaderMaterial).get_shader_parameter(&"progress")).is_equal_approx(0.5, 0.001)
	stain._process(10.0)
	assert_float((stain.material as ShaderMaterial).get_shader_parameter(&"progress")).is_equal_approx(1.0, 0.001)


func test_arenas_have_drip_spots_configured() -> void:
	for path in ["res://data/arenas/crypt.tres", "res://data/arenas/ossuary.tres"]:
		var arena: ArenaData = load(path)
		assert_bool(arena.drip_spots.is_empty()).is_false()


func test_hub_trees_have_sway_shader() -> void:
	var hub: PackedScene = load("res://scenes/hub/Hub/Hub.tscn")
	var instance: Node2D = auto_free(hub.instantiate())
	var props := instance.get_node("World/Props")
	var checked := 0
	for child in props.get_children():
		if child.name.begins_with("Tree"):
			var sprite := child.get_node("Sprite") as Sprite2D
			assert_object(sprite.material).is_not_null()
			checked += 1
	assert_int(checked).is_greater(0)
