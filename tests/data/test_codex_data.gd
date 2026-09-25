extends GdUnitTestSuite
## Indice del Codex (M12, #86): solo struttura logica (sezioni/voci), nessuna dipendenza da scena.

func test_sections_are_not_empty() -> void:
	var sections := CodexData.sections()
	assert_array(sections).is_not_empty()
	for section in sections:
		assert_str(section.title as String).is_not_empty()
		assert_array(section.entries as Array).is_not_empty()
		for entry in section.entries:
			assert_str(entry.title as String).is_not_empty()
			assert_str(entry.body as String).is_not_empty()


func test_sections_cover_expected_topics() -> void:
	var titles: Array = CodexData.sections().map(func(s: Dictionary) -> String: return s.title)
	assert_array(titles).contains(["CODEX_SECTION_STRUCTURES", "CODEX_SECTION_EVENTS", "CODEX_SECTION_EQUIPMENT", "CODEX_SECTION_EXTRACTION"])


func test_events_section_has_all_four_run_events() -> void:
	var events_section: Dictionary = CodexData.sections().filter(func(s: Dictionary) -> bool: return s.title == "CODEX_SECTION_EVENTS")[0]
	var entry_titles: Array = (events_section.entries as Array).map(func(e: Dictionary) -> String: return e.title)
	assert_array(entry_titles).contains(["CODEX_EVENT_LIGHTNING_TITLE", "CODEX_EVENT_PENTAGRAM_TITLE", "CODEX_EVENT_SHADOWSTEP_TITLE", "CODEX_EVENT_CLOSET_TITLE"])
