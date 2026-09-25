class_name GrowingStain
extends Sprite2D
## Pozzanghera/pozza che cresce da vuota a piena in growth_seconds da quando compare in scena (M12,
## #86). Anima l'uniform "progress" dello shader growing_stain.gdshader: TIME nello shader e' dall'avvio
## del motore, non da quando nasce l'istanza, quindi la crescita va guidata da qui.

@export var growth_seconds: float = 10.0

var _elapsed: float = 0.0


func _ready() -> void:
	if material:
		material.set_shader_parameter(&"progress", 0.0)


func _process(delta: float) -> void:
	if material == null or _elapsed >= growth_seconds:
		set_process(false)
		return
	_elapsed += delta
	material.set_shader_parameter(&"progress", clampf(_elapsed / growth_seconds, 0.0, 1.0))


## Colore della macchia (acqua nella Cripta, sangue nell'Ossario): lo imposta chi istanzia la scena.
func set_stain_color(color: Color) -> void:
	if material:
		material.set_shader_parameter(&"stain_color", color)
