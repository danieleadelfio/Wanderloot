class_name SoundEntry
extends Resource
## Un effetto sonoro della SoundBank: id logico + stream + mix.

@export var id: StringName = &""
@export var stream: AudioStream
@export var volume_db: float = 0.0
## Variazione casuale del pitch (+-), evita la ripetitivita' dei suoni frequenti.
@export_range(0.0, 0.5, 0.01) var pitch_variance: float = 0.0
