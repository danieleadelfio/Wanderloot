class_name AbilityEffect
extends Resource
## Cosa fa un'abilita' quando si attiva. Sottoclassi come Resource (dati + comportamento), riusabili tra abilita'.
## host e' il nodo WandAbilities della run, che espone player, proiettili e colpi ad area.


func activate(_host: WandAbilities) -> void:
	pass


## Rimozione dalla bacchetta (sostituzione): annulla effetti persistenti.
func deactivate(_host: WandAbilities) -> void:
	pass


## Vero finche' la ricarica deve restare ferma (es. barriera ancora integra).
func holds_cooldown(_host: WandAbilities) -> bool:
	return false
