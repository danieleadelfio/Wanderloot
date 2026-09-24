class_name ItemText
extends RefCounted
## Testi e colori di un oggetto (inventario, fabbro, inventario di run, drop): nome colorato per rarita',
## rarita', descrizione dell'oggetto base, bonus tirati e abilita'.

const RARITIES: RarityTable = preload("res://data/equipment/rarity_table.tres")
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
	if modifier.is_multiplier:
		return "%+d%% %s" % [roundi((modifier.amount - 1.0) * 100.0), name]
	match int(modifier.stat):
		UpgradeData.Stat.EXP_GAIN, UpgradeData.Stat.DROP_CHANCE:
			return "%+d%% %s" % [roundi(modifier.amount * 100.0), name]
		UpgradeData.Stat.INVULNERABILITY:
			return "+%.2fs %s" % [modifier.amount, name]
	return "%+d %s" % [roundi(modifier.amount), name]


## Nome, rarita', descrizione dell'oggetto base, bonus e abilita', una riga ciascuno.
static func tooltip(item: ItemInstance) -> String:
	var lines: PackedStringArray = ["%s  [%s]" % [title(item), rarity_name(item)], TranslationServer.translate(item.base.description)]
	for affix in item.affixes:
		lines.append("• " + modifier_text(affix))
	if item.ability:
		lines.append(TranslationServer.translate("ITEM_ABILITY") % TranslationServer.translate(item.ability.display_name))
	return "\n".join(lines)
