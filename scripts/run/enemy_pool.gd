class_name EnemyPool
extends Node2D
## Pool di nemici di un singolo tipo (una scena). Deve stare all'origine.

signal enemy_died(enemy: Enemy)

@export var enemy_scene: PackedScene
@export var initial_size: int = 32
@export var can_grow: bool = true

var _free: Array[Enemy] = []
var _active_count: int = 0


func _ready() -> void:
	for i in initial_size:
		_free.append(_create())


func spawn(spawn_position: Vector2, target: Node2D) -> Enemy:
	if _free.is_empty():
		if not can_grow:
			return null
		_free.append(_create())
	var enemy: Enemy = _free.pop_back()
	enemy.target = target
	enemy.activate(spawn_position)
	_active_count += 1
	return enemy


func active_count() -> int:
	return _active_count


func _create() -> Enemy:
	var enemy := enemy_scene.instantiate() as Enemy
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)
	return enemy


func _on_enemy_died(enemy: Enemy) -> void:
	_active_count -= 1
	_free.append(enemy)
	enemy_died.emit(enemy)
