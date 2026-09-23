# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/it/1.1.0/). Ogni voce va aggiunta sotto "Unreleased" al momento della modifica, non a posteriori.

## [Unreleased]

### Added
- Modello dati del loot: `MaterialData`, `DropEntry` e drop table in `EnemyData`; materiali Gelatina e Nucleo di slime (#6).
- Flusso di fine run: `RunManager` a stati (RUNNING/LEVEL_UP/ENDED) con esito morte/estrazione, pausa guidata dallo stato, schermata di fine run con riepilogo e “Nuova run” (#5). M1 completato.
- Punto di estrazione: appare dopo 60s, 5s di canale nella zona, progresso che cala fuori dalla zona; HUD con countdown e percentuale. `SpawnUtils` condiviso con il wave spawner (#4).
- Scelta di 3 upgrade al level-up: `UpgradeData`/`UpgradeTable` (estrazione pesata), overlay `LevelUpChoice` in pausa, upgrade applicati a copie di run delle stats (#3).
- Livelli di run: `LevelCurve` data-driven, `RunManager.start_run()` / segnale `leveled_up`, HUD con livello e barra EXP (#2).
- Enemy pool + wave spawner data-driven (`WaveData`), sostituisce il nemico singolo con respawn di M0 (#1).
- M0 skeleton tecnico: arena 1600x1000 con muri e camera, player twin-stick (movimento 8 dir, mira mouse/stick destro), arma con fire-rate da `WeaponData`, proiettili con object pool, nemico base che insegue e rinasce, danno da contatto con i-frames, hit-flash, HUD HP/EXP.
- Componenti riusabili `Health`, `Hitbox`, `Hurtbox`, `HitFlash`, `Weapon`, `ProjectilePool`.
- Dati come Resource: `WeaponData`, `EnemyData`, `PlayerStats` (+ `.tres` iniziali).
- Autoload `RunManager` (exp di run), input map, collision layers nominati.
- BEST_PRACTICES: API poolable, componenti combat, composition root, tabella collision layers.
- Documento di design iniziale (`docs/GDD.md`): scope MVP, core loop hub/run/estrazione, doppia progressione, extraction shooter layer.
- Setup repo git locale, changelog, best practice di sviluppo.

### Changed
- Gioco rinominato **Wanderloot** (GDD, BEST_PRACTICES, `project.godot`). Repo GitHub collegato, task tracking su GitHub Issues attivo.
- Knockback e hitstop spostati definitivamente a M4.
- `CHANGELOG.md` spostato in `docs/` (coerente con i riferimenti in GDD e BEST_PRACTICES).

