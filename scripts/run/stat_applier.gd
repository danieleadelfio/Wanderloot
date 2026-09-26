class_name StatApplier
extends RefCounted
## Applica modificatori di statistica (upgrade di run ed equipaggiamento) alle copie di run di
## PlayerStats e WeaponData. Logica pura: chi chiama passa sempre copie duplicate(), mai i .tres condivisi.


static func apply(stat: UpgradeData.Stat, amount: float, is_multiplier: bool, stats: PlayerStats, weapon: WeaponData) -> void:
	match stat:
		UpgradeData.Stat.DAMAGE:
			weapon.damage = roundi(_modify(weapon.damage, amount, is_multiplier))
		UpgradeData.Stat.FIRE_RATE:
			weapon.fire_rate = _modify(weapon.fire_rate, amount, is_multiplier)
		UpgradeData.Stat.PROJECTILE_SPEED:
			weapon.projectile_speed = _modify(weapon.projectile_speed, amount, is_multiplier)
		UpgradeData.Stat.MOVE_SPEED:
			stats.move_speed = _modify(stats.move_speed, amount, is_multiplier)
		UpgradeData.Stat.MAX_HP:
			stats.max_hp = maxi(roundi(_modify(stats.max_hp, amount, is_multiplier)), 1)
		UpgradeData.Stat.PROJECTILE_LIFETIME:
			weapon.projectile_lifetime = _modify(weapon.projectile_lifetime, amount, is_multiplier)
		UpgradeData.Stat.PICKUP_RADIUS:
			stats.pickup_radius = _modify(stats.pickup_radius, amount, is_multiplier)
		UpgradeData.Stat.EXP_GAIN:
			stats.exp_multiplier = _modify(stats.exp_multiplier, amount, is_multiplier)
		UpgradeData.Stat.DROP_CHANCE:
			stats.drop_chance_multiplier = _modify(stats.drop_chance_multiplier, amount, is_multiplier)
		UpgradeData.Stat.INVULNERABILITY:
			stats.invulnerability_time = maxf(_modify(stats.invulnerability_time, amount, is_multiplier), 0.0)
		UpgradeData.Stat.KNOCKBACK:
			weapon.knockback = _modify(weapon.knockback, amount, is_multiplier)
		UpgradeData.Stat.PROJECTILE_COUNT:
			weapon.projectile_count = maxi(roundi(_modify(weapon.projectile_count, amount, is_multiplier)), 1)
		UpgradeData.Stat.COUNT_BONUS:
			# Solo le abilita' (Anello arcano, Fulmine errante, ...): non tocca lo sparo base ne' il
			# Ventaglio (M12, #86: prima si sommava anche li', rendendo Contatore + Ventaglio troppo forte).
			stats.count_bonus += roundi(amount)
		UpgradeData.Stat.PIERCE:
			weapon.pierce = maxi(roundi(_modify(weapon.pierce, amount, is_multiplier)), 0)


## Modificatori dell'equipaggiamento indossato (oggetto base + bonus tirati), applicati a inizio run.
static func apply_modifiers(modifiers: Array[StatModifier], stats: PlayerStats, weapon: WeaponData) -> void:
	for modifier in modifiers:
		apply(modifier.stat, modifier.amount, modifier.is_multiplier, stats, weapon)


static func _modify(value: float, amount: float, is_multiplier: bool) -> float:
	return value * amount if is_multiplier else value + amount
