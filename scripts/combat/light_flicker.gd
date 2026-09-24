class_name LightFlicker
extends PointLight2D
## Tremolio di una luce (torce, candele): energia che oscilla attorno al valore base con due sinusoidi sfasate.

@export var amplitude: float = 0.18
@export var speed: float = 7.0

var _base_energy: float = 1.0
var _phase: float = 0.0


func _ready() -> void:
	_base_energy = energy
	_phase = randf() * TAU


func _process(delta: float) -> void:
	_phase += delta * speed
	energy = _base_energy * (1.0 + amplitude * (sin(_phase) * 0.6 + sin(_phase * 2.7 + 1.3) * 0.4))
