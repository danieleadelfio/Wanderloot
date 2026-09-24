class_name GameSession
extends RefCounted
## Azioni di sessione del menu di pausa, condivise da Arena e Hub: salva, carica, torna al menu, cambia lingua.
## Salvataggi solo manuali (M8): lo stato permanente si scrive su disco solo da qui.


## Salva lo stato permanente. In run il loot non ancora estratto resta a rischio e non viene salvato.
static func save() -> bool:
	return MetaProgression.save_game() == OK


## Ricarica il salvataggio e torna all'hub; una run in corso viene abbandonata. False se non c'e' salvataggio.
static func load_saved(tree: SceneTree) -> bool:
	if not MetaProgression.has_save():
		return false
	RunManager.abort_run()
	MetaProgression.load_game()
	tree.paused = false
	tree.change_scene_to_file.call_deferred(SceneRoutes.HUB)
	return true


## Torna al menu iniziale senza salvare; una run in corso viene abbandonata.
static func quit_to_menu(tree: SceneTree) -> void:
	RunManager.abort_run()
	tree.paused = false
	tree.change_scene_to_file.call_deferred(SceneRoutes.MAIN_MENU)


## Cambio lingua a partita avviata (M9): salva, applica e memorizza la lingua, torna al menu iniziale.
## La posizione nella piazza la imposta prima il chiamante (Hub) o la toglie (Arena).
static func change_language(tree: SceneTree, locale: String) -> void:
	MetaProgression.save_game()
	LocaleSettings.save_locale(locale)
	TranslationServer.set_locale(locale)
	quit_to_menu(tree)
