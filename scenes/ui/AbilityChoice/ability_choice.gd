class_name AbilityChoice
extends CanvasLayer
## Scelta dell'abilita' della bacchetta (M10), a gioco in pausa. Con gli slot pieni chiede cosa sostituire.
## Esito via segnale: index -1 = aggiungi, >= 0 = sostituisci quello slot, ability null = nessun cambio.

signal resolved(ability: WandAbility, replace_index: int)

const BUTTON_SIZE: Vector2 = Vector2(250.0, 150.0)
const BAG_ICON: Texture2D = preload("res://assets/sprites/icon_bag.png")

var _chosen: WandAbility
var _current: Array[WandAbility] = []
var _full: bool = false
var _levels: Dictionary = {}
## Cap sbloccato per abilita' (#16, #20): se gia' al cap, la scelta mostra un Bag of Resources
## al posto della carta (WandAbilities.equip()/level_up() la convertono comunque in materiali).
var _caps: Dictionary = {}

@onready var _title: Label = %Title
@onready var _choices: HBoxContainer = %Choices
@onready var _keep_button: Button = %KeepButton


func _ready() -> void:
	hide()
	_keep_button.pressed.connect(_finish.bind(null, -1))


func present(options: Array[WandAbility], current: Array[WandAbility], full: bool, levels: Dictionary = {}, caps: Dictionary = {}) -> void:
	_current = current
	_full = full
	_levels = levels
	_caps = caps
	_title.text = tr("ABILITY_CHOICE_TITLE")
	_keep_button.visible = false
	_fill(options, _on_option_pressed)
	show()


func _on_option_pressed(ability: WandAbility) -> void:
	if not _full or _levels.has(ability.id):
		_finish(ability, -1)
		return
	_chosen = ability
	_title.text = tr("ABILITY_REPLACE_TITLE") % tr(ability.display_name)
	_keep_button.visible = true
	_fill(_current, _on_replace_pressed)


func _on_replace_pressed(ability: WandAbility) -> void:
	_finish(_chosen, _current.find(ability))


func _finish(ability: WandAbility, index: int) -> void:
	hide()
	resolved.emit(ability, index)


func _fill(abilities: Array[WandAbility], on_pressed: Callable) -> void:
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	for ability in abilities:
		var button := Button.new()
		if _is_capped(ability):
			button.text = "%s\n%s" % [tr("ABILITY_CHOICE_BAG_TITLE") % tr(ability.display_name), tr("ABILITY_CHOICE_BAG_DESC")]
			button.icon = BAG_ICON
		else:
			var name := tr(ability.display_name)
			if _levels.has(ability.id):
				name += "  " + tr("ABILITY_LEVEL_UP") % [_levels[ability.id], _levels[ability.id] + 1]
			button.text = "%s\n%s\n%s" % [name, ability.trigger_text(), tr(ability.description)]
			button.icon = ability.icon
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.expand_icon = false
		button.custom_minimum_size = BUTTON_SIZE
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(on_pressed.bind(ability))
		_choices.add_child(button)
	if _choices.get_child_count() > 0:
		(_choices.get_child(0) as Button).grab_focus()


## true se l'abilita' e' gia' posseduta ed e' gia' al cap sbloccato: la scelta non la fa salire di
## livello, da' un Bag of Resources (WandAbilities.equip()/level_up(), M12 #86 #16/#20).
func _is_capped(ability: WandAbility) -> bool:
	return _levels.has(ability.id) and int(_levels[ability.id]) >= int(_caps.get(ability.id, 1))
