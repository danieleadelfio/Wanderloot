class_name ArenaSelect
extends PanelContainer
## Scelta dell'arena (portale): arene sbloccate selezionabili, bloccate con la condizione di sblocco.

signal arena_selected(id: StringName)

const RARITIES: RarityTable = ItemText.RARITIES

@onready var _list: VBoxContainer = %ArenaList
@onready var _level_label: Label = %ArenaLevelLabel
@onready var _level_effects_label: Label = %ArenaLevelEffects
@onready var _level_hint: Label = %ArenaLevelHint


## level: livello arena (§6.3b) calcolato dall'equip indossato ora (non cambia scegliendo l'arena).
## Visibilita' del sistema (M12, #86): prima non si vedeva da nessuna parte prima di entrare in run.
func refresh(catalog: ArenaCatalog, extractions: Dictionary, selected: StringName, level: int = 1) -> void:
	_level_label.text = tr("ARENA_LEVEL_CURRENT") % level
	var drop_tier := ArenaLevel.max_drop_tier(level, RARITIES.highest())
	_level_effects_label.text = tr("ARENA_LEVEL_EFFECTS") % [
		ArenaLevel.enemy_hp_multiplier(level), roundi(100.0 * (ArenaLevel.spawn_rate_multiplier(level) - 1.0)),
		ArenaLevel.boss_bonus(level), tr(RARITIES.tier(drop_tier).display_name)]
	_level_hint.visible = not MetaProgression.has_seen_tutorial(&"portal_arena_level")
	# Segnato visto solo quando il pannello e' davvero aperto (non ad ogni refresh in background,
	# es. dopo un crafting): altrimenti sparirebbe prima che il giocatore lo veda mai.
	if _level_hint.visible and is_visible_in_tree():
		MetaProgression.mark_tutorial_seen(&"portal_arena_level")
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var chosen: Button = null
	for arena in catalog.arenas:
		var button := Button.new()
		var unlocked := arena.is_unlocked(extractions)
		if unlocked:
			button.text = "%s%s" % [tr(arena.display_name), tr("ARENA_SELECTED") if arena.id == selected else ""]
			button.tooltip_text = tr(arena.description)
			button.pressed.connect(arena_selected.emit.bind(arena.id))
			# Scelta evidenziata come bottone premuto (M11.3, #67).
			button.toggle_mode = true
			button.button_pressed = arena.id == selected
			if arena.id == selected:
				chosen = button
		else:
			var required := catalog.find(arena.unlock_arena)
			button.text = tr("ARENA_LOCKED") % [
				tr(arena.display_name), int(extractions.get(arena.unlock_arena, 0)), arena.unlock_extractions,
				tr(required.display_name) if required else String(arena.unlock_arena)]
			button.disabled = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 36
		_list.add_child(button)
	# Il refresh ricrea i bottoni: il focus torna sull'arena scelta, non sulla prima della lista.
	if chosen and is_visible_in_tree():
		chosen.grab_focus.call_deferred()
