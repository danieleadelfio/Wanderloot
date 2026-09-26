extends GdUnitTestSuite
## Consumabili (M10.1): tabella dei drop, magnete su tutta l'arena, cura, furia.

const TICK: float = 1.0 / 60.0


func _entry(id: StringName, weight: float) -> ConsumableData:
	var data := ConsumableData.new()
	data.id = id
	data.weight = weight
	return data


func test_pick_respects_weights_and_chance() -> void:
	var table := ConsumableTable.new()
	table.entries = [_entry(&"a", 1.0), _entry(&"b", 0.0)] as Array[ConsumableData]
	table.drop_chance = 1.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 30:
		assert_str(String(table.roll(rng).id)).is_equal("a")
	table.drop_chance = 0.0
	assert_object(table.roll(rng)).is_null()


func test_real_table_has_three_consumables() -> void:
	var table: ConsumableTable = load("res://data/consumables/consumable_table.tres")
	assert_int(table.entries.size()).is_equal(3)
	var crypt: ArenaData = load("res://data/arenas/crypt.tres")
	assert_object(crypt.consumables).is_not_null()


func test_magnet_attracts_everything_in_the_arena() -> void:
	var target: Node2D = auto_free(Node2D.new())
	add_child(target)
	var pool: PickupPool = auto_free(PickupPool.new())
	pool.pickup_scene = load("res://scenes/run/Pickup/Pickup.tscn")
	pool.initial_size = 4
	pool.pop_speed = 0.0
	pool.target = target
	pool.attract_radius = 50.0
	add_child(pool)
	pool.set_physics_process(false)
	var collected := [0]
	pool.exp_collected.connect(func(amount: int) -> void: collected[0] += amount)
	pool.spawn_exp(Vector2(900, 0), 2)
	pool.spawn_exp(Vector2(-700, 400), 3)
	for i in 60:
		pool._physics_process(TICK)
	assert_int(collected[0]).is_equal(0)
	pool.attract_all(4.0)
	for i in 180:
		pool._physics_process(TICK)
	assert_int(collected[0]).is_equal(5)


## Arene 10x (M13, #86): il Magnete deve recuperare un oggetto anche dall'altra parte di un'arena
## enorme (~8000px), non solo da poche centinaia di px come nel test sopra.
func test_magnet_attracts_from_across_a_10x_arena() -> void:
	var target: Node2D = auto_free(Node2D.new())
	add_child(target)
	var pool: PickupPool = auto_free(PickupPool.new())
	pool.pickup_scene = load("res://scenes/run/Pickup/Pickup.tscn")
	pool.initial_size = 2
	pool.pop_speed = 0.0
	pool.target = target
	add_child(pool)
	pool.set_physics_process(false)
	var collected := [0]
	pool.exp_collected.connect(func(amount: int) -> void: collected[0] += amount)
	pool.spawn_exp(Vector2(7000, 4000), 1)
	pool.attract_all(4.0)
	# Budget generoso (20s simulati) per attraversare tutta l'arena in accelerazione.
	for i in 1200:
		pool._physics_process(TICK)
	assert_int(collected[0]).is_equal(1)


func test_heal_is_capped_at_max() -> void:
	var health: Health = auto_free(Health.new())
	health.reset(5)
	health.take_damage(3)
	health.heal(2)
	assert_int(health.current).is_equal(4)
	health.heal(10)
	assert_int(health.current).is_equal(5)


func test_frenzy_multiplies_fire_rate() -> void:
	var weapon: Weapon = auto_free(Weapon.new())
	weapon.data = WeaponData.new()
	weapon.data.fire_rate = 10.0
	weapon.rate_multiplier = 2.0
	var shots := 0
	for i in 60:
		weapon._physics_process(TICK)
		shots += weapon.try_fire(Vector2.RIGHT)
	assert_int(shots).is_between(19, 21)
