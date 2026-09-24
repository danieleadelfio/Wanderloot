class_name RunEventState
extends RefCounted
## Stato di un evento in corso (logica pura, testata): dura `duration` secondi, fallisce al primo colpo subito.

enum Status { IDLE, RUNNING, COMPLETED, FAILED }

var status: Status = Status.IDLE
var duration: float = 0.0
var elapsed: float = 0.0


func start(event_duration: float) -> void:
	duration = event_duration
	elapsed = 0.0
	status = Status.RUNNING


func tick(delta: float) -> Status:
	if status == Status.RUNNING:
		elapsed += delta
		if elapsed >= duration:
			status = Status.COMPLETED
	return status


func fail() -> void:
	if status == Status.RUNNING:
		status = Status.FAILED


func remaining_ratio() -> float:
	return clampf(1.0 - elapsed / maxf(duration, 0.001), 0.0, 1.0)


## Prossimo evento: il primo tempo in `times` non ancora superato da elapsed_run (-1 se finiti).
static func next_time(times: PackedFloat32Array, fired: int) -> float:
	return times[fired] if fired < times.size() else -1.0
