class_name FrameCycler
extends Sprite2D
## Animazione minima a frame: cicla gli hframes dello spritesheet a intervallo fisso (idle/bob).

@export var frame_time: float = 0.35

var _elapsed: float = 0.0


func _process(delta: float) -> void:
	if hframes <= 1:
		return
	_elapsed += delta
	if _elapsed >= frame_time:
		_elapsed -= frame_time
		frame = (frame + 1) % hframes
