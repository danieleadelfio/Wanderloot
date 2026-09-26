class_name PauseController
extends Node
## Traduce l'input (ESC, P, I) in azioni su PauseState ed emette mode_changed. Gira anche in pausa
## (process_mode ALWAYS nella scena). Non tocca il tree: la pausa la applica la composition root.

signal mode_changed(mode: PauseState.Mode)

## Disattivato dalla composition root quando la run non e' in corso (level-up, fine run).
var enabled: bool = true
var state: PauseState = PauseState.new()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled and not state.is_paused():
		return
	var action := _action_for(event)
	if action < 0:
		return
	get_viewport().set_input_as_handled()
	request(action)


func request(action: PauseState.Action) -> void:
	var before := state.mode
	state.handle(action)
	if state.mode != before:
		mode_changed.emit(state.mode)


func _action_for(event: InputEvent) -> int:
	if event.is_action_pressed("menu"):
		return PauseState.Action.MENU
	if event.is_action_pressed("pause"):
		return PauseState.Action.PAUSE
	if event.is_action_pressed("inventory"):
		return PauseState.Action.INVENTORY
	if event.is_action_pressed("map"):
		return PauseState.Action.MAP
	return -1
