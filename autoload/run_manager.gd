extends Node
## Stato della run corrente (exp, in futuro livello/timer estrazione).
## Azzerato a ogni run. Non scrive mai su MetaProgression: lo fa solo l'estrazione riuscita.

signal exp_changed(total: int)

var experience: int = 0


func reset() -> void:
	experience = 0
	exp_changed.emit(experience)


func add_exp(amount: int) -> void:
	if amount <= 0:
		return
	experience += amount
	exp_changed.emit(experience)
