class_name ItemText
extends RefCounted
## Testi e colori di un oggetto (inventario, fabbro, inventario di run, drop): nome colorato per rarita',
## rarita', descrizione dell'oggetto base, bonus tirati e abilita'.

const RARITIES: RarityTable = preload("res://data/equipment/rarity_table.tres")
const AFFIXES: AffixTable = preload("res://data/equipment/affix_table.tres")
const STAT_KEYS: Dictionary[int, String] = {
	UpgradeData.Stat.DAMAGE: "STAT_DAMAGE", UpgradeData.Stat.FIRE_RATE: "STAT_FIRE_RATE",
	UpgradeData.Stat.PROJECTILE_SPEED: "STAT_PROJECTILE_SPEED", UpgradeData.Stat.MOVE_SPEED: "STAT_MOVE_SPEED",
	UpgradeData.Stat.MAX_HP: "STAT_MAX_HP", UpgradeData.Stat.PROJECTILE_LIFETIME: "STAT_PROJECTILE_LIFETIME",
	UpgradeData.Stat.PICKUP_RADIUS: "STAT_PICKUP_RADIUS", UpgradeData.Stat.EXP_GAIN: "STAT_EXP_BONUS",
	UpgradeData.Stat.DROP_CHANCE: "STAT_DROP_BONUS", UpgradeData.Stat.INVULNERABILITY: "STAT_INVULNERABILITY",
	UpgradeData.Stat.KNOCKBACK: "STAT_KNOCKBACK", UpgradeData.Stat.PROJECTILE_COUNT: "STAT_PROJECTILES",
	UpgradeData.Stat.PIERCE: "STAT_PIERCE", UpgradeData.Stat.COUNT_BONUS: "STAT_COUNT_BONUS",
}


static func color(item: ItemInstance) -> Color:
	return RARITIES.tier(item.rarity).color if item else Color(0.72, 0.72, 0.72)


static func rarity_name(item: ItemInstance) -> String:
	return TranslationServer.translate(RARITIES.tier(item.rarity).display_name)


static func title(item: ItemInstance) -> String:
	return TranslationServer.translate(item.base.display_name)


## Testo di un bonus: "+12% Cadenza", "+2 Danno", "+15% Bonus exp", "+0.10s Invulnerabilita'".
static func modifier_text(modifier: StatModifier) -> String:
	var name := TranslationServer.translate(STAT_KEYS.get(int(modifier.stat), "?"))
	return "%s %s" % [value_text(int(modifier.stat), modifier.amount, modifier.is_multiplier), name]


## Solo il numero: "+12%", "+2", "+0.10s".
static func value_text(stat: int, amount: float, is_multiplier: bool) -> String:
	if is_multiplier:
		return "%+d%%" % roundi((amount - 1.0) * 100.0)
	match stat:
		UpgradeData.Stat.EXP_GAIN, UpgradeData.Stat.DROP_CHANCE:
			return "%+d%%" % roundi(amount * 100.0)
		UpgradeData.Stat.INVULNERABILITY:
			return "+%.2fs" % amount
	return "%+d" % roundi(amount)


## Intervallo possibile del bonus per la rarita' dell'oggetto, es. "(+10% – +20%)"; vuoto se non tirato dalla tabella.
static func range_text(modifier: StatModifier, rarity: int) -> String:
	var source := AFFIXES.find(int(modifier.stat), modifier.is_multiplier)
	if source == null:
		return ""
	var tier := RARITIES.tier(rarity)
	var low := value_text(int(modifier.stat), ItemRoller.value_at(source, tier.roll_min), modifier.is_multiplier)
	var high := value_text(int(modifier.stat), ItemRoller.value_at(source, tier.roll_max), modifier.is_multiplier)
	return "(%s – %s)" % [low, high]


## Nome, rarita', descrizione dell'oggetto base, bonus e abilita', una riga ciascuno.
static func tooltip(item: ItemInstance) -> String:
	var lines: PackedStringArray = ["%s  [%s]" % [title(item), rarity_name(item)], TranslationServer.translate(item.base.description)]
	for affix in item.affixes:
		lines.append("• %s  %s" % [modifier_text(affix), range_text(affix, item.rarity)])
	if item.ability:
		lines.append(TranslationServer.translate("ITEM_ABILITY") % _ability_name(item))
	return "\n".join(lines)


## Riquadro del tooltip: nome colorato, rarita', descrizione, bonus con intervallo, abilita'. header sopra (es. "Equipaggiato").
static func tooltip_panel(item: ItemInstance, header: String = "") -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 260
	box.add_theme_constant_override("separation", 2)
	if header != "":
		box.add_child(_line(header, Color(0.8, 0.8, 0.9, 0.7), 12))
	box.add_child(_line(title(item), color(item), 18))
	box.add_child(_line(rarity_name(item), color(item), 13))
	box.add_child(_line(TranslationServer.translate(item.base.description), Color(0.9, 0.88, 0.8), 13))
	for affix in item.affixes:
		var row := HBoxContainer.new()
		row.add_child(_line("• " + modifier_text(affix), Color(0.75, 1, 0.75), 14))
		row.add_child(_line(range_text(affix, item.rarity), Color(1, 1, 1, 0.95), 12))
		box.add_child(row)
	if item.ability:
		box.add_child(_line(TranslationServer.translate("ITEM_ABILITY") % _ability_name(item), Color(1, 0.85, 0.4), 14))
	return box


## Tooltip di confronto: l'oggetto a sinistra, quelli equipaggiati nello stesso slot a destra.
static func compare_panel(item: ItemInstance, equipped: Array[ItemInstance]) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.add_child(tooltip_panel(item))
	for other in equipped:
		row.add_child(VSeparator.new())
		row.add_child(tooltip_panel(other, TranslationServer.translate("TOOLTIP_EQUIPPED")))
	return row


static func _ability_name(item: ItemInstance) -> String:
	return "%s Lv%d" % [TranslationServer.translate(item.ability.display_name), item.ability_level(RARITIES)]


static func _line(text: String, font_color: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_font_size_override("font_size", size)
	return label