class_name LavaZone
extends Node2D
## Zona quadrata del Pavimento di lava (M13, #86): preavviso (bordo e riempimento arancione che
## pulsa), poi lava attiva per `active_time`. Nessuna Hitbox: il direttore degli eventi controlla se
## il player e' dentro (danno a tempo come il veleno, non un colpo). Poolata (start/stop).

const WARNING_COLOR := Color(1.0, 0.55, 0.15)
const LAVA_DARK := Color(0.55, 0.08, 0.02, 0.92)
const LAVA_BRIGHT := Color(1.0, 0.55, 0.1, 0.95)
const LAVA_HOT := Color(1.0, 0.9, 0.4, 0.9)

var size: float = 200.0
var _warning: float = 1.0
var _active_time: float = 2.0
var _elapsed: float = 0.0
var _running: bool = false
var _seed: float = 0.0


func _ready() -> void:
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unshaded
	hide()
	set_process(false)


func start(center: Vector2, side: float, warning: float, active_time: float) -> void:
	global_position = center
	size = side
	_warning = warning
	_active_time = active_time
	_elapsed = 0.0
	_seed = randf() * 100.0
	_running = true
	show()
	reset_physics_interpolation()
	set_process(true)
	queue_redraw()


func stop() -> void:
	_running = false
	hide()
	set_process(false)


func is_running() -> bool:
	return _running


func is_active() -> bool:
	return _running and _elapsed >= _warning


func rect() -> Rect2:
	return Rect2(global_position - Vector2.ONE * size * 0.5, Vector2.ONE * size)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _warning + _active_time:
		stop()
		return
	queue_redraw()


func _draw() -> void:
	var local := Rect2(-Vector2.ONE * size * 0.5, Vector2.ONE * size)
	if not is_active():
		var ratio := clampf(_elapsed / maxf(_warning, 0.01), 0.0, 1.0)
		var pulse := 0.5 + 0.5 * sin(_elapsed * 14.0)
		draw_rect(local, Color(WARNING_COLOR, 0.12 + 0.2 * ratio + 0.08 * pulse))
		draw_rect(local, Color(WARNING_COLOR, 0.9), false, 3.0)
		# Riempimento dal centro: quanto manca alla lava.
		draw_rect(local.grow(-size * 0.5 * (1.0 - ratio)), Color(WARNING_COLOR, 0.25))
		return
	var t := _elapsed + _seed
	# Alone caldo attorno, base scura, cuore incandescente che respira.
	draw_rect(local.grow(6.0), Color(1.0, 0.4, 0.05, 0.25), false, 12.0)
	draw_rect(local, LAVA_DARK)
	draw_rect(local.grow(-size * 0.06), Color(LAVA_BRIGHT, 0.8 + 0.12 * sin(t * 3.0)))
	# Croste scure che galleggiano piano (forme fisse per zona, pseudo-casuali dal seed).
	for i in 6:
		var c := local.position + Vector2(_rand(i, 1.0), _rand(i, 2.0)) * size * 0.76 + Vector2.ONE * size * 0.12
		c += Vector2(sin(t * 0.6 + i), cos(t * 0.5 + i * 2.0)) * size * 0.02
		var r := size * (0.06 + 0.05 * _rand(i, 3.0))
		var crust := PackedVector2Array()
		for k in 6:
			var angle := TAU * k / 6.0 + _rand(i, 4.0 + k)
			crust.append(c + Vector2.RIGHT.rotated(angle) * r * (0.7 + 0.5 * _rand(i, 10.0 + k)))
		draw_colored_polygon(crust, Color(0.32, 0.06, 0.02, 0.85))
	# Bolle incandescenti che si gonfiano e si sgonfiano.
	for i in 8:
		var at := local.position + Vector2(_rand(i, 20.0), _rand(i, 21.0)) * size * 0.8 + Vector2.ONE * size * 0.1
		var r := size * (0.015 + 0.02 * (0.5 + 0.5 * sin(t * 2.5 + i * 1.7)))
		draw_circle(at, maxf(r, 1.0), LAVA_HOT)
	draw_rect(local, Color(0.25, 0.03, 0.0, 0.95), false, 4.0)


## Numero pseudo-casuale in [0, 1) fisso per zona (dipende dal seed estratto a start()).
func _rand(i: int, salt: float) -> float:
	return fposmod(sin(i * 12.9898 + salt * 78.233 + _seed) * 43758.5453, 1.0)
