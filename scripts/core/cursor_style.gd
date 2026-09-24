class_name CursorStyle
extends RefCounted
## Cursore del mouse (M10.1): freccia chiara (default di progetto, menu e hub) o mirino (run in corso).

const ARROW: Texture2D = preload("res://assets/sprites/cursor_arrow.png")
const CROSSHAIR: Texture2D = preload("res://assets/sprites/cursor_crosshair.png")
const ARROW_HOTSPOT := Vector2(6, 4)
const CROSSHAIR_HOTSPOT := Vector2(24, 24)


static func use_crosshair() -> void:
	Input.set_custom_mouse_cursor(CROSSHAIR, Input.CURSOR_ARROW, CROSSHAIR_HOTSPOT)


static func use_arrow() -> void:
	Input.set_custom_mouse_cursor(ARROW, Input.CURSOR_ARROW, ARROW_HOTSPOT)
