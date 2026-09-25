class_name ItemRoller
extends RefCounted
## Crea un'istanza di un oggetto base a una rarita': tira i bonus e, se la rarita' lo prevede, l'abilita'.
## Logica pura, testata. Usata da crafting, drop in run e fusione.

## Statistiche intere: il valore tirato si arrotonda (almeno 1).
const INTEGER_STATS: Array[int] = [
	UpgradeData.Stat.DAMAGE, UpgradeData.Stat.MAX_HP, UpgradeData.Stat.PROJECTILE_COUNT,
	UpgradeData.Stat.PIERCE, UpgradeData.Stat.COUNT_BONUS,
]


static func roll(base: EquipmentData, tier_index: int, rarities: RarityTable, affixes: AffixTable, abilities: AbilityCatalog, rng: RandomNumberGenerator) -> ItemInstance:
	var tier := rarities.tier(tier_index)
	var item := ItemInstance.new(base, clampi(tier_index, 0, rarities.highest()))
	# Nessuna statistica ripetuta: esclusi i bonus che l'oggetto base ha gia' (M11.3, #71).
	var fixed: Array[int] = []
	for modifier in base.modifiers:
		fixed.append(int(modifier.stat))
	# weight <= 0 = disattivato (M12, #86: Gittata e Persistenza fuori dal pool), mai estraibile.
	var pool: Array[AffixRoll] = affixes.rolls.filter(func(r: AffixRoll) -> bool: return r.allows(base.slot) and not fixed.has(int(r.stat)) and r.weight > 0.0)
	for i in mini(tier.affix_count, pool.size()):
		var chosen := _pick(pool, rng)
		pool.erase(chosen)
		item.affixes.append(_modifier(chosen, rng.randf_range(tier.roll_min, tier.roll_max)))
	if tier.ability_count > 0 and abilities and not abilities.abilities.is_empty():
		item.ability = abilities.abilities[rng.randi_range(0, abilities.abilities.size() - 1)]
	return item


static func _pick(pool: Array[AffixRoll], rng: RandomNumberGenerator) -> AffixRoll:
	var total := 0.0
	for r in pool:
		total += maxf(r.weight, 0.0)
	var value := rng.randf() * total
	for r in pool:
		value -= maxf(r.weight, 0.0)
		if value <= 0.0:
			return r
	return pool.back()


static func _modifier(source: AffixRoll, quality: float) -> StatModifier:
	var modifier := StatModifier.new()
	modifier.stat = source.stat
	modifier.is_multiplier = source.is_multiplier
	modifier.amount = value_at(source, quality)
	return modifier


## Valore del bonus a una qualita' 0..1 (interi arrotondati, almeno 1). Usato anche per mostrare gli intervalli.
static func value_at(source: AffixRoll, quality: float) -> float:
	var value := lerpf(source.min_value, source.max_value, clampf(quality, 0.0, 1.0))
	return maxf(roundf(value), 1.0) if INTEGER_STATS.has(int(source.stat)) and not source.is_multiplier else snappedf(value, 0.001)
