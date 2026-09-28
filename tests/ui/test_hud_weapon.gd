extends GdUnitTestSuite
## Slot arma dell'HUD (M13, #86): quale arma mostrare (logica pura) e come la mostra (icona, bordo della
## rarita', tooltip), bacchetta base se non e' equipaggiata nessuna arma.


func _item(path: String, tier: int = 2) -> ItemInstance:
	return ItemInstance.new(load(path), tier)


func _hud() -> Hud:
	var hud: Hud = auto_free(load("res://scenes/ui/HUD/HUD.tscn").instantiate())
	add_child(hud)
	return hud


func test_no_weapon_shows_nothing() -> void:
	assert_object(Hud.weapon_to_show(null, [] as Array[ItemInstance])).is_null()


func test_equipped_weapon_is_shown() -> void:
	var wand := _item("res://data/equipment/gel_wand.tres")
	assert_object(Hud.weapon_to_show(wand, [] as Array[ItemInstance])).is_same(wand)


## Armadio degli Scheletri: l'arma scelta in run si indossa subito e prevale su quella del baule.
func test_closet_weapon_overrides_the_equipped_one() -> void:
	var wand := _item("res://data/equipment/gel_wand.tres")
	var closet := _item("res://data/equipment/bone_wand.tres", 3)
	var run_items: Array[ItemInstance] = [closet]
	assert_object(Hud.weapon_to_show(wand, run_items)).is_same(closet)
	assert_object(Hud.weapon_to_show(null, run_items)).is_same(closet)


func test_closet_pieces_that_are_not_weapons_are_ignored() -> void:
	var wand := _item("res://data/equipment/gel_wand.tres")
	var run_items: Array[ItemInstance] = [_item("res://data/equipment/gel_ring.tres"), _item("res://data/equipment/bone_armor.tres")]
	assert_object(Hud.weapon_to_show(wand, run_items)).is_same(wand)


func test_last_closet_weapon_wins() -> void:
	var first := _item("res://data/equipment/rapid_wand.tres")
	var last := _item("res://data/equipment/bone_wand.tres")
	var run_items: Array[ItemInstance] = [first, _item("res://data/equipment/gel_ring.tres"), last]
	assert_object(Hud.weapon_to_show(null, run_items)).is_same(last)


func test_slot_shows_icon_rarity_border_and_tooltip() -> void:
	var hud := _hud()
	var wand := _item("res://data/equipment/gel_wand.tres", 4)
	hud.set_weapon(wand)
	var slot: PanelContainer = hud.get_node("%WeaponSlot")
	assert_object((hud.get_node("%WeaponIcon") as TextureRect).texture).is_same(wand.base.icon)
	assert_object((slot.get_theme_stylebox(&"panel") as StyleBoxTexture).modulate_color).is_equal(ItemText.color(wand))
	assert_str(slot.tooltip_text).is_equal(ItemText.tooltip(wand))


func test_closet_weapon_tooltip_says_it_is_for_this_run_only() -> void:
	var hud := _hud()
	var wand := _item("res://data/equipment/bone_wand.tres", 3)
	hud.set_weapon(wand, true)
	assert_str((hud.get_node("%WeaponSlot") as Control).tooltip_text).ends_with(tr("RUNINV_TEMP_EQUIP"))


func test_no_weapon_shows_the_basic_wand() -> void:
	var hud := _hud()
	hud.set_weapon(_item("res://data/equipment/gel_wand.tres"))
	hud.set_weapon(null)
	var slot: PanelContainer = hud.get_node("%WeaponSlot")
	assert_object((hud.get_node("%WeaponIcon") as TextureRect).texture).is_same(Hud.BASE_WEAPON_ICON)
	assert_object((slot.get_theme_stylebox(&"panel") as StyleBoxTexture).modulate_color).is_equal(Hud.BASE_WEAPON_BORDER)
	assert_str(slot.tooltip_text).is_equal(tr("HUD_WEAPON_BASE"))
