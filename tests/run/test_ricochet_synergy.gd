extends GdUnitTestSuite
## Sinergia Ricochet (M13, #86): il rimbalzo e' una proprieta' del proiettile (Projectile._bounces_left,
## da WeaponData.ricochet_bounces) e del pool che lo spara (ProjectilePool.targets), non del percorso che
## ha chiesto lo sparo. Ventaglio (piu' proiettili dalla stessa WeaponData, Weapon.try_fire) e Anello
## arcano (WandAbilities.spawn_ring, duplica player.weapon_data()) passano entrambi dallo stesso
## ProjectilePool con lo stesso WeaponData/duplicato: ereditano ricochet_bounces automaticamente, senza
## bisogno di codice dedicato per ognuno. Vedi anche docs/BEST_PRACTICES.md §3.1.2.

func _pool_with_targets(hit_enemy: Node2D, other: Node2D) -> ProjectilePool:
	var pool: ProjectilePool = auto_free(ProjectilePool.new())
	pool.projectile_scene = load("res://scenes/run/Projectile/Projectile.tscn")
	add_child(pool)
	pool.targets = func() -> Array[Node2D]: return [hit_enemy, other]
	return pool

func _target(position: Vector2) -> Node2D:
	var node: Node2D = auto_free(Node2D.new())
	add_child(node)
	node.global_position = position
	return node

func _hurtbox_on(node: Node2D) -> Hurtbox:
	var hurtbox: Hurtbox = auto_free(Hurtbox.new())
	node.add_child(hurtbox)
	return hurtbox

func _active_projectiles(pool: ProjectilePool) -> Array[Projectile]:
	var result: Array[Projectile] = []
	for child in pool.get_children():
		if child is Projectile and child.visible:
			result.append(child)
	return result


## Ventaglio: tutti i proiettili di un singolo colpo condividono la stessa WeaponData dell'arma
## (Weapon.try_fire, stesso "data" per ogni k del ventaglio), quindi tutti rimbalzano allo stesso modo.
func test_ventaglio_projectiles_all_ricochet() -> void:
	var hit_enemy := _target(Vector2(50.0, 0.0))
	var other := _target(Vector2(0.0, 40.0))
	var hurtbox := _hurtbox_on(hit_enemy)
	var pool := _pool_with_targets(hit_enemy, other)

	var weapon: Weapon = auto_free(Weapon.new())
	weapon.data = WeaponData.new()
	weapon.data.projectile_count = 3
	weapon.data.ricochet_bounces = 1
	add_child(weapon)
	weapon.set_physics_process(false)
	weapon.fired.connect(pool.spawn)
	assert_int(weapon.try_fire(Vector2.RIGHT)).is_equal(1)

	var fired := _active_projectiles(pool)
	assert_int(fired.size()).is_equal(3)
	for projectile in fired:
		projectile._on_hit(hurtbox)
		assert_bool(projectile._active).is_true()  # rimbalzato sull'altro bersaglio, non sparito
		projectile._on_hit(hurtbox)
		assert_bool(projectile._active).is_false()  # un solo rimbalzo concesso (ricochet_bounces = 1)


## Anello arcano: WandAbilities.spawn_ring duplica player.weapon_data() (StatApplier vi ha gia'
## scritto ricochet_bounces con gli upgrade/equip correnti), quindi i proiettili dell'anello ereditano
## lo stesso numero di rimbalzi dell'arma base, non zero.
func test_arcane_ring_projectiles_inherit_ricochet_from_current_weapon() -> void:
	var hit_enemy := _target(Vector2(50.0, 0.0))
	var other := _target(Vector2(0.0, 40.0))
	var hurtbox := _hurtbox_on(hit_enemy)
	var pool := _pool_with_targets(hit_enemy, other)

	var player: Player = auto_free(load("res://scenes/run/Player/Player.tscn").instantiate())
	add_child(player)
	player.weapon_data().ricochet_bounces = 1

	var wand: WandAbilities = auto_free(WandAbilities.new())
	add_child(wand)
	wand.setup(player, pool, pool.targets)
	wand.spawn_ring(4, 1.0)

	var fired := _active_projectiles(pool)
	assert_int(fired.size()).is_equal(4)
	for projectile in fired:
		projectile._on_hit(hurtbox)
		assert_bool(projectile._active).is_true()
