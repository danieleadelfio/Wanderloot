class_name HitFlash
extends Node
## Flash bianco sul target quando colpito. Collegare a Hurtbox.hurt.

@export var target: CanvasItem
@export var flash_color: Color = Color(4.0, 4.0, 4.0)
@export var duration: float = 0.12

var _tween: Tween


func flash(_amount: int = 0) -> void:
	if target == null:
		return
	if _tween != null:
		_tween.kill()
	target.modulate = flash_color
	_tween = create_tween()
	_tween.tween_property(target, "modulate", Color.WHITE, duration)
