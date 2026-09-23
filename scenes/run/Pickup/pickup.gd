class_name Pickup
extends Node2D
## Oggetto a terra (gemma di exp o materiale). Poolable; il movimento lo gestisce PickupPool.

enum Kind { EXP, MATERIAL }

var kind: Kind = Kind.EXP
var amount: int = 1
var item_material: MaterialData
## Da quando entra nel raggio resta attratto fino all'assorbimento.
var attracted: bool = false
var speed: float = 0.0
## Piccolo "salto" allo spawn, poi si ferma a terra.
var pop_velocity: Vector2 = Vector2.ZERO

@onready var _sprite: Sprite2D = %Sprite


func activate(at: Vector2, new_kind: Kind, new_amount: int, new_material: MaterialData, texture: Texture2D, texture_scale: float, pop: Vector2) -> void:
	global_position = at
	kind = new_kind
	amount = new_amount
	item_material = new_material
	attracted = false
	speed = 0.0
	pop_velocity = pop
	_sprite.texture = texture
	_sprite.scale = Vector2.ONE * texture_scale
	visible = true


func deactivate() -> void:
	visible = false
