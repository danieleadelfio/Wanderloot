class_name ShieldEffect
extends AbilityEffect
## Barriera che annulla il prossimo colpo; la ricarica riparte solo quando si rompe (Barriera arcana).


func activate(host: WandAbilities) -> void:
	host.player.set_shield(true)


func deactivate(host: WandAbilities) -> void:
	host.player.set_shield(false)


func holds_cooldown(host: WandAbilities) -> bool:
	return host.player.has_shield()
