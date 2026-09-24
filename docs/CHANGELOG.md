# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/it/1.1.0/). Ogni voce va aggiunta sotto "Unreleased" al momento della modifica, non a posteriori.

## [Unreleased]

### Added
- Lingue italiano, inglese, francese e spagnolo: testi di scene, dati e codice come chiavi in `data/i18n/strings.csv`, selettore nelle Opzioni; a partita avviata il cambio lingua salva e torna al menu iniziale; lingua salvata nel file impostazioni e riapplicata all'avvio; `LocaleSettings` e test sulle traduzioni (#44).
- Opzioni anche dal menu di pausa (run e hub): pannello Opzioni unico riusato dal menu iniziale, Cancella dati solo nel menu iniziale (#43).
- Statistiche del personaggio nell'HUD della run (aggiornate a ogni potenziamento); nell'hub finestra Inventario con schede Inventario e Statistiche, aperta con I, C, icone cliccabili in alto a destra o dal baule: si equipaggia senza andare al baule; `StatSheet` testato (#42).
- Salvando dalla piazza si salva anche la posizione del player: Carica e Continua lo rimettono nello stesso punto (salvataggio v4, compatibile con v3); test dedicati (#41).
- Rifiniture dal playtest: ombra del Re Slime attaccata al corpo, nessun cerchio di preavviso sulla raffica a ventaglio (`BossAttack.show_windup`), freccia verso l'estrazione gialla (#40).
- Boss Re Slime nella Cripta: compare 20s dopo l'apertura dell'estrazione; raffica a ventaglio, anelli, salto schiacciante con cerchio rosso di preavviso, spirale in fase 2; drop garantiti di gelatina e nuclei; grafica vettoriale e test sui dati (#39).
- Sistema boss riutilizzabile: `BossData` e `BossAttack` (.tres) con raffica a ventaglio, anello e salto schiacciante, preavviso con cerchio rosso a terra (`Telegraph`), fase 2 sotto soglia di HP, comparsa configurabile in `ArenaData`, barra HP del boss nell'HUD, texture opzionale dei proiettili in `WeaponData`, suoni dedicati, bot che schiva i cerchi; test sulla logica pura (#38).
- Menu iniziale (scena principale): Continua se esiste un salvataggio, Nuova partita, Opzioni con volume di Musica ed Effetti (salvati in `user://settings.cfg`) e cancellazione dei dati con conferma, Esci; Torna al menu nel menu di pausa; `AudioSettings` testato (#37).
- Salvataggi manuali: nulla viene scritto su disco finché non si preme Salva nel menu di pausa (ESC) in run o nella piazza; menu di pausa con Riprendi, Salva, Carica; Carica abbandona la run e torna all'hub; `MetaProgression.save_game/load_game/new_game/delete_save`, `GameSession`, `RunManager.abort_run`; il vecchio salvataggio automatico viene cancellato (si riparte da zero); test dedicati (#36).
- Guida operativa `docs/GUIDA_CONTENUTI.md`: come creare nemici, arene, personaggi, materiali, equipaggiamento, ricette, potenziamenti, suoni e punti di interazione sfruttando dati, generatori, bot e test esistenti; GDD aggiornato (roadmap M5–M7, struttura attuale riordinata, open questions su zoom, difficoltà e scelta del personaggio), BEST_PRACTICES con la regola "dati prima del codice".
- Hub come piazza all'aperto esplorabile: fontana, forgia, magazzino, alberi, lampioni e portale in stile vettoriale, atmosfera serale; il player cammina e con E apre le finestre di fabbro, baule/equipaggiamento e portale (mondo in pausa, ESC o E chiude); `Interactable` e azione `interact`, test dedicati (#35).
- Arena Ossario: buio quasi totale, candele rosse, nebbia, decorazioni macabre, musica cupa, ondate più dure, sblocco dopo 3 estrazioni nella Cripta; nuova ricetta Bacchetta d'ossa con i materiali dell'Ossario (#33).
- Nemici macabri: Ghoul (veloce, fragile) e Scheletro arciere (mantiene la distanza e tira dardi, primo nemico a distanza con proiettili nemici poolati); comportamento e arma nei dati, nuovi materiali Frammento d'osso ed Essenza d'ombra, test dedicati (#34).
- Arene guidate dai dati: `ArenaData` (aspetto, luci, musica, ondate, nemici con peso e tempo minimo, sblocco), `ArenaCatalog`, spawner multi-nemico, pannello Portale nell'hub, estrazioni per arena e arena scelta nel salvataggio v3 (#32).
- Atmosfera cupa nella Cripta: ambiente scurito, luce portata dal player, torce tremolanti, vignettatura; proiettili, pickup e zona di estrazione restano luminosi (#31).
- Bilanciamento dal playtest: rage più veloce (×1,8) e fase avanzata delle ondate dopo 60s (spawn 40% più rapido, +20 nemici vivi) (#30).
- Rage dei nemici: dopo 5s in vita lo slime diventa rosso, più veloce (×1,5) e più dannoso (+1); valori in `EnemyData`, test dedicati (#29).
- Arena e icone in stile vettoriale: pavimento a lastre, muri a mattoni, icone di materiali ed equipaggiamento per hub, inventario e oggetti a terra (#28).
- Grafica vettoriale (addio pixel art) per player, slime, proiettile e gemma di exp: sorgenti SVG, PNG a 2x, filtro lineare, collider dello slime riallineati; `tools/sprites.py` diventa il generatore vettoriale (#27).
- 8 nuovi potenziamenti di level-up (13 totali, senza tetto): Persistenza, Magnete, Saggezza, Fortuna, Guardia, Impatto, Ventaglio (multishot) e Perforazione; test dedicati (#25).
- Raccolta a magnete: gemme di exp e materiali restano a terra, entro un raggio volano verso il player e vengono assorbiti con due suoni distinti; `PickupPool` testato. Exp e loot contano solo se raccolti (#22).
- Inventario di run con il tasto I: pannello sulla metà destra, gioco in pausa, equipaggiamento indossato e loot a rischio della run (#24).
- Menu di pausa con ESC (Riprendi, Pausa) e pausa diretta con P, scritta PAUSA al centro; `PauseState` testato, pausa combinata con quella del level-up (#23).
- HUD: barra HP rossa e barra EXP blu; scalatura della finestra `canvas_items` (base 1280x720, aspect expand) per lo schermo intero (#26).
- Cadenza di fuoco senza tetto: cooldown ad accumulatore, più proiettili nello stesso tick oltre i 60 colpi/s, test dedicati (#21).
- Playtest end-to-end automatico `tools/flow.gd` (hub→run→estrazione→craft→equip→morte→hub→ricarica) con correzioni: crash del focus differito nell'hub dopo il cambio scena, indicatore a bordo schermo verso la zona di estrazione (#20). MVP completato.
- Bilanciamento guidato dal bot di playtest `tools/autoplay.gd`: zona di estrazione a 120s (canale 6s), ondate più graduali, tetto di nemici che cresce nel tempo (`WaveData.max_alive_at`, niente farming infinito), drop e costi delle ricette ricalibrati; tabella dei risultati in GDD §10.1 (#17).
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

