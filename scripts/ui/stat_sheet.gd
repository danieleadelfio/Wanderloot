class_name StatSheet
extends RefCounted
## Righe [chiave di traduzione, valore] delle statistiche del personaggio (HUD in run, scheda Statistiche nell'hub).
## Logica pura: legge PlayerStats e WeaponData gia' calcolati (base + equip + potenziamenti).


static func rows(stats: PlayerStats, weapon: WeaponData) -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []
	result.append(PackedStringArray(["STAT_MAX_HP", str(stats.max_hp)]))
	result.append(PackedStringArray(["STAT_MOVE_SPEED", str(roundi(stats.move_speed))]))
	result.append(PackedStringArray(["STAT_DAMAGE", str(weapon.damage)]))
	result.append(PackedStringArray(["STAT_FIRE_RATE", "%.1f/s" % weapon.fire_rate]))
	result.append(PackedStringArray(["STAT_PROJECTILES", str(weapon.projectile_count)]))
	result.append(PackedStringArray(["STAT_PIERCE", str(weapon.pierce)]))
	result.append(PackedStringArray(["STAT_COUNT_BONUS", "+%d" % stats.count_bonus]))
	result.append(PackedStringArray(["STAT_PROJECTILE_SPEED", str(roundi(weapon.projectile_speed))]))
	result.append(PackedStringArray(["STAT_PROJECTILE_LIFETIME", "%.2fs" % weapon.projectile_lifetime]))
	result.append(PackedStringArray(["STAT_KNOCKBACK", str(roundi(weapon.knockback))]))
	result.append(PackedStringArray(["STAT_PICKUP_RADIUS", str(roundi(stats.pickup_radius))]))
	result.append(PackedStringArray(["STAT_INVULNERABILITY", "%.2fs" % stats.invulnerability_time]))
	result.append(PackedStringArray(["STAT_EXP_BONUS", _percent(stats.exp_multiplier)]))
	result.append(PackedStringArray(["STAT_DROP_BONUS", _percent(stats.drop_chance_multiplier)]))
	return result


static func _percent(multiplier: float) -> String:
	return "%+d%%" % roundi((multiplier - 1.0) * 100.0)


## Riempie una GridContainer a 2 colonne con le righe (ricreate a ogni chiamata).
static func fill(grid: GridContainer, sheet: Array[PackedStringArray], font_size: int = 14) -> void:
	for child in grid.get_children():
		child.queue_free()
	for row in sheet:
		for i in 2:
			var label := Label.new()
			label.text = row[i]
			label.add_theme_font_size_override("font_size", font_size)
			label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95) if i == 0 else Color(1, 0.9, 0.6))
			label.add_theme_color_override("font_outline_color", Color.BLACK)
			label.add_theme_constant_override("outline_size", 3)
			if i == 1:
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			grid.add_child(label)
