extends CanvasLayer
## Numero di release in basso a sinistra (M13, #86), istanziato nelle scene principali (menu, piazza,
## arena). Solo lettura dei Project Settings: nessuno stato globale.

@onready var _label: Label = %Label


func _ready() -> void:
	_label.text = "v" + ReleaseVersion.current()
