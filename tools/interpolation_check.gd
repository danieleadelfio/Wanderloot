extends SceneTree
## Controllo dell'interpolazione (M10.2): un nemico preso dal pool deve comparire subito nel punto nuovo,
## senza scivolare da quello vecchio. Richiede un display (non headless):
## godot --path . -s tools/interpolation_check.gd   -> stampa OK o SCIVOLA
## Fisica rallentata a 4 tick/s per rendere visibile l'interpolazione.

var _pool: EnemyPool
var _enemy: Enemy
var _frame: int = 0
var _drawn: Array[Vector2] = []


func _initialize() -> void:
	Engine.physics_ticks_per_second = 4
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.size = Vector2(1280, 720)
	root.add_child(background)
	_pool = EnemyPool.new()
	_pool.enemy_scene = load("res://scenes/run/Enemies/EnemyBasic/EnemyBasic.tscn")
	_pool.initial_size = 1
	root.add_child(_pool)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 5:
		var far := Node2D.new()
		far.position = Vector2(-5000, -5000)
		root.add_child(far)
		_enemy = _pool.spawn(Vector2(200, 200), far)
		_enemy.set_physics_process(false)
	elif _frame == 60:
		_enemy.deactivate()
	elif _frame == 70:
		_enemy = _pool.spawn(Vector2(900, 500), _enemy.target)
		_enemy.set_physics_process(false)
	elif _frame > 70 and _frame <= 74:
		_drawn.append(_green_centroid())
	elif _frame > 74:
		var ok := _drawn.all(func(p: Vector2) -> bool: return p.distance_to(Vector2(900, 500)) < 30.0)
		print("interpolation_check: %s %s" % ["OK" if ok else "SCIVOLA", _drawn])
		quit(0 if ok else 1)
	return false


func _green_centroid() -> Vector2:
	var image := root.get_texture().get_image()
	var sum := Vector2.ZERO
	var count := 0
	for y in range(0, image.get_height(), 3):
		for x in range(0, image.get_width(), 3):
			var c := image.get_pixel(x, y)
			if c.g > 0.5 and c.r < 0.6:
				sum += Vector2(x, y)
				count += 1
	return sum / count if count > 0 else Vector2(-1, -1)
