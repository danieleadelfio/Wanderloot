# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/it/1.1.0/). Ogni voce va aggiunta sotto "Unreleased" al momento della modifica, non a posteriori.

## [Unreleased]

### Added
- Audio minimo: SFX chiptune e due musiche in loop generati da `tools/audio.py`, `SoundBank`/`SfxPlayer`/`MusicPlayer`, bus Music/SFX, suoni collegati via segnali in Arena e Hub (#19).
- Asset pixel art 16x16 (scala 2, filtro nearest): player, slime e proiettile sprite al posto dei `Polygon2D`, pavimento e muri a tile, icone di materiali ed equipaggiamento nell'hub; generatore `tools/sprites.py`. Decisa la open question 16x16 vs 32x32 (#18).
- Combat feel: knockback data-driven (`Knockback`), freeze locale sui nemici colpiti, hitstop globale solo sul danno al player (`HitStop`), lampeggio durante gli i-frames (`Blink`) (#16).
- Persistenza dell'equipaggiamento (salvataggio v2, compatibile con v1, id sconosciuti scartati) e 17 nuovi test GdUnit4 (38 totali): crafting, loadout, spesa materiali, `StatApplier`, `Player.begin_run`, persistenza equip e migrazione v1 (#15). M3 completato.
- Equipaggiamento applicato alle stats di inizio run (`Player.begin_run()`, `StatApplier` condiviso con gli upgrade) e pannello Equipaggiamento nell'hub (#14).
- Fabbro nell'hub: ricette fisse (`RecipeData`, `MaterialCost`, `RecipeBook`), regole in `Crafting`, `MetaProgression.craft()` scala i materiali e salva; `MetaInventory.can_afford/spend` (#13).
- Modello dati dell'equipaggiamento: `EquipmentData` (slot arma/accessorio), `StatModifier`, `EquipmentCatalog` con 4 pezzi; `EquipmentLoadout` in `MetaProgression` (posseduti/equipaggiati) (#12).
- Scena Hub come scena principale: baule con i materiali permanenti e partenza della run; a fine run si torna all'hub (#11).
- Trasferimento del loot su estrazione riuscita e perdita su morte (`LootTransfer`), riepilogo loot nella schermata di fine run (#10).
- Test GdUnit4 (21 casi): trasferimento loot, inventari run/meta, persistenza, `RunManager`, drop, curva exp, estrazione upgrade. M2 completato.
- Autoload `MetaProgression` con inventario permanente `MetaInventory`, salvataggio/caricamento `ConfigFile` versionato in `user://` (#9).
- Drop di materiali alla morte dei nemici nell'inventario di run, contatore "Loot a rischio" in HUD (#8).
- Inventario di run `LootRunInventory` separato dal permanente, posseduto da `RunManager` e svuotato a ogni run (#7).
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

