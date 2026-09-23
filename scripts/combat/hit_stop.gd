class_name HitStop
extends Node
## Hitstop globale breve via Engine.time_scale. Solo per eventi rari (player colpito): i colpi frequenti
## sui nemici usano il freeze locale del nemico (EnemyData.hit_freeze), non rallentano tutto il gioco.

@export_range(0.0, 1.0, 0.01) var time_scale: float = 0.05
@export var duration: float = 0.08

var _active: bool = false


func trigger(_amount: int = 0) -> void:
	if _active or duration <= 0.0:
		return
	_active = true
	Engine.time_scale = time_scale
	# Timer in tempo reale e attivo anche in pausa: il time_scale torna sempre a 1.
	await get_tree().create_timer(duration, true, false, true).timeout
	_restore()


func _exit_tree() -> void:
	_restore()


func _restore() -> void:
	if _active:
		_active = false
		Engine.time_scale = 1.0
