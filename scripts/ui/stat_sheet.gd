class_name StatSheet
extends RefCounted
## Righe [chiave di traduzione, valore] delle statistiche del personaggio (HUD in run, scheda Statistiche
## nell'hub, inventario di run). Logica pura: legge PlayerStats e WeaponData gia' calcolati (base + equip +
## potenziamenti).


## Una riga: chiave di traduzione, estrattore del valore grezzo da stats/weapon, formattatore del valore.
static func _row_defs() -> Array[Dictionary]:
	return [
		{"label": "STAT_MAX_HP", "getter": func(s: PlayerStats, w: WeaponData) -> float: return float(s.max_hp), "format": func(v: float) -> String: return str(int(round(v)))},
		{"label": "STAT_MOVE_SPEED", "getter": func(s: PlayerStats, w: WeaponData) -> float: return s.move_speed, "format": func(v: float) -> String: return str(roundi(v))},
		{"label": "STAT_DAMAGE", "getter": func(s: PlayerStats, w: WeaponData) -> float: return float(w.damage), "format": func(v: float) -> String: return str(int(round(v)))},
		{"label": "STAT_FIRE_RATE", "getter": func(s: PlayerStats, w: WeaponData) -> float: return w.fire_rate, "format": func(v: float) -> String: return "%.1f/s" % v},
		{"label": "STAT_PROJECTILES", "getter": func(s: PlayerStats, w: WeaponData) -> float: return float(w.projectile_count), "format": func(v: float) -> String: return str(int(round(v)))},
		{"label": "STAT_PIERCE", "getter": func(s: PlayerStats, w: WeaponData) -> float: return float(w.pierce), "format": func(v: float) -> String: return str(int(round(v)))},
		{"label": "STAT_COUNT_BONUS", "getter": func(s: PlayerStats, w: WeaponData) -> float: return float(s.count_bonus), "format": func(v: float) -> String: return "+%d" % int(round(v))},
		{"label": "STAT_PROJECTILE_SPEED", "getter": func(s: PlayerStats, w: WeaponData) -> float: return w.projectile_speed, "format": func(v: float) -> String: return str(roundi(v))},
		{"label": "STAT_PROJECTILE_LIFETIME", "getter": func(s: PlayerStats, w: WeaponData) -> float: return w.projectile_lifetime, "format": func(v: float) -> String: return "%.2fs" % v},
		{"label": "STAT_KNOCKBACK", "getter": func(s: PlayerStats, w: WeaponData) -> float: return w.knockback, "format": func(v: float) -> String: return str(roundi(v))},
		{"label": "STAT_PICKUP_RADIUS", "getter": func(s: PlayerStats, w: WeaponData) -> float: return s.pickup_radius, "format": func(v: float) -> String: return str(roundi(v))},
		{"label": "STAT_INVULNERABILITY", "getter": func(s: PlayerStats, w: WeaponData) -> float: return s.invulnerability_time, "format": func(v: float) -> String: return "%.2fs" % v},
		{"label": "STAT_EXP_BONUS", "getter": func(s: PlayerStats, w: WeaponData) -> float: return s.exp_multiplier, "format": func(v: float) -> String: return _percent(v)},
		{"label": "STAT_DROP_BONUS", "getter": func(s: PlayerStats, w: WeaponData) -> float: return s.drop_chance_multiplier, "format": func(v: float) -> String: return _percent(v)},
	]


static func rows(stats: PlayerStats, weapon: WeaponData) -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []
	for row in _row_defs():
		var getter: Callable = row["getter"]
		var format: Callable = row["format"]
		var value: float = getter.call(stats, weapon)
		result.append(PackedStringArray([row.label, format.call(value)]))
	return result


## Righe a 4 colonne [chiave, base, bonus equip, finale] (M12, #86): base_stats/base_weapon sono i valori
## di partenza del player (mai equip ne' potenziamenti); stats/weapon sono i valori finali da mostrare
## (in hub: base + equip; in run: base + equip + potenziamenti); equip_modifiers sono solo i modificatori
## dell'equip indossato, per isolarne il contributo dal resto. Il bonus e' la variazione percentuale
## rispetto alla base (formato della statistica, non forzato in %) tranne quando la base e' zero, dove si
## mostra il delta assoluto nel formato della statistica.
static func equip_rows(base_stats: PlayerStats, base_weapon: WeaponData, stats: PlayerStats, weapon: WeaponData, equip_modifiers: Array[StatModifier]) -> Array[PackedStringArray]:
	var equip_stats: PlayerStats = base_stats.duplicate()
	var equip_weapon: WeaponData = base_weapon.duplicate()
	StatApplier.apply_modifiers(equip_modifiers, equip_stats, equip_weapon)
	var result: Array[PackedStringArray] = []
	for row in _row_defs():
		var getter: Callable = row["getter"]
		var format: Callable = row["format"]
		var base_v: float = getter.call(base_stats, base_weapon)
		var equip_v: float = getter.call(equip_stats, equip_weapon)
		var final_v: float = getter.call(stats, weapon)
		result.append(PackedStringArray([row.label, format.call(base_v), _bonus_text(base_v, equip_v, format), format.call(final_v)]))
	return result


## Percentuale del contributo dell'equip rispetto alla base; "" se nullo. Con base zero (es.
## Invulnerabilita' di partenza) mostra il delta assoluto nel formato della statistica invece della %.
static func _bonus_text(base_v: float, equip_v: float, format: Callable) -> String:
	var delta := equip_v - base_v
	if is_zero_approx(delta):
		return ""
	if not is_zero_approx(base_v):
		return "%+d%%" % roundi((equip_v / base_v - 1.0) * 100.0)
	return "%s%s" % ["+" if delta > 0.0 else "-", format.call(absf(delta))]


static func _percent(multiplier: float) -> String:
	return "%+d%%" % roundi((multiplier - 1.0) * 100.0)


## Riempie una GridContainer a 2 colonne con le righe di rows() (ricreate a ogni chiamata).
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


## Riempie una GridContainer a 4 colonne con le righe di equip_rows(): chiave, base (giallo, fisso),
## bonus equip (verde, vuoto se nullo), finale (bianco).
static func fill_with_equip(grid: GridContainer, sheet: Array[PackedStringArray], font_size: int = 14) -> void:
	for child in grid.get_children():
		child.queue_free()
	var colors := [Color(0.85, 0.85, 0.95), Color(1, 0.9, 0.6), Color(0.5, 0.9, 0.5), Color(1, 1, 1)]
	var alignments := [HORIZONTAL_ALIGNMENT_LEFT, HORIZONTAL_ALIGNMENT_RIGHT, HORIZONTAL_ALIGNMENT_RIGHT, HORIZONTAL_ALIGNMENT_RIGHT]
	for row in sheet:
		for i in 4:
			var label := Label.new()
			label.text = row[i]
			label.add_theme_font_size_override("font_size", font_size)
			label.add_theme_color_override("font_color", colors[i])
			label.add_theme_color_override("font_outline_color", Color.BLACK)
			label.add_theme_constant_override("outline_size", 3)
			label.horizontal_alignment = alignments[i]
			grid.add_child(label)
