class_name PauseState
extends RefCounted
## Pause richieste dal giocatore (logica pura). Indipendenti da level-up e fine run, che restano
## guidati da RunManager: la composition root mette in pausa se una delle due fonti lo richiede.

enum Mode { NONE, MENU, PAUSED, INVENTORY }
enum Action { MENU, PAUSE, RESUME, INVENTORY }

var mode: Mode = Mode.NONE


## ESC (MENU) apre il menu o chiude qualsiasi pausa aperta; P (PAUSE) alterna la pausa diretta;
## I (INVENTORY) alterna l'inventario di run.
func handle(action: Action) -> Mode:
	match action:
		Action.MENU:
			mode = Mode.MENU if mode == Mode.NONE else Mode.NONE
		Action.PAUSE:
			mode = Mode.NONE if mode == Mode.PAUSED else Mode.PAUSED
		Action.INVENTORY:
			mode = Mode.NONE if mode == Mode.INVENTORY else Mode.INVENTORY
		Action.RESUME:
			mode = Mode.NONE
	return mode


func is_paused() -> bool:
	return mode != Mode.NONE


func reset() -> void:
	mode = Mode.NONE
