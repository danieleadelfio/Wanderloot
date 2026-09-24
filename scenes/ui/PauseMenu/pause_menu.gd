class_name PauseMenu
extends CanvasLayer
## Menu di pausa (ESC) e scritta PAUSA (P). Solo presentazione: le scelte tornano via segnale,
## salvataggio e caricamento li esegue la composition root (Arena, Hub) tramite GameSession.

signal action_requested(action: PauseState.Action)
signal save_requested
signal load_requested
signal menu_requested

## Con modifiche non salvate "Torna al menu" chiede una seconda pressione.
var _unsaved_changes: bool = false
var _menu_armed: bool = false

@onready var _menu: Control = %Menu
@onready var _pause_label: Label = %PauseLabel
@onready var _resume_button: Button = %ResumeButton
@onready var _save_button: Button = %SaveButton
@onready var _load_button: Button = %LoadButton
@onready var _menu_button: Button = %MenuButton
@onready var _status_label: Label = %StatusLabel
@onready var _hint: Label = %Hint


func _ready() -> void:
	show_mode(PauseState.Mode.NONE)
	_resume_button.pressed.connect(action_requested.emit.bind(PauseState.Action.RESUME))
	_save_button.pressed.connect(save_requested.emit)
	_load_button.pressed.connect(load_requested.emit)
	_menu_button.pressed.connect(_on_menu_pressed)


func show_mode(mode: PauseState.Mode) -> void:
	_menu.visible = mode == PauseState.Mode.MENU
	_pause_label.visible = mode == PauseState.Mode.PAUSED
	_status_label.text = ""
	_menu_armed = false
	if _menu.visible:
		_resume_button.grab_focus()


## Carica e' disattivato se non esiste un salvataggio.
func set_can_load(can_load: bool) -> void:
	_load_button.disabled = not can_load


func show_status(text: String) -> void:
	_status_label.text = text


## Testo d'aiuto sotto i bottoni (nell'hub P non e' la pausa diretta).
func set_hint(text: String) -> void:
	_hint.text = text


func set_unsaved_changes(unsaved: bool) -> void:
	_unsaved_changes = unsaved
	_menu_armed = false


func _on_menu_pressed() -> void:
	if _unsaved_changes and not _menu_armed:
		_menu_armed = true
		show_status("Modifiche non salvate: premi di nuovo per uscire")
		return
	menu_requested.emit()
