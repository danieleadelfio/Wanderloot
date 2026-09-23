class_name Health
extends Node
## Componente HP riusabile. Non gestisce la morte: emette solo segnali, decide il proprietario.

signal changed(current: int, maximum: int)
signal damaged(amount: int)
signal died

@export var max_hp: int = 10

var current: int = 0


func _ready() -> void:
	reset()


func reset(new_max: int = -1) -> void:
	if new_max > 0:
		max_hp = new_max
	current = max_hp
	changed.emit(current, max_hp)


func take_damage(amount: int) -> void:
	if is_dead() or amount <= 0:
		return
	current = maxi(current - amount, 0)
	damaged.emit(amount)
	changed.emit(current, max_hp)
	if current == 0:
		died.emit()


func is_dead() -> bool:
	return current <= 0
