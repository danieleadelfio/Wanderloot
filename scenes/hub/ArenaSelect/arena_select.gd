class_name ArenaSelect
extends PanelContainer
## Scelta dell'arena (portale): arene sbloccate selezionabili, bloccate con la condizione di sblocco.

signal arena_selected(id: StringName)

@onready var _list: VBoxContainer = %ArenaList


func refresh(catalog: ArenaCatalog, extractions: Dictionary, selected: StringName) -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	for arena in catalog.arenas:
		var button := Button.new()
		var unlocked := arena.is_unlocked(extractions)
		if unlocked:
			button.text = "%s%s" % [arena.display_name, "  —  scelta" if arena.id == selected else ""]
			button.tooltip_text = arena.description
			button.pressed.connect(arena_selected.emit.bind(arena.id))
		else:
			var required := catalog.find(arena.unlock_arena)
			button.text = "%s  —  bloccata: %d/%d estrazioni in %s" % [
				arena.display_name, int(extractions.get(arena.unlock_arena, 0)), arena.unlock_extractions,
				required.display_name if required else String(arena.unlock_arena)]
			button.disabled = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 36
		_list.add_child(button)
