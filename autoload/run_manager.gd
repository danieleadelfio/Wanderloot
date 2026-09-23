extends Node
## Stato della run corrente: fase, exp, livello, tempo, uccisioni, loot a rischio. Azzerato a ogni run.
## Non tocca la scena (pausa, UI): la composition root reagisce a state_changed.
## Non scrive mai su MetaProgression: lo fa solo l'estrazione riuscita (da M2).

signal state_changed(state: State)
signal exp_changed(current: int, required: int)
signal leveled_up(level: int)
signal run_ended(result: Result)

enum State { IDLE, RUNNING, LEVEL_UP, ENDED }
enum Result { DEATH, EXTRACTED }

var state: State = State.IDLE
var level: int = 1
## Exp accumulata nel livello corrente (si azzera a ogni level-up, il resto passa oltre).
var experience: int = 0
## Secondi di gioco effettivi (esclusi pausa/level-up).
var elapsed: float = 0.0
var kills: int = 0
## Loot raccolto nella run: si svuota a ogni start_run(), mai scritto su MetaProgression da qui.
var loot: LootRunInventory = LootRunInventory.new()

var _curve: LevelCurve


func _process(delta: float) -> void:
	if state == State.RUNNING:
		elapsed += delta


func start_run(curve: LevelCurve) -> void:
	_curve = curve
	level = 1
	experience = 0
	elapsed = 0.0
	kills = 0
	loot.clear()
	exp_changed.emit(experience, exp_to_next())
	_set_state(State.RUNNING)


func is_running() -> bool:
	return state == State.RUNNING or state == State.LEVEL_UP


func exp_to_next() -> int:
	if _curve == null:
		return 0
	return _curve.exp_to_next(level)


func register_kill(exp_reward: int) -> void:
	if not is_running():
		return
	kills += 1
	add_exp(exp_reward)


func add_exp(amount: int) -> void:
	if amount <= 0 or _curve == null or not is_running():
		return
	experience += amount
	while experience >= exp_to_next():
		experience -= exp_to_next()
		level += 1
		leveled_up.emit(level)
	exp_changed.emit(experience, exp_to_next())


func add_loot(material: MaterialData, amount: int) -> void:
	if not is_running():
		return
	loot.add(material, amount)


func begin_level_up() -> void:
	if state == State.RUNNING:
		_set_state(State.LEVEL_UP)


func end_level_up() -> void:
	if state == State.LEVEL_UP:
		_set_state(State.RUNNING)


func end_run(result: Result) -> void:
	if not is_running():
		return
	_set_state(State.ENDED)
	run_ended.emit(result)


func _set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	state_changed.emit(state)
