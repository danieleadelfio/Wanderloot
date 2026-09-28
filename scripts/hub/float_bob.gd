class_name FloatBob
extends Node2D
## Sospensione lentissima delle isole dell'hub (GDD §7): solo traslazione verticale, sinusoide pura,
## nessuna rotazione ne' oscillazione laterale (niente effetto "barca"). Periodi lunghi e diversi per
## ogni isola, cosi' non si muovono mai all'unisono.

@export var amplitude: float = 1.5
@export var period: float = 22.0
@export var phase: float = 0.0

var _base_y: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	_base_y = position.y


# Sui tick di fisica: il nodo puo' portare con se' corpi fisici e il player (M10.1).
func _physics_process(delta: float) -> void:
	_time += delta
	position.y = _base_y + amplitude * sin(TAU * _time / period + phase)
