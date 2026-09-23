class_name Blink
extends Node
## Lampeggio del target durante gli i-frames. Collegare a Hurtbox.invulnerable_changed.

@export var target: CanvasItem
@export var period: float = 0.1
@export_range(0.0, 1.0, 0.05) var low_alpha: float = 0.3

var _tween: Tween


func set_active(active: bool) -> void:
	if target == null:
		return
	if _tween != null:
		_tween.kill()
	target.self_modulate.a = 1.0
	if not active:
		return
	_tween = create_tween().set_loops()
	_tween.tween_property(target, "self_modulate:a", low_alpha, period * 0.5)
	_tween.tween_property(target, "self_modulate:a", 1.0, period * 0.5)
