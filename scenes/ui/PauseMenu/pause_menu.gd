class_name PauseMenu
extends CanvasLayer
## Menu di pausa (ESC) e scritta PAUSA (P). Solo presentazione: le scelte tornano via segnale.

signal action_requested(action: PauseState.Action)

@onready var _menu: Control = %Menu
@onready var _pause_label: Label = %PauseLabel
@onready var _resume_button: Button = %ResumeButton
@onready var _pause_button: Button = %PauseButton


func _ready() -> void:
	show_mode(PauseState.Mode.NONE)
	_resume_button.pressed.connect(action_requested.emit.bind(PauseState.Action.RESUME))
	_pause_button.pressed.connect(action_requested.emit.bind(PauseState.Action.PAUSE))


func show_mode(mode: PauseState.Mode) -> void:
	_menu.visible = mode == PauseState.Mode.MENU
	_pause_label.visible = mode == PauseState.Mode.PAUSED
	if _menu.visible:
		_resume_button.grab_focus()
