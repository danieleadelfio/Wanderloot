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


static func apply_equipment(items: Array[EquipmentData], stats: PlayerStats, weapon: WeaponData) -> void:
	for item in items:
		for modifier in item.modifiers:
			apply(modifier.stat, modifier.amount, modifier.is_multiplier, stats, weapon)


static func _modify(value: float, amount: float, is_multiplier: bool) -> float:
	return value * amount if is_multiplier else value + amount
