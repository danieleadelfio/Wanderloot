extends GdUnitTestSuite
## Guardia per #85: una classe Resource con un Packed*Array esportato deve essere @tool,
## altrimenti all'export quel valore puo' sparire solo nella build (l'editor converte il .tres
## da un'istanza segnaposto).

const ROOTS: Array[String] = ["res://scripts", "res://scenes", "res://autoload"]


func test_resources_with_packed_arrays_are_tool() -> void:
	var offenders: Array[String] = []
	for path in _scripts():
		var source := FileAccess.get_file_as_string(path)
		var is_resource := source.contains("\nextends Resource") or source.begins_with("extends Resource")
		var has_packed := RegEx.create_from_string("@export[^\\n]*:\\s*Packed\\w*Array").search(source) != null
		if is_resource and has_packed and not source.begins_with("@tool"):
			offenders.append(path)
	assert_array(offenders).is_empty()


func _scripts() -> Array[String]:
	var found: Array[String] = []
	var pending: Array[String] = ROOTS.duplicate()
	while not pending.is_empty():
		var dir: String = pending.pop_back()
		for sub in DirAccess.get_directories_at(dir):
			pending.append(dir.path_join(sub))
		for file in DirAccess.get_files_at(dir):
			if file.ends_with(".gd"):
				found.append(dir.path_join(file))
	return found
