class_name SfxPlayer
extends Node
## Pool di AudioStreamPlayer sul bus SFX. play(id) ignora id sconosciuti o senza stream: un file
## mancante toglie il suono, non rompe il gioco. Funziona anche in pausa (process_mode ALWAYS nella scena).

@export var bank: SoundBank
@export var voices: int = 12
@export var bus: StringName = &"SFX"
## Intervallo minimo tra due riproduzioni dello stesso suono (molti nemici colpiti insieme).
@export var min_interval: float = 0.03

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _last_played_msec: Dictionary[StringName, int] = {}


func _ready() -> void:
	for i in voices:
		var player := AudioStreamPlayer.new()
		player.bus = bus
		add_child(player)
		_players.append(player)


func play(id: StringName) -> void:
	var entry := bank.find(id) if bank != null else null
	if entry == null or entry.stream == null or _players.is_empty():
		return
	var now := Time.get_ticks_msec()
	if now - _last_played_msec.get(id, -100000) < int(min_interval * 1000.0):
		return
	_last_played_msec[id] = now
	var player := _pick_player()
	player.stream = entry.stream
	player.volume_db = entry.volume_db
	player.pitch_scale = 1.0 + randf_range(-entry.pitch_variance, entry.pitch_variance)
	player.play()


func _pick_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	# Tutte le voci occupate: si ruba la piu' vecchia.
	var stolen := _players[_next]
	_next = (_next + 1) % _players.size()
	return stolen
