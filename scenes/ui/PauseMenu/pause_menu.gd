class_name PauseMenu
extends CanvasLayer
## Menu di pausa (ESC) e scritta PAUSA (P). Solo presentazione: le scelte tornano via segnale,
## salvataggio e caricamento li esegue la composition root (Arena, Hub) tramite GameSession.

signal action_requested(action: PauseState.Action)
signal save_requested
signal load_requested

@onready var _menu: Control = %Menu
@onready var _pause_label: Label = %PauseLabel
@onready var _resume_button: Button = %ResumeButton
@onready var _save_button: Button = %SaveButton
@onready var _load_button: Button = %LoadButton
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	show_mode(PauseState.Mode.NONE)
	_resume_button.pressed.connect(action_requested.emit.bind(PauseState.Action.RESUME))
	_save_button.pressed.connect(save_requested.emit)
	_load_button.pressed.connect(load_requested.emit)


func show_mode(mode: PauseState.Mode) -> void:
	_menu.visible = mode == PauseState.Mode.MENU
	_pause_label.visible = mode == PauseState.Mode.PAUSED
	_status_label.text = ""
	if _menu.visible:
		_resume_button.grab_focus()


## Carica e' disattivato se non esiste un salvataggio.
func set_can_load(can_load: bool) -> void:
	_load_button.disabled = not can_load


func show_status(text: String) -> void:
	_status_label.text = text
