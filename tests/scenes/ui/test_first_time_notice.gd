extends GdUnitTestSuite
## Spiegazione a schermo intero alla prima volta in assoluto (M12, #86): qui solo mostra/nascondi e
## il segnale di conferma, non la pausa (decisa da Arena, che non si instanzia nei test).

var _notice: FirstTimeNotice


func before_test() -> void:
	_notice = auto_free((load("res://scenes/ui/FirstTimeNotice/FirstTimeNotice.tscn") as PackedScene).instantiate())
	add_child(_notice)


func test_hidden_until_shown() -> void:
	assert_bool(_notice.visible).is_false()


func test_show_notice_sets_text_and_becomes_visible() -> void:
	_notice.show_notice("Titolo", "Corpo")
	assert_bool(_notice.visible).is_true()
	assert_str((_notice.get_node("%Title") as Label).text).is_equal("Titolo")
	assert_str((_notice.get_node("%Body") as Label).text).is_equal("Corpo")


func test_continue_button_hides_and_emits_dismissed() -> void:
	_notice.show_notice("Titolo", "Corpo")
	var emitted := [false]
	_notice.dismissed.connect(func() -> void: emitted[0] = true)
	(_notice.get_node("%ContinueButton") as Button).pressed.emit()
	assert_bool(_notice.visible).is_false()
	assert_bool(emitted[0]).is_true()
