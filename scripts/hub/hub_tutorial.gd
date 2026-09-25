class_name HubTutorial
extends CanvasLayer
## Tutorial guidato della piazza alla prima nuova partita (M12, #86): la camera si stacca dal player e
## si sposta su ogni punto di interazione con una breve descrizione, poi torna al player. Skippabile in
## ogni momento (bottone sempre visibile). Chi chiama segna tutorials_seen su MetaProgression alla fine
## o allo skip: qui c'e' solo la sequenza, nessuna persistenza.

signal finished

@onready var _title: Label = %Title
@onready var _body: Label = %Body
@onready var _next_button: Button = %NextButton
@onready var _skip_button: Button = %SkipButton

var _camera: Camera2D
var _player: Node2D
var _steps: Array[Dictionary] = []
var _step_index: int = -1
var _tween: Tween


func _ready() -> void:
	hide()
	_skip_button.text = tr("TUTORIAL_SKIP")
	_next_button.pressed.connect(_advance)
	_skip_button.pressed.connect(_finish)


## steps: array di {title: String, body: String, position: Vector2}. L'ultimo elemento e' tipicamente
## la posizione del player stesso, cosi' l'ultimo "Avanti" (diventato "Ho capito") lo riporta li'.
func start(camera: Camera2D, player: Node2D, steps: Array[Dictionary]) -> void:
	_camera = camera
	_player = player
	_steps = steps
	_step_index = -1
	player.set_physics_process(false)
	camera.position_smoothing_enabled = false
	show()
	_advance()


func _advance() -> void:
	_step_index += 1
	if _step_index >= _steps.size():
		_finish()
		return
	var step: Dictionary = _steps[_step_index]
	_title.text = step.get("title", "")
	_body.text = step.get("body", "")
	_next_button.text = tr("TUTORIAL_GOT_IT") if _step_index == _steps.size() - 1 else tr("TUTORIAL_NEXT")
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_camera, "global_position", step.get("position", _camera.global_position) as Vector2, 0.6)


func _finish() -> void:
	if _tween:
		_tween.kill()
	if is_instance_valid(_camera) and is_instance_valid(_player):
		_camera.position_smoothing_enabled = true
		_camera.global_position = _player.global_position
		_player.set_physics_process(true)
	hide()
	finished.emit()
