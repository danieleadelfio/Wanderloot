extends Node
## Stato della run corrente (exp, livello). Azzerato a ogni run.
## Non scrive mai su MetaProgression: lo fa solo l'estrazione riuscita.

signal exp_changed(current: int, required: int)
signal leveled_up(level: int)

var level: int = 1
## Exp accumulata nel livello corrente (si azzera a ogni level-up, il resto passa oltre).
var experience: int = 0

var _curve: LevelCurve


func start_run(curve: LevelCurve) -> void:
	_curve = curve
	level = 1
	experience = 0
	exp_changed.emit(experience, exp_to_next())


func exp_to_next() -> int:
	if _curve == null:
		return 0
	return _curve.exp_to_next(level)


func add_exp(amount: int) -> void:
	if amount <= 0 or _curve == null:
		return
	experience += amount
	while experience >= exp_to_next():
		experience -= exp_to_next()
		level += 1
		leveled_up.emit(level)
	exp_changed.emit(experience, exp_to_next())
