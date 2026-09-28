class_name ScreenShake
extends Node
## Scossa dello schermo quando il player viene colpito (M13, #86): sposta l'offset della Camera2D
## con un "trauma" che decade (intensita' = trauma^2). Solo visivo, nessun effetto sul gameplay.
## Collegato dalla composition root (Arena) a Player.hit_taken.

@export var camera: Camera2D
## Spostamento massimo in px a trauma pieno.
@export var max_offset: float = 14.0
## Trauma perso al secondo.
@export var decay: float = 2.6
## Trauma aggiunto per colpo (+ per punto di danno oltre il primo), tetto 1.
@export var trauma_per_hit: float = 0.45
@export var trauma_per_damage: float = 0.1

var trauma: float = 0.0


func shake(amount: int = 1) -> void:
	trauma = minf(trauma + trauma_per_hit + trauma_per_damage * maxi(amount - 1, 0), 1.0)


func _process(delta: float) -> void:
	if camera == null:
		return
	if trauma <= 0.0:
		camera.offset = Vector2.ZERO
		return
	# Tempo reale: durante l'HitStop (time_scale basso) la scossa non resta congelata.
	trauma = maxf(trauma - decay * delta / maxf(Engine.time_scale, 0.01), 0.0)
	var strength := trauma * trauma * max_offset
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
