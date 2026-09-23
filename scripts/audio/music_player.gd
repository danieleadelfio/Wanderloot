class_name MusicPlayer
extends AudioStreamPlayer
## Musica di scena sul bus Music. Il loop e' impostato all'import del WAV; finished -> play() e' la riserva.


func _ready() -> void:
	bus = &"Music"
	finished.connect(play)
	if stream != null:
		play()
