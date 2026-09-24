class_name Poison
extends Node
## Veleno su un Health: danno a tempo e tinta verde del bersaglio finche' dura.

signal changed(active: bool)

@export var health: Health
## Nodo tinto di verde durante il veleno.
@export var tint_target: CanvasItem
@export var tint: Color = Color(0.55, 1.0, 0.45)

var state := PoisonState.new()


func apply(duration: float, interval: float, damage: int) -> void:
	var was := state.is_active()
	state.apply(duration, interval, damage)
	if not was:
		_set_tint(true)


func clear() -> void:
	state.remaining = 0.0
	_set_tint(false)


func _physics_process(delta: float) -> void:
	if not state.is_active():
		return
	var damage := state.tick(delta)
	if damage > 0 and health and not health.is_dead():
		health.take_damage(damage)
	if not state.is_active():
		_set_tint(false)


func _set_tint(active: bool) -> void:
	if tint_target:
		tint_target.self_modulate = tint if active else Color.WHITE
	changed.emit(active)
