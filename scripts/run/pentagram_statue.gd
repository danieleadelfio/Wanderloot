class_name PentagramStatue
extends Area2D
## Statua del demone al centro del Pentagramma di sangue (M13, #86): ferma nel mondo dall'inizio
## della run, visibile anche in mappa/minimappa. Il player le si avvicina e preme "interact" (E):
## sparisce e segnala l'attivazione a RunEventDirector, che accende le candele.
## Input a polling (Input.is_action_just_pressed), non _unhandled_input: cosi' risponde anche a
## Input.action_press("interact") del bot di playtest (stesso schema di Player.try_dash con "dash").

signal interacted

## Raggio della zona di interazione (deve combaciare con la CollisionShape2D della scena).
const INTERACT_RADIUS: float = 70.0

var consumed: bool = false
var _player_in_range: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_changed.bind(true))
	body_exited.connect(_on_body_changed.bind(false))


func _process(_delta: float) -> void:
	if consumed or not _player_in_range:
		return
	if Input.is_action_just_pressed("interact"):
		consume()
		interacted.emit()


## Posiziona/riabilita la statua a inizio run.
func place(at: Vector2) -> void:
	global_position = at
	consumed = false
	_player_in_range = false
	show()
	set_deferred("monitoring", true)
	reset_physics_interpolation()


## Sparisce e smette di rispondere all'interazione (attivazione dell'evento).
func consume() -> void:
	consumed = true
	hide()
	set_deferred("monitoring", false)


func _on_body_changed(_body: Node2D, entered: bool) -> void:
	_player_in_range = entered
