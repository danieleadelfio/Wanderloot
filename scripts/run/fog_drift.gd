class_name FogDrift
extends Node2D
## Nebbia: macchie morbide semitrasparenti che scorrono lente e rientrano dal lato opposto. Unshaded,
## cosi' resta visibile come foschia anche al buio. Configurata dalla composition root.

@export var area: Rect2 = Rect2(-800.0, -500.0, 1600.0, 1000.0)
@export var speed_range: Vector2 = Vector2(8.0, 24.0)

var _blobs: Array[Sprite2D] = []
var _velocities: Array[Vector2] = []


func setup(color: Color, count: int, rng: RandomNumberGenerator) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for i in count:
		var blob := Sprite2D.new()
		blob.texture = texture
		blob.material = material
		blob.modulate = color
		blob.scale = Vector2.ONE * rng.randf_range(2.5, 5.0)
		blob.position = Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		add_child(blob)
		_blobs.append(blob)
		_velocities.append(Vector2.RIGHT.rotated(rng.randf_range(-0.4, 0.4)) * rng.randf_range(speed_range.x, speed_range.y))


# Movimento sui tick di fisica: con l'interpolazione attiva resta fluido (M10.1).
func _physics_process(delta: float) -> void:
	for i in _blobs.size():
		var blob := _blobs[i]
		blob.position += _velocities[i] * delta
		if blob.position.x > area.end.x + 300.0:
			blob.position.x = area.position.x - 300.0
