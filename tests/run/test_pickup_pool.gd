extends GdUnitTestSuite
## Magnete: dentro il raggio l'oggetto arriva al player ed e' assorbito una sola volta; fuori resta a terra.

const TICK: float = 1.0 / 60.0

var _pool: PickupPool
var _target: Node2D
var _exp: Array[int] = []
var _materials: Array[int] = []


func before_test() -> void:
	_exp.clear()
	_materials.clear()
	_target = auto_free(Node2D.new())
	add_child(_target)
	_pool = auto_free(PickupPool.new())
	_pool.pickup_scene = load("res://scenes/run/Pickup/Pickup.tscn")
	_pool.initial_size = 4
	_pool.pop_speed = 0.0
	_pool.target = _target
	_pool.attract_radius = 100.0
	add_child(_pool)
	_pool.set_physics_process(false)
	_pool.exp_collected.connect(func(amount: int) -> void: _exp.append(amount))
	_pool.material_collected.connect(func(_m: MaterialData, amount: int) -> void: _materials.append(amount))


func _run(seconds: float) -> void:
	for i in int(seconds / TICK):
		_pool._physics_process(TICK)


func test_pickup_inside_radius_is_attracted_and_absorbed_once() -> void:
	_pool.spawn_exp(Vector2(80, 0), 3)
	_run(1.0)
	assert_array(_exp).contains_exactly([3])
	assert_int(_pool.active_count()).is_equal(0)


func test_pickup_outside_radius_stays_until_player_gets_close() -> void:
	_pool.spawn_exp(Vector2(300, 0), 1)
	_run(1.0)
	assert_array(_exp).is_empty()
	_target.position = Vector2(220, 0)
	_run(1.0)
	assert_array(_exp).contains_exactly([1])


func test_material_pickup_reports_material_amount() -> void:
	var gel := MaterialData.new()
	gel.id = &"gel"
	_pool.spawn_material(Vector2(50, 0), gel, 2)
	_run(1.0)
	assert_array(_materials).contains_exactly([2])
	assert_array(_exp).is_empty()
