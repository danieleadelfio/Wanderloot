class_name AbilityTrigger
extends RefCounted
## Conta colpi, distanza e tempo per un'abilita' e dice quante volte attivarla (logica pura, testata).

var ability: WandAbility
var _shots: int = 0
var _distance: float = 0.0
var _elapsed: float = 0.0


func _init(for_ability: WandAbility) -> void:
	ability = for_ability


func on_shot() -> int:
	if ability.trigger != WandAbility.Trigger.SHOTS:
		return 0
	_shots += 1
	if _shots >= ability.every_shots:
		_shots -= ability.every_shots
		return 1
	return 0


func on_moved(distance: float) -> int:
	if ability.trigger != WandAbility.Trigger.DISTANCE:
		return 0
	_distance += distance
	var times := floori(_distance / ability.every_distance)
	_distance -= times * ability.every_distance
	return times


## held = la ricarica e' ferma (l'effetto e' ancora attivo): il tempo non scorre.
## level: livello attuale dell'abilita' (M12, #86, #18), per il cooldown per-livello (es. Barriera arcana).
func tick(delta: float, held: bool = false, level: int = 1) -> int:
	if ability.trigger != WandAbility.Trigger.COOLDOWN or held:
		return 0
	_elapsed += delta
	if _elapsed >= ability.cooldown_for_level(level):
		_elapsed = 0.0
		return 1
	return 0


## Avanzamento verso la prossima attivazione (0..1), per l'HUD.
func progress(level: int = 1) -> float:
	match ability.trigger:
		WandAbility.Trigger.SHOTS:
			return float(_shots) / maxi(ability.every_shots, 1)
		WandAbility.Trigger.DISTANCE:
			return _distance / maxf(ability.every_distance, 1.0)
		WandAbility.Trigger.COOLDOWN:
			return _elapsed / maxf(ability.cooldown_for_level(level), 0.01)
	return 1.0
