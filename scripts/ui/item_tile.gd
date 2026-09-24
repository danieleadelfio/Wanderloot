class_name ItemTile
extends Button
## Casella quadrata con icona (oggetto con bordo della rarita' o materiale con quantita') e tooltip.
## Usata dalla schermata del loot di fine run e dal baule (M11.3).

## Oggetto nuovo guardato col mouse (perde la N).
signal seen(uid: int)

const SIZE: Vector2 = Vector2(64, 64)

var item: ItemInstance
var item_material: MaterialData
var amount: int = 0
## Oggetti equipaggiati nello stesso slot, mostrati accanto nel tooltip (M11.3, #70).
var compare: Array[ItemInstance] = []


static func for_item(value: ItemInstance) -> ItemTile:
	var tile := ItemTile.new()
	tile.item = value
	tile.icon = value.base.icon
	tile.tooltip_text = ItemText.tooltip(value)
	tile._style(ItemText.color(value))
	if value.is_new:
		tile._add_new_badge()
	return tile


## N gialla in alto a destra (oggetto nuovo); sparisce al primo passaggio del mouse.
func _add_new_badge() -> void:
	var badge := Label.new()
	badge.name = "NewBadge"
	badge.text = "N"
	badge.add_theme_font_size_override("font_size", 16)
	badge.add_theme_color_override("font_color", Color(1, 0.85, 0.15))
	badge.add_theme_color_override("font_outline_color", Color.BLACK)
	badge.add_theme_constant_override("outline_size", 5)
	badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	badge.position += Vector2(-4, 0)
	badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(badge)
	mouse_entered.connect(_on_seen, CONNECT_ONE_SHOT)

func _on_seen() -> void:
	if has_node("NewBadge"):
		get_node("NewBadge").queue_free()
	seen.emit(item.uid)


static func for_material(value: MaterialData, count: int) -> ItemTile:
	var tile := ItemTile.new()
	tile.item_material = value
	tile.amount = count
	tile.icon = value.icon
	tile.tooltip_text = "%s × %d" % [TranslationServer.translate(value.display_name), count]
	tile._style(Color(1, 0.8, 0.35))
	var label := Label.new()
	label.text = "×%d" % count
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(label)
	return tile


func _make_custom_tooltip(_for_text: String) -> Object:
	if item == null:
		return null
	return ItemText.compare_panel(item, compare)


func _style(border: Color) -> void:
	custom_minimum_size = SIZE
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.1, 0.09, 0.14, 0.95) if state == "normal" else Color(0.18, 0.16, 0.24, 0.95)
		box.border_color = border
		box.set_border_width_all(3)
		box.set_corner_radius_all(6)
		box.set_content_margin_all(6)
		add_theme_stylebox_override(state, box)
