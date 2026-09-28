@tool
extends EditorExportPlugin
## A inizio export alza application/config/version (1.0.6 -> 1.0.7) e salva project.godot: il
## project.binary dell'eseguibile viene scritto dopo _export_begin, quindi la build esportata mostra
## gia' il numero nuovo. "Esporta tutto" (piu' preset di fila) alza una volta sola: entro
## SAME_EXPORT_SECONDS dall'ultimo aumento i preset successivi riusano lo stesso numero.

const SAME_EXPORT_SECONDS := 120.0

static var _last_bump_msec: int = -1


func _get_name() -> String:
	return "ReleaseVersion"


func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	var now := Time.get_ticks_msec()
	if _last_bump_msec >= 0 and now - _last_bump_msec < SAME_EXPORT_SECONDS * 1000.0:
		return
	_last_bump_msec = now
	var version := ReleaseVersion.next(ReleaseVersion.current())
	ProjectSettings.set_setting(ReleaseVersion.SETTING, version)
	ProjectSettings.save()
	print("Release: ", version)
