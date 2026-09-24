class_name OvertimeState
extends RefCounted
## Tempi e livelli dell'overtime (logica pura, testata). Parte con start() all'apertura dell'estrazione;
## tick() emette avvisi, cambi di livello e i boss da far comparire. La composition root applica gli effetti.

signal warned(seconds: int, next_level: int)
signal level_changed(level: int)
## count = bosses_per_wave: tanti boss quanti ne compaiono all'estrazione (M11.2).
signal boss_due(count: int)

var data: OvertimeData
## Boss per ondata: li imposta la composition root (boss dell'arena + guadagnati con gli eventi). Non si azzera con start().
var bosses_per_wave: int = 1
var level: int = 0
var elapsed: float = 0.0
var _running: bool = false
var _warned: Dictionary[String, bool] = {}
var _boss_left: float = 0.0


func start(overtime: OvertimeData) -> void:
	data = overtime
	level = 0
	elapsed = 0.0
	_warned.clear()
	_running = data != null


func stop() -> void:
	_running = false


func is_running() -> bool:
	return _running


func time_to_next_level() -> float:
	return data.start_after + level * data.level_every - elapsed


func tick(delta: float) -> void:
	if not _running:
		return
	elapsed += delta
	var left := time_to_next_level()
	for seconds in data.warnings:
		var key := "%d/%d" % [level + 1, roundi(seconds)]
		if left <= seconds and left > 0.0 and not _warned.has(key):
			_warned[key] = true
			warned.emit(roundi(seconds), level + 1)
	if left <= 0.0:
		level += 1
		_boss_left = 0.0
		level_changed.emit(level)
	if level > 0:
		_boss_left -= delta
		if _boss_left <= 0.0:
			_boss_left += boss_interval()
			boss_due.emit(bosses_per_wave)


func speed_multiplier() -> float:
	return data.speed_multiplier * level if level > 0 else 1.0


func hp_multiplier() -> float:
	return 1.0 + data.hp_bonus * level


func boss_interval() -> float:
	return maxf(data.min_boss_interval, data.boss_interval / maxi(level, 1))
