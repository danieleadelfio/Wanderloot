class_name ClosetReward
extends CanvasLayer
## Ricompensa dell'evento Scheletri nell'armadio (M12, #86): fino a closet_choices pezzi mai
## estratti prima, presentati come l'interno di un armadio (ante ai lati). La scelta si equipaggia
## subito per il resto della run; chi chiama (Arena) aggiunge il pezzo al loot a rischio e ne applica
## i modificatori al player. Sola presentazione: la scelta esce via segnale.

signal item_chosen(item: ItemInstance)

@onready var _window: Control = %Window
@onready var _mannequin: LoadoutPanel = %Mannequin
@onready var _choices: HBoxContainer = %Choices
@onready var _empty: Label = %ChoicesEmpty


func _ready() -> void:
	_window.hide()


func close() -> void:
	_window.hide()


## candidates: istanze gia' tirate (MetaProgression.make_item), una per pezzo mai estratto proposto.
func present(loadout: EquipmentLoadout, candidates: Array[ItemInstance]) -> void:
	_mannequin.refresh(loadout)
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	for item in candidates:
		var tile := ItemTile.for_item(item)
		tile.pressed.connect(_on_chosen.bind(item))
		_choices.add_child(tile)
	_empty.visible = candidates.is_empty()
	_window.show()


func _on_chosen(item: ItemInstance) -> void:
	close()
	item_chosen.emit(item)
