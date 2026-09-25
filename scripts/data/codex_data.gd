class_name CodexData
extends RefCounted
## Contenuto del Codex (M12, #86): manuale consultabile in ogni momento dalla piazza, non l'onboarding
## una tantum di HubTutorial. Logica pura: solo indice di sezioni/voci con chiavi di traduzione, nessuna
## dipendenza da scena o UI. Aggiungere qui una nuova voce quando una nuova meccanica/evento/struttura
## entra nel gioco (vedi anche la regola GDD/CHANGELOG dello stesso commit).

## Ogni voce: {title, body} come chiavi di traduzione. Ogni sezione: {title, entries}.
static func sections() -> Array[Dictionary]:
	return [
		{
			"title": "CODEX_SECTION_STRUCTURES",
			"entries": [
				{"title": "CODEX_FORGE_TITLE", "body": "CODEX_FORGE_BODY"},
				{"title": "CODEX_CHEST_TITLE", "body": "CODEX_CHEST_BODY"},
				{"title": "CODEX_PORTAL_TITLE", "body": "CODEX_PORTAL_BODY"},
			],
		},
		{
			"title": "CODEX_SECTION_EVENTS",
			"entries": [
				{"title": "CODEX_EVENT_LIGHTNING_TITLE", "body": "CODEX_EVENT_LIGHTNING_BODY"},
				{"title": "CODEX_EVENT_PENTAGRAM_TITLE", "body": "CODEX_EVENT_PENTAGRAM_BODY"},
				{"title": "CODEX_EVENT_SHADOWSTEP_TITLE", "body": "CODEX_EVENT_SHADOWSTEP_BODY"},
				{"title": "CODEX_EVENT_CLOSET_TITLE", "body": "CODEX_EVENT_CLOSET_BODY"},
			],
		},
		{
			"title": "CODEX_SECTION_EQUIPMENT",
			"entries": [
				{"title": "CODEX_RARITY_TITLE", "body": "CODEX_RARITY_BODY"},
				{"title": "CODEX_ARENA_LEVEL_TITLE", "body": "CODEX_ARENA_LEVEL_BODY"},
			],
		},
		{
			"title": "CODEX_SECTION_EXTRACTION",
			"entries": [
				{"title": "CODEX_EXTRACTION_TITLE", "body": "CODEX_EXTRACTION_BODY"},
				{"title": "CODEX_OVERTIME_TITLE", "body": "CODEX_OVERTIME_BODY"},
			],
		},
	]
