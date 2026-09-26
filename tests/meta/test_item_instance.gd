extends GdUnitTestSuite
## Persistenza dell'istanza oggetto: round-trip to_dict()/from_dict(), incluso il tag spazzatura (M12, #86).

var _catalog: EquipmentCatalog
var _abilities: AbilityCatalog
var _wand: EquipmentData


func before_test() -> void:
	_catalog = load("res://data/equipment/equipment_catalog.tres")
	_abilities = load("res://data/abilities/ability_catalog.tres")
	_wand = load("res://data/equipment/gel_wand.tres")


func test_trash_flag_round_trips_through_dict() -> void:
	var item := ItemInstance.new(_wand, 1)
	item.is_trash = true
	var restored := ItemInstance.from_dict(item.to_dict(), _catalog, _abilities)
	assert_bool(restored.is_trash).is_true()


func test_trash_flag_defaults_to_false_when_missing() -> void:
	var item := ItemInstance.new(_wand, 0)
	var data := item.to_dict()
	data.erase("trash")
	var restored := ItemInstance.from_dict(data, _catalog, _abilities)
	assert_bool(restored.is_trash).is_false()
