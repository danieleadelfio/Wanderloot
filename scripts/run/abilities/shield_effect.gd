class_name ShieldEffect
extends AbilityEffect
## Barriera che annulla i prossimi colpi (uno per livello); la ricarica riparte solo quando si rompe (Barriera arcana).


func activate(host: WandAbilities, level: int = 1) -> void:
	host.player.set_shield(true, level)


func deactivate(host: WandAbilities) -> void:
	host.player.set_shield(false)


func holds_cooldown(host: WandAbilities) -> bool:
	return host.player.has_shield()
