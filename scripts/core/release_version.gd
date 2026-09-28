class_name ReleaseVersion
extends RefCounted
## Numero di release del gioco (M13, #86): `application/config/version` dei Project Settings, mostrato
## in basso a sinistra (VersionLabel) e alzato di uno a ogni export dal plugin addons/release_version.
## Ogni cifra va da 0 a 9: 1.0.9 -> 1.1.0 (mai 1.0.10), 1.9.9 -> 2.0.0. Logica pura, testata.

const SETTING := "application/config/version"
const DEFAULT := "1.0.0"


static func current() -> String:
	return str(ProjectSettings.get_setting(SETTING, DEFAULT))


static func next(version: String) -> String:
	var parts := version.split(".")
	var major := parts[0].to_int() if parts.size() > 0 else 1
	var minor := parts[1].to_int() if parts.size() > 1 else 0
	var patch := parts[2].to_int() if parts.size() > 2 else 0
	patch += 1
	if patch >= 10:
		patch = 0
		minor += 1
	if minor >= 10:
		minor = 0
		major += 1
	return "%d.%d.%d" % [major, minor, patch]
