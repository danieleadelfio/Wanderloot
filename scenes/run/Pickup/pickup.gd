class_name Pickup
extends Node2D
## Oggetto a terra (gemma di exp o materiale). Poolable; il movimento lo gestisce PickupPool.

enum Kind { EXP, MATERIAL, CONSUMABLE, ITEM }

var kind: Kind = Kind.EXP
var amount: int = 1
var item_material: MaterialData
var consumable: ConsumableData
var item: ItemInstance
## Da quando entra nel raggio resta attratto fino all'assorbimento.
var attracted: bool = false
var speed: float = 0.0
## Piccolo "salto" allo spawn, poi si ferma a terra.
var pop_velocity: Vector2 = Vector2.ZERO

## Alone degli oggetti di equipaggiamento (colore e dimensione della rarita').
var glow_scale: float = 0.0

@onready var _sprite: Sprite2D = %Sprite
@onready var _glow: Sprite2D = %Glow


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
	_sprite.self_modulate = Color.WHITE
	glow_scale = 0.0
	_glow.hide()
	visible = true
	reset_physics_interpolation()


## Tinta dell'icona (oggetti: colore della rarita').
func set_tint(color: Color) -> void:
	_sprite.self_modulate = color


## Alone pulsante dietro l'icona (oggetti trovati in run).
func set_glow(color: Color, size: float) -> void:
	glow_scale = size
	_glow.modulate = color
	_glow.scale = Vector2.ONE * size
	_glow.show()


## Chiamata dal pool a ogni tick: l'alone respira.
func pulse(time: float) -> void:
	if glow_scale > 0.0:
		var wave := sin(time * 4.0 + position.x * 0.01)
		_glow.scale = Vector2.ONE * glow_scale * (1.0 + 0.12 * wave)
		_glow.modulate.a = 0.75 + 0.25 * wave


func deactivate() -> void:
	visible = false
	item = null
	consumable = null
