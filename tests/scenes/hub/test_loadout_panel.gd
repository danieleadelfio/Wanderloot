extends GdUnitTestSuite
## Baule dell'hub (LoadoutPanel): equipaggiare un oggetto dal baule emette equip_requested, e nell'hub
## reale questo fa scattare, tutto sincrono, MetaProgression.equip -> _mark_changed -> changed.emit ->
## Hub._refresh -> refresh() di *questo* pannello - nello stesso momento in cui il tile cliccato sta
## ancora emettendo il proprio segnale nativo "pressed".
##
## Bug (M13, #86): refresh() liberava subito i vecchi tile del baule con child.free() (non queue_free())
## dopo il remove_child(), incluso il tile che stava ancora emettendo "pressed" -> Godot rifiuta con
## "Attempted to free a locked object (calling or emitting)". Riproducibile con QUALUNQUE oggetto nel
## baule (equipaggiato dall'evento Scheletri nell'armadio o trovato normalmente in run): una volta
## depositato, un oggetto e' un'istanza uguale alle altre (MetaProgression.deposit_run_items), non c'e'
## alcuna differenza di percorso nella UI dell'hub in base a come e' stato ottenuto.


func _base(id: StringName, slot: EquipmentData.Slot) -> EquipmentData:
	var data := EquipmentData.new()
	data.id = id
	data.slot = slot
	return data


func _panel() -> LoadoutPanel:
	var panel: LoadoutPanel = auto_free(load("res://scenes/hub/LoadoutPanel/LoadoutPanel.tscn").instantiate())
	add_child(panel)
	return panel


func _stash_tile(panel: LoadoutPanel, uid: int) -> ItemTile:
	for child in panel._grid.get_children():
		if child is ItemTile and child.item and child.item.uid == uid:
			return child
	return null


## Riproduce la catena reale in modo sincrono, esattamente come la collega Hub._ready() (equip_requested
## -> MetaProgression.equip -> _mark_changed -> changed.emit -> Hub._refresh -> LoadoutPanel.refresh).
func _wire_synchronous_equip(panel: LoadoutPanel, loadout: EquipmentLoadout) -> void:
	panel.equip_requested.connect(func(uid: int) -> void:
		loadout.equip(uid)
		panel.refresh(loadout)
	)


## Pezzo scelto dall'armadio degli Scheletri: dopo un'estrazione riuscita entra nel baule con
## MetaProgression.deposit_run_items() (loadout.add()), come qualunque altro oggetto.
func test_equipping_an_item_from_the_skeletons_closet_does_not_free_a_locked_button() -> void:
	var loadout := EquipmentLoadout.new()
	var item := ItemInstance.new(_base(&"closet_head", EquipmentData.Slot.HEAD))
	loadout.add(item)
	var panel := _panel()
	_wire_synchronous_equip(panel, loadout)
	panel.refresh(loadout)
	var tile := _stash_tile(panel, item.uid)
	assert_object(tile).is_not_null()
	await assert_error(func() -> void: tile.pressed.emit()).is_success()
	assert_bool(loadout.is_equipped(item.uid)).is_true()


## Stesso identico percorso UI per un oggetto trovato normalmente in run (drop di un nemico): nessuna
## differenza di codice tra le due origini una volta nel baule, quindi lo stesso bug (e la stessa fix)
## vale per entrambe.
func test_equipping_a_normally_dropped_item_does_not_free_a_locked_button() -> void:
	var loadout := EquipmentLoadout.new()
	var item := ItemInstance.new(_base(&"dropped_armor", EquipmentData.Slot.ARMOR))
	loadout.add(item)
	var panel := _panel()
	_wire_synchronous_equip(panel, loadout)
	panel.refresh(loadout)
	var tile := _stash_tile(panel, item.uid)
	assert_object(tile).is_not_null()
	await assert_error(func() -> void: tile.pressed.emit()).is_success()
	assert_bool(loadout.is_equipped(item.uid)).is_true()


## Stesso schema per il manichino (slot equipaggiati): unequip -> refresh nello stesso frame, sul
## bottone che sta ancora emettendo "pressed" (M13, #86, stesso bug, altro loop di refresh()).
func test_unequipping_from_the_mannequin_does_not_free_a_locked_button() -> void:
	var loadout := EquipmentLoadout.new()
	var item := ItemInstance.new(_base(&"worn_weapon", EquipmentData.Slot.WEAPON))
	loadout.add(item)
	loadout.equip(item.uid)
	var panel := _panel()
	panel.unequip_requested.connect(func(slot: int) -> void:
		loadout.unequip(slot)
		panel.refresh(loadout)
	)
	panel.refresh(loadout)
	var slot_button: ItemTile = null
	for child in panel._slots.get_children():
		if child is ItemTile and child.item and child.item.uid == item.uid:
			slot_button = child
			break
	assert_object(slot_button).is_not_null()
	await assert_error(func() -> void: slot_button.pressed.emit()).is_success()
	assert_bool(loadout.is_equipped(item.uid)).is_false()
