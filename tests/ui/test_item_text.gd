extends GdUnitTestSuite
## Testi e pannelli di ItemText (inventario, fabbro, confronto equipaggiato/non equipaggiato).


func _item(path: String, tier: int = 2) -> ItemInstance:
	return ItemInstance.new(load(path), tier)


## Bug (M13, #86): nel confronto il pezzo equipaggiato aveva la scritta "Equipaggiato" sopra, quella
## del pezzo non equipaggiato no, quindi i due VBoxContainer avevano altezze diverse e le righe sotto
## (nome, rarita', bonus) non erano piu' allineate. Ora tooltip_panel riserva sempre la riga
## dell'intestazione, vuota se non c'e' un header, cosi' i due pannelli hanno la stessa altezza.
func test_compare_panel_keeps_equipped_and_unequipped_panels_aligned() -> void:
	var equipped := _item("res://data/equipment/gel_wand.tres")
	var candidate := _item("res://data/equipment/bone_wand.tres", 3)
	var row: HBoxContainer = ItemText.compare_panel(candidate, [equipped]) as HBoxContainer
	auto_free(row)
	var equipped_panel: VBoxContainer = row.get_child(0) as VBoxContainer
	var candidate_panel: VBoxContainer = row.get_child(row.get_child_count() - 1) as VBoxContainer
	assert_int(equipped_panel.get_child_count()).is_equal(candidate_panel.get_child_count())
	var equipped_header := equipped_panel.get_child(0) as Label
	var candidate_header := candidate_panel.get_child(0) as Label
	assert_str(equipped_header.text).is_equal(tr("TOOLTIP_EQUIPPED"))
	assert_str(candidate_header.text).is_equal("")
	# Stesso font e size sulla riga di intestazione: stessa altezza anche se uno dei due testi e' vuoto.
	assert_int(equipped_header.get_theme_font_size(&"font_size")).is_equal(candidate_header.get_theme_font_size(&"font_size"))
