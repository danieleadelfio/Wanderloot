# Wanderloot — Game Design Document (MVP)

Nome del gioco: **Wanderloot** ("wanderlust" + "loot"). Nome di lavoro precedente: FirstAiGame.

Ultimo aggiornamento: 2026-09-24
Engine: Godot 4.6
Stato: MVP completato (M0–M4), post-MVP M5–M7 completati (due arene, nemici a distanza, hub esplorabile) — prossimo: playtest umano, zoom della camera, roadmap v2

## 1. Pitch

Dungeon crawler/arena 2D top-down, ranged, in grafica vettoriale 2D (da M6; prima pixel art), fantasy. Il giocatore parte da un hub centrale sicuro e si lancia in run procedurali/semi-fisse in stile "arena survivor" (Vampire Survivors / Brotato / Hades): durante la run sale di livello e sceglie potenziamenti temporanei, mentre nemici e forzieri droppano loot ed equipaggiamento grezzo. Quel loot resta "a rischio" finché non si compie un'estrazione riuscita: morire prima di estrarre significa perderlo tutto. Solo il loot estratto entra nell'inventario permanente e alimenta crafting ed equipaggiamento nell'hub, che a sua volta sblocca nuove strutture e NPC.

Riferimenti diretti: Vampire Survivors / Brotato (run loop, scelta reward a level-up), Hades (hub tra le run, progressione doppia), Risk of Rain 2 (arena + estrazione/portale di fine run), Escape from Tarkov (concetto di extraction shooter applicato al loot).

## 2. Core Loop

1. **Hub** — il giocatore prepara la run: sceglie equipaggiamento permanente (sbloccato via crafting), parla con NPC, eventualmente avvia il crafting.
2. **Run** — entra nell'arena/dungeon. Uccide nemici a distanza, guadagna exp e loot "grezzo" (in un inventario temporaneo, valido solo per questa run).
3. **Level-up in run** — al salire di livello il gioco si mette in pausa e propone 3 scelte di potenziamento temporaneo (danno, velocità, area, nuove abilità passive). Puramente run-scoped, si azzera a fine run.
4. **Fine run** — due esiti:
   - **Estrazione riuscita** (raggiungere un punto di estrazione e sopravvivere per un tempo/canalizzazione): il loot grezzo accumulato passa all'inventario permanente nell'hub.
   - **Morte**: tutto il loot grezzo della run viene perso. Non si perde invece l'exp/valuta eventualmente già "assicurata" da meccaniche specifiche (v. §4).
5. **Ritorno in hub** — con il loot estratto (se presente) si fa crafting/upgrade per la run successiva.

## 3. Le due progressioni

### 3.1 Progressione interna alla run (temporanea)
- Exp guadagnata raccogliendo le gemme lasciate dai nemici (da M5; prima era immediata) → level-up. Curva in `LevelCurve` (`data/run/level_curve.tres`): exp per passare da N a N+1 = `5 * 1.35^(N-1)` arrotondato (5, 7, 9, 12, 17…). L'exp in eccesso passa al livello successivo; più level-up in un colpo sono gestiti uno alla volta.
- Ad ogni level-up: pausa, 3 scelte casuali (pesate) tra potenziamenti d'arma, abilità passive, statistiche.
  - **Stato M1**: 5 upgrade di statistica in `data/upgrades/` (Potenza +1 danno, Raffica +20% cadenza, Gittata +20% velocità proiettili, Agilità +10% movimento, Vigore +1 HP max e cura 1), tutti con peso 1, estratti senza ripetizioni da `UpgradeTable`. Scelta con mouse o tastiera/pad (focus sul primo). Abilità passive/nuove armi: dopo l'MVP.
  - **Stato M5 (#25)**: 8 potenziamenti in più (13 totali), tutti cumulabili senza tetto. Statistiche: Persistenza +25% durata proiettili, Magnete +30% raggio di raccolta, Saggezza +15% exp raccolta, Fortuna +15% probabilità di drop, Guardia +0,2s di invulnerabilità, Impatto +30% spinta. Meccaniche (peso 0,6, più rari): Ventaglio +1 proiettile per colpo (ventaglio centrato, 10° tra i proiettili, compresso se supera 360°), Perforazione +1 nemico attraversato. Nuove voci di `UpgradeData.Stat` sempre in coda all'enum (i `.tres` salvano l'indice).
- Tutto ciò che riguarda questa progressione si azzera all'inizio di ogni run, indipendentemente dall'esito.

### 3.2 Progressione esterna alla run (permanente, meta)
- Alimentata **solo** dal loot estratto con successo.
- **Stato M2**: autoload `MetaProgression` con `MetaInventory` (id materiale → quantità, logica pura). Salvato in `user://meta_progression.cfg` (`ConfigFile`, con numero di versione) a ogni deposito, caricato all'avvio. Unico punto di scrittura esterno: `deposit_run_loot()`.
- **Stato M3 (#15)**: salvataggio versione 2 = materiali + equipaggiamento (`[equipment] owned`, `[equipped] weapon/accessory`), scritto a ogni deposito, craft, equip e unequip. Un salvataggio v1 si carica con loadout vuoto. Al caricamento gli id assenti dal catalogo e i pezzi equipaggiati ma non posseduti (o nello slot sbagliato) vengono scartati. Il loot entra ancora solo da `deposit_run_loot()`; i materiali escono solo da `craft()`.
- Due filoni:
  - **Materiali da crafting** (comuni/rari) → usati per craftare o potenziare equipaggiamento nell'hub.
  - **Equipaggiamento grezzo/non identificato** → utilizzabile solo dopo l'estrazione; una volta in hub può essere equipaggiato o smontato in materiali.
- L'equipaggiamento permanente scelto in hub prima della run (arma di partenza, oggetti passivi permanenti) influenza il power level di partenza della run successiva.
  - **Stato M3 (#14)**: pannello "Equipaggiamento" nell'hub (un pezzo per slot, click per equipaggiare/togliere). A inizio run `Arena` passa `MetaProgression.equipped_items()` a `Player.begin_run()`, che riparte da copie fresche di `PlayerStats`/`WeaponData` e applica i modificatori (`StatApplier`, stessa logica degli upgrade di run, che si sommano sopra). L'equip è letto una sola volta: cambiarlo vale dalla run successiva.
- Sblocco progressivo di strutture/NPC nell'hub in base a milestone (es. numero di estrazioni riuscite, materiali totali raccolti, boss sconfitti).

## 4. Extraction shooter layer — regole di rischio

- Il loot grezzo vive in un "inventario di run" separato da quello permanente.
  - **Stato M2**: `LootRunInventory` (classe pura `RefCounted`, id materiale → quantità) posseduta da `RunManager.loot`; si svuota a ogni `start_run()` e accetta loot solo a run in corso. Nessun autoload aggiuntivo.
- **Morte prima dell'estrazione = perdita totale del loot di run.** (Regola scelta per l'MVP: nessuna mitigazione parziale, per mantenere la tensione rischio/ricompensa netta.)
  - **Stato M2**: a fine run `Arena` chiama `LootTransfer.resolve()` (logica pura, coperta da test GdUnit4): con esito `EXTRACTED` il loot va in `MetaProgression.deposit_run_loot()` (salvato su disco), con `DEATH` viene scartato; in entrambi i casi l'inventario di run si svuota. La schermata di fine run mostra “Loot estratto: N · Totale nel baule: M” oppure “Loot perso: N”.
- L'estrazione è un punto/area che appare dopo un certo tempo o dopo un trigger (es. uccisione di un'elite), e richiede di rimanere nella zona per N secondi (rischio: i nemici continuano ad arrivare durante il canale).
  - **Stato M1** (`ExtractionData`, `data/run/extraction_default.tres`): la zona (cerchio verde, raggio 48px) appare dopo 60s di run in un punto casuale ad almeno 400px dal player; servono 5s dentro la zona. **Decisione:** uscendo il progresso non si azzera ma cala di 0.5s per ogni secondo fuori (un'uscita breve per schivare non vanifica tutto). HUD: countdown, poi percentuale di estrazione. Da M4 (#20): freccia verde sul bordo dello schermo verso la zona quando è fuori vista (`ExtractionIndicator`).
- Possibile estensione futura (fuori scope MVP): possibilità di estrarre "in anticipo" con meno loot ma meno rischio, o zone a rischio/reward crescente.

## 5. Combattimento (ranged)

- Player controllato con movimento in 8 direzioni (WASD/stick) + mira libera (mouse o stick destro) — twin-stick style.
- Arma di partenza singola (es. "arco" o "baccheta magica base"), a distanza, con cooldown/fire-rate.
- I proiettili sono sprite semplici (piccoli cerchi/frecce), riutilizzabili via object pooling per performance.
- **Nemici dell'Ossario (M7, #34)**: **Ghoul** (2 HP, velocità 175, rage dopo 4s ×1,25 cioè circa la velocità del player, 1 exp): inseguitore veloce e fragile. **Scheletro arciere** (3 HP, velocità 95, 2 exp): mantiene ~280px dal player (`EnemyMovement.keep_distance`, gira attorno quando è alla distanza giusta) e tira un dardo viola (240px/s, schivabile) ogni 2,6s entro 420px (primo nemico a distanza: `EnemyProjectile` poolato sul layer `enemy_attack`, unshaded). Entrambi usano `enemy.gd` con comportamento e arma nei dati (`EnemyData`: gruppo Comportamento). Drop: **Frammento d'osso** (comune; ghoul 6%, arciere 10%) ed **Essenza d'ombra** (rara; 0,4% / 1,2%): percentuali basse perché nell'Ossario si uccide molto (~680 nemici per run col bot).
- **Rage (M6, #29)**: un nemico vivo da più di `rage_after` secondi (slime: 5s) va in rage: velocità ×1,8 (era ×1,5, alzata dopo il primo playtest del proprietario), +1 danno da contatto, sprite che sfuma in 0,35s verso una variante rossa e arrabbiata. Si azzera quando il nemico torna nel pool. Valori in `EnemyData` (gruppo Rage). Con lo spawn ad almeno 300px e ~3s per raggiungere il player, quasi tutti i nemici che arrivano a contatto sono in rage: di fatto alza la pressione generale (voluto, vedi §10.3).
- Nemici: pattern semplici (inseguimento diretto, mantenimento distanza + attacco ranged, pattern a pattuglia). Nessuna animazione complessa richiesta: 1-2 frame di movimento + 1 di attacco/morte sono sufficienti in stile pixel art.
- Combat feel gestito via codice: knockback, hit-flash, hitstop leggero, i-frames sul player — nessun bisogno di asset aggiuntivi per "sentire" l'impatto.
- **Stato M4 (#16)**: knockback come componente `Knockback` (spinta che decade, `resistance` 0–1), alimentato da `Hurtbox.knocked`; intensità nei dati (`WeaponData.knockback` 320 → ~40px sullo slime, `EnemyData.contact_knockback` 380 → ~27px sul player, `knockback_resistance`). **Decisione hitstop**: sui colpi ai nemici (molto frequenti) solo freeze locale del nemico colpito (`EnemyData.hit_freeze` 0.05s); hitstop globale (`HitStop`, `Engine.time_scale` 0.05 per 0.08s reali) solo quando il player subisce danno, e `time_scale` viene sempre ripristinato all'uscita dalla scena. I-frames del player ora visibili (lampeggio `Blink`); il knockback da contatto allontana il player dal nemico, quindi il danno ripetuto a contatto diventa raro.
- **Stato M5 (#21)**: nessun tetto alla cadenza di fuoco. Prima l'arma sparava al massimo 1 colpo per tick di fisica (60/s) e l'arrotondamento del cooldown faceva perdere cadenza già da ~30 colpi/s; ora il cooldown è ad accumulatore e nello stesso tick partono tutti i colpi maturati, sfalsati lungo la traiettoria. Scelta di design: gli upgrade possono "rompere" il gioco, è parte del divertimento.
- **Stato M0**: movimento 8 direzioni (WASD/frecce/stick sinistro), mira col mouse tenendo premuto il tasto sinistro oppure stick destro con auto-fire, fire-rate da `WeaponData`. Implementati hit-flash (nemici e player) e i-frames del player (0.8s, danno da contatto ripetuto finché si resta a contatto). Knockback e hitstop rinviati a M4 (rifinitura).

## 6. Loot e crafting (scope MVP)

- I nemici droppano: exp (sempre) + eventualmente 1 tipo di materiale comune.
- Rari drop: pezzo di equipaggiamento grezzo (non identificato/non equipaggiabile finché non estratto).
- **Stato M2 (dati)**: `MaterialData` (id, nome, rarità comune/raro, colore placeholder) in `data/materials/`; drop table come array di `DropEntry` (materiale, probabilità, quantità min/max) dentro `EnemyData`, ogni riga tirata indipendentemente. Slime: Gelatina (comune) 35% ×1–2, Nucleo di slime (raro) 3% ×1. L'equipaggiamento grezzo arriva con M3 (crafting/equip), in M2 solo materiali.
- ~~Stato M2 (drop)~~: il loot andava direttamente nell'inventario di run. **Sostituito in M5 (#22)**: alla morte il nemico lascia a terra una gemma di exp (blu) e i materiali tirati dalla drop table (icona del materiale). Entro `PlayerStats.pickup_radius` (90px) vengono attratti verso il player con accelerazione (effetto magnete) e assorbiti al contatto, con due suoni distinti (`pickup_exp`, `pickup_item`). Exp e loot contano solo quando assorbiti; ciò che resta a terra a fine run è perso. Pool e movimento in `PickupPool` (un solo `_physics_process` per tutti gli oggetti), coperto da test. HUD: "Loot a rischio: N" in ambra.
- Crafting MVP: sistema semplice "materiali → oggetto", con ricette fisse (niente crafting proceduralmente generato in v1).
- Equipaggiamento MVP: slot minimi (arma, 1 accessorio) per non esplodere lo scope.
- **Stato M3 (#12, dati)**: `EquipmentData` (id, nome, descrizione, slot `WEAPON`/`ACCESSORY`, lista di `StatModifier`) in `data/equipment/`, tutti elencati in `EquipmentCatalog` (risolve gli id salvati). `StatModifier` riusa l'enum di `UpgradeData.Stat` (danno, cadenza, velocità proiettili, movimento, HP max). Pezzi iniziali: Bacchetta di gelatina (+1 danno), Bacchetta rapida (+25% cadenza), Amuleto del nucleo (+2 HP), Stivali viscosi (+10% movimento). **Decisione**: lo slot arma modifica la bacchetta base, non la sostituisce (nuovi tipi di arma: v2). L'equipaggiamento grezzo droppato in run resta fuori dall'MVP: i pezzi si ottengono solo col crafting.
- `EquipmentLoadout` (logica pura, in `MetaProgression.loadout`): pezzi posseduti per id, un pezzo equipaggiato per slot; si può equipaggiare solo ciò che si possiede.

## 7. Hub centrale (scope MVP)

Per l'MVP, hub ridotto a:
- **1 NPC "Fabbro/Blacksmith"**: crafting base e potenziamento equipaggiamento con i materiali estratti.
  - **Stato M3 (#13)**: pannello "Fabbro" nell'hub con le ricette fisse di `data/recipes/recipe_book.tres` (`RecipeData`: risultato + righe `MaterialCost`). Costi iniziali: Bacchetta di gelatina 6 Gelatina, Stivali viscosi 8 Gelatina, Bacchetta rapida 10 Gelatina + 1 Nucleo, Amuleto del nucleo 4 Gelatina + 2 Nuclei. Bottone disabilitato se mancano materiali o il pezzo è già posseduto. **Decisione**: ogni pezzo si crafta una sola volta (niente duplicati né potenziamento nell'MVP: potenziamento/smontaggio in v2). Regole in `Crafting` (logica pura); `MetaProgression.craft()` è l'unico punto che scala i materiali e salva.
- **1 baule/inventario permanente**: dove finisce il loot dopo un'estrazione riuscita.
- **1 portale/punto di partenza run**.
- **Stato M7 (#33, Ossario)**: seconda arena, si sblocca dopo **3 estrazioni riuscite nella Cripta**. Buio quasi totale (ambiente 0.19, 0.16, 0.22: ancora abbastanza per leggere i nemici), luce del player più corta, niente torce ma 12 candele rosse tremolanti, nebbia viola che scorre (`FogDrift`), pavimento di lastre scure con crepe e macchie di sangue, muri con teschi, 34 decorazioni (teschi, ossa, costole, lapidi, sangue). Musica: bordone dissonante, campana lontana e battito (`music_ossuary`, loop di 24s). Ondate più dure (`wave_ossuary.tres`: tetto 55, fase avanzata da 50s), estrazione a 120s con canale di 7s e zona ad almeno 450px. Nemici: Ghoul dall'inizio, Scheletro arciere dal secondo 15. Ricompensa: **Bacchetta d'ossa** (arma, +1 danno e +1 perforazione) = 40 Frammenti d'osso + 6 Essenze d'ombra.
- **Stato M7 (#32, arene)**: ogni arena è un `ArenaData` (`data/arenas/`): pavimento, muri, luce ambiente e del player, torce, musica, `WaveData`, `ExtractionData` e lista di `EnemySpawn` (scena, peso, da che secondo compare). `Arena.tscn` è una sola scena che si configura dall'arena scelta; il `WaveSpawner` crea un pool per tipo di nemico e sceglie il tipo per peso. Il portale (pannello nell'hub) mostra le arene: quelle bloccate indicano quante estrazioni servono e in quale arena. `MetaProgression` salva estrazioni riuscite per arena e arena scelta (salvataggio v3, carica v1/v2). Prima arena: **Cripta**, sempre disponibile.
- **Stato M8 (#37, menu iniziale)**: il gioco parte da `scenes/menu/MainMenu/` (scena principale): **Continua** (solo se esiste un salvataggio: carica e va all'hub), **Nuova partita** (stato vuoto in memoria; il file resta finché non si salva), **Opzioni** (volume Musica ed Effetti 0–100% su scala logaritmica sopra i valori del bus layout, salvati subito in `user://settings.cfg` e applicati all'avvio da `AudioSettings`; **Cancella dati salvati** con doppia conferma), **Esci**. Il menu di pausa aggiunge **Torna al menu** (abbandona la run; con modifiche non salvate chiede una seconda pressione).
- **Stato M8 (#36, salvataggi)**: **salvataggi solo manuali**. `MetaProgression` lavora in memoria; su disco (`user://save.cfg`, formato v3) si scrive solo con **Salva** nel menu di pausa (ESC), disponibile in run e nella piazza (ESC senza finestre aperte). Menu di pausa: Riprendi, Salva, Carica (disattivato senza salvataggio); P resta la pausa diretta in run. Salvare in run salva lo stato permanente (baule, equipaggiamento, estrazioni, arena scelta): il loot della run in corso resta a rischio e non viene salvato. **Carica** ricarica il file e torna all'hub, abbandonando la run in corso (`RunManager.abort_run()`, nessun esito). Il vecchio file dei salvataggi automatici (`user://meta_progression.cfg`) viene cancellato all'avvio: si riparte da zero. Azioni condivise in `GameSession` (logica di sessione, nessun autoload nuovo).
- **Stato M7 (#35, piazza)**: l'hub è una **piazza all'aperto esplorabile** (`Hub.tscn`, Node2D): pavimento in ciottoli, fontana al centro, forgia (tetto rosso) e magazzino (tetto blu) sul lato nord, alberi ai bordi, 8 lampioni, portale ad arco con vortice viola al lato sud. Atmosfera serale (`CanvasModulate` 0.52, 0.49, 0.68 e luci calde dei lampioni). Il player (stessa scena della run, `weapon_enabled = false`) cammina nella piazza; camera con zoom 0,85 e limiti sulla piazza. Tre punti di interazione (`Interactable`, Area2D sul layer del player) con suggerimento "E — …": **incudine del fabbro** → finestra Fabbro, **baule** davanti al magazzino → finestra Baule + Equipaggiamento, **portale** → finestra Portale (scelta dell'arena + "Attraversa il portale"). Con una finestra aperta il mondo è in pausa (nodo `World` pausabile, hub e UI sempre attivi); ESC o E la chiude. Nuova azione di input `interact` (E, pad X). Asset generati da `tools/sprites.py` (`build_hub`). **Supera la decisione M3 (#11)** sull'hub solo menu.
- ~~Stato M3 (#11)~~ (superato in M7, #35): l'hub è una schermata UI (`scenes/hub/Hub/`), non ancora un ambiente esplorabile: pannello "Baule" con i materiali permanenti e bottone "Parti per la run". È la scena principale del gioco. A fine run (morte o estrazione) "Torna all'hub" sostituisce "Nuova run". **Decisione**: hub esplorabile con NPC fisici rinviato (M4 o v2), per l'MVP conta il ciclo hub→run→hub. Cambi scena via `change_scene_to_file` con percorsi in `SceneRoutes` (nessun autoload aggiuntivo).

Fuori scope MVP ma parte della visione a lungo termine (da aggiungere per fasi successive): NPC mercante (compra/vendi), NPC alchimista (pozioni/buff), strutture che si sbloccano con la progressione (nuova ala dell'hub, arena di addestramento, ecc.), più tipi di run/arena, più armi ranged ed elite/boss.

## 8. Arte e stile

- Stile (da M6): **grafica vettoriale** con contorno scuro, sfumature e ombre morbide. Sorgenti SVG in `assets/art/`, PNG esportati a 2x della dimensione a schermo in `assets/sprites/`, Sprite2D a scala 0.5 con filtro lineare. ~~Pixel art 16x16/32x32~~: abbandonata in M6 dopo il confronto 16/32/64/vettoriale, per nitidezza a qualsiasi zoom e schermo intero e per un migliore rapporto qualità/costo di produzione degli asset generati.
- Palette limitata (4-8 colori dominanti) per coerenza visiva e per ridurre il lavoro di produzione asset.
- Fonte asset consigliata: pacchetti pronti stile Kenney.nl (gratuiti) o pacchetti a pagamento coerenti (es. "Tiny Dungeon", "Cute Fantasy RPG") su itch.io, integrati con generazione AI mirata (sprite singoli, icone oggetti, tileset) per colmare i buchi specifici del proprio gioco.
- Nessuna animazione complessa richiesta per l'MVP: idle, movimento (2-4 frame), attacco, hit, morte per player e nemici base.

- **Stato M6 (#28)**: pavimento a lastre (tile di 192px di mondo, 3x3 lastre con variazioni di tono e crepe) e muri a mattoni vettoriali; icone vettoriali di materiali ed equipaggiamento (64px sorgente, 32px nell'hub, 24px come oggetti a terra). Nessun ostacolo nell'arena per ora: richiede steering o pathfinding per i nemici, da discutere a parte.
- **Stato M6 (#27)**: player (mago incappucciato col bastone, 48px a schermo), slime (44px), proiettile (sfera con scia, 16px) e gemma di exp (16px) vettoriali; 2 frame di respiro per player e slime (`FrameCycler`). Collider dello slime allargati alle nuove dimensioni (corpo 16px, hurtbox e contatto 17px). Generatore: `tools/sprites.py` (Python + cairosvg).
- ~~Stato M4 (#18)~~ (superato in M6): primo set di asset in pixel art 16x16 (scala 2, filtro nearest), palette ristretta derivata da Sweetie-16, contorno scuro su tutti gli sprite. Generati da `tools/sprites.py` (sprite descritti come griglie di caratteri: modificabili e rigenerabili senza editor grafico). **Nota**: è programmer art coerente, non arte finale da artista; la pipeline permette di sostituire i PNG in `assets/sprites/` a parità di dimensioni senza toccare scene o codice.
- **Stato M4 (#19, audio)**: SFX chiptune sintetizzati da `tools/audio.py` (numpy): sparo, colpo e morte nemico, danno e morte player, level-up, apertura estrazione, estrazione riuscita, craft, selezione. Due musiche in loop (hub 90 BPM calma, arena 140 BPM incalzante). Bus `Music` (−8 dB) e `SFX` (−3 dB) in `default_bus_layout.tres`. Suoni per id in `data/audio/sound_bank.tres`; `SfxPlayer` (pool di 12 voci, min 30ms tra ripetizioni dello stesso suono, pitch variato sui suoni frequenti) ignora id/stream mancanti senza errori. Stessa nota della grafica: suoni programmatici sostituibili file per file.
- **Stato M5 (#26, HUD e schermo)**: barra HP rossa, barra EXP blu. Scalatura della finestra `canvas_items` con risoluzione base 1280x720 e aspect `expand`: a schermo intero gioco e HUD si ingrandiscono in proporzione invece di mostrare più arena a pixel minuscoli. Zoom della camera (`Arena/Player/Camera2D`): 1.0 per ora, **valore definitivo da scegliere con il playtest del proprietario** e da riportare qui.
- **Stato M7 (#31, atmosfera)**: tono più cupo con le luci 2D di Godot. L'arena attuale è la **Cripta** (arena iniziale): ambiente scurito da `CanvasModulate` (0.40, 0.38, 0.50), il player porta una luce calda (`Player/%Light`, raggio ~450px), 5 torce tremolanti per muro lungo (`Torch.tscn`, `LightFlicker`), vignettatura ai bordi. Proiettili, gemme, oggetti a terra e zona di estrazione sono *unshaded*: restano luminosi e leggibili al buio. HUD e menu sono su CanvasLayer propri e non vengono scuriti.
- **Stato M7 (#35, piazza)**: props vettoriali dell'hub generati da `build_hub()` (ciottoli, fontana, forgia e magazzino, incudine, baule, portale ad arco con vortice, lampione, due alberi). Lampioni e arco con materiale normale, illuminati dalle luci della piazza; il vortice del portale è unshaded.

## 9. Struttura tecnica (Godot 4.6)

La struttura target iniziale (M0) è superata dallo stato reale in §9.1. Per aggiungere contenuti (nemici, arene, personaggi, equipaggiamento, suoni) seguire `docs/GUIDA_CONTENUTI.md`.

### 9.1 Struttura attuale

```
res://
  autoload/run_manager.gd            # RunManager: stato, exp, livello, tempo, uccisioni, loot di run
  autoload/meta_progression.gd       # MetaProgression: inventario, equip, estrazioni per arena, arena scelta, salvataggio v3
  scripts/core/scene_routes.gd       # percorsi delle scene principali (MainMenu, Hub, Arena)
  scripts/core/                      # game_session (Salva/Carica/Torna al menu), audio_settings (volumi, file impostazioni)
  scenes/menu/MainMenu/              # menu iniziale (scena principale): Continua, Nuova partita, Opzioni, Esci
  scripts/data/                      # classi Resource: arena_data, arena_catalog, enemy_spawn, enemy_data, weapon_data, player_stats, wave_data, extraction_data, level_curve, upgrade_data, upgrade_table, material_data, drop_entry, equipment_data, equipment_catalog, stat_modifier, recipe_data, material_cost, recipe_book
  scripts/meta/                      # meta_inventory, equipment_loadout, crafting (logica pura dello stato permanente)
  scripts/combat/                    # health, hitbox, hurtbox, hit_flash, weapon, projectile_pool, knockback, hit_stop, blink, frame_cycler, light_flicker
  scripts/run/                       # enemy_pool, wave_spawner, enemy_movement, spawn_utils, loot_run_inventory, loot_transfer, stat_applier, pickup_pool, pause_state, pause_controller, fog_drift
  scripts/hub/                       # interactable (punto di interazione, nearest_index testato), spinner (vortice del portale)
  scripts/audio/                     # sound_entry, sound_bank, sfx_player, music_player
  scenes/hub/Hub/                    # Hub.tscn + hub.gd: piazza esplorabile, scena principale, composition root dell'hub
  scenes/hub/{Blacksmith,LoadoutPanel,ArenaSelect}/ # finestre dell'hub: fabbro, equipaggiamento, portale (segnali verso l'hub)
  scenes/hub/Lamp/                   # lampione con luce calda
  scenes/run/Arena/                  # Arena.tscn + arena.gd: unica scena di arena, configurata da ArenaData (composition root della run)
  scenes/run/Player/                 # Player.tscn + player.gd (usato in Arena e Hub)
  scenes/run/Enemies/enemy.gd        # script nemico condiviso, guidato da EnemyData
  scenes/run/Enemies/{EnemyBasic,Ghoul,SkeletonArcher}/ # scene dei nemici (stesso script, dati e grafica diversi)
  scenes/run/Projectile/             # Projectile.tscn (player) ed EnemyProjectile.tscn (layer enemy_attack), poolable
  scenes/run/{Pickup,ExtractionPoint,Torch,Candle}/ # oggetto a terra, zona di estrazione, torcia, candela
  scenes/ui/                         # HUD, LevelUpChoice, RunEndScreen, PauseMenu, RunInventory, ExtractionIndicator
  data/arenas/                       # arena_catalog + un .tres per arena (crypt, ossuary)
  data/{weapons,enemies,player,waves,run,upgrades,materials,equipment,recipes,audio}/ # istanze .tres di tutti i contenuti
  assets/art/                        # sorgenti SVG (generati da tools/sprites.py)
  assets/sprites/                    # PNG a 2x (personaggi, nemici, tile, decorazioni, props dell'hub, icone)
  assets/audio/                      # WAV di SFX e musiche (generati da tools/audio.py)
  tools/sprites.py, tools/audio.py   # generatori di grafica vettoriale e audio (Python)
  tools/autoplay.gd, tools/bot_driver.gd # bot di playtest per il bilanciamento (metriche su N run, anche per arena)
  tools/flow.gd                      # playtest end-to-end automatico hub→run→hub
  addons/gdUnit4/                    # framework di test (v6.2.1, vendored)
  tests/                             # test GdUnit4, specchio di scripts/ e autoload/
docs/                                # GDD, CHANGELOG, BEST_PRACTICES, GUIDA_CONTENUTI (procedure operative per i contenuti)
```

- Grafica (M6): sprite vettoriali in `assets/sprites/` (player e slime a 2 frame via `FrameCycler`, proiettile, pavimento e muri a tile ripetute, icone 16x16 di materiali ed equipaggiamento usate nell'hub). Arena 1600x1000: muri visibili larghi 32px sul bordo, area giocabile ±768x±468, camera sul player con limiti arena.
- Autoload attivi: `RunManager` (stato run) e `MetaProgression` (stato permanente, da M2). Nessun altro.
- Nemici: `EnemyPool` (un pool per tipo di nemico, 32 pre-istanziati, cresce se serve) + `WaveSpawner` guidato da `WaveData`: l'intervallo tra batch scende da 2.0s a 0.5s (−0.015s per secondo di run), il batch cresce di 1 nemico ogni 25s, tetto 60 nemici vivi. Spawn in punto casuale ad almeno 300px dal player.
- Flusso di run (M1): `RunManager` è una macchina a stati `IDLE → RUNNING ⇄ LEVEL_UP → ENDED` con esito `DEATH` o `EXTRACTED`. `Arena` mette in pausa il gioco quando lo stato non è `RUNNING`. A fine run: schermata con esito, livello, tempo e uccisioni, bottone “Torna all'hub” (da M3; nuova run = scena `Arena` nuova + `start_run()`). Il canale di estrazione non è uno stato globale: vive in `ExtractionPoint` (nessun altro sistema ne dipende). `RunManager` non scrive mai su `MetaProgression` (vedi §4).
- Collision layers (nomi in Project Settings): 1 `world`, 2 `player`, 3 `enemy`, 4 `player_attack`, 5 `enemy_attack`.
- Input map: `move_*` (WASD, frecce, stick sinistro), `aim_*` (stick destro), `shoot` (mouse sinistro), `menu` (ESC, Start), `pause` (P), `inventory` (I, Back), `interact` (E, pad X; hub, M7).
- Pausa (M5, #23): ESC apre il menu di pausa (Riprendi, Pausa; predisposto per altre voci), P mette direttamente in pausa con la scritta PAUSA bianca semitrasparente al centro (96px su base 720p). ESC chiude qualsiasi pausa aperta. Logica in `PauseState` (pura, testata), input in `PauseController`; `Arena` mette in pausa se lo chiede la run (level-up, fine run) o il giocatore. Durante level-up e fine run ESC/P/I sono ignorati.
- Inventario di run (M5, #24): I apre un pannello sulla metà destra dello schermo e mette in pausa; mostra l'equipaggiamento indossato (per slot) e il loot raccolto nella run con il totale a rischio. Si chiude con I o ESC. È un quarto modo di `PauseState`, quindi non si sovrappone a menu e pausa.

Note tecniche:
- Autoload consigliati: `RunManager` (stato run corrente, azzerato ad ogni run) e `MetaProgression` (persistito su disco, es. tramite `ConfigFile` o risorse `.tres`/JSON in `user://`).
- Separare nettamente lo stato "run" da quello "meta" fin dall'inizio: è la base tecnica di tutta la meccanica extraction/estrazione (vedi §4). Il `RunManager` non deve mai scrivere direttamente su `MetaProgression`: lo fa solo l'evento "estrazione riuscita".
- Object pooling per proiettili e nemici comuni, utile fin da subito viste le run ad orde (arena survivor-like).
- Godot's `TileMap`/`TileSet` per l'arena, `Area2D` per hitbox/hurtbox e per il trigger di estrazione.

## 10. Roadmap per milestone

**M0 — Skeleton tecnico** ✅ (2026-09-23): player che si muove e spara in un'arena vuota, un nemico che insegue, proiettili con pool, HUD minimale (HP/exp). Dettagli in §5 e §9.1.
**M1 — Run loop completo** ✅ (2026-09-23): level-up con scelta di 3 upgrade, spawn di nemici a ondate, punto di estrazione funzionante, morte = reset run.
**M2 — Loot ed extraction** ✅ (2026-09-23): inventario di run separato da quello permanente, drop di materiali, trasferimento del loot solo su estrazione riuscita.
**M3 — Hub minimo** ✅ (2026-09-23): scena hub, 1 NPC fabbro, crafting con ricette fisse, equipaggiamento persistente selezionabile prima della run.
**M4 — Rifinitura MVP** ✅ (2026-09-23): combat feel (knockback, hitstop), bilanciamento (curve exp/danno/drop rate), asset pixel art definitivi, audio minimo, primo playtest completo hub→run→estrazione/morte→hub.
**M5 — Post-MVP: controlli e UI** ✅ (2026-09-23): cadenza senza tetto, raccolta a magnete, pausa (ESC/P), inventario di run (I), 8 nuovi potenziamenti, barre HUD e scalatura della finestra.
**M6 — Grafica vettoriale e rage** ✅ (2026-09-23): addio pixel art, arena e icone vettoriali, rage dei nemici, fase avanzata delle ondate dopo 60s.
**M7 — Atmosfera, arene, hub esplorabile** ✅ (2026-09-24): luci 2D e Cripta cupa, arene guidate dai dati con scelta dal portale, Ossario con Ghoul e Scheletro arciere, hub come piazza all'aperto.

Fuori da questa roadmap (v2+): più NPC/strutture nell'hub, crafting proceduralmente ricco, più biomi/arene, boss, sistema di rarità loot più profondo, meccaniche di estrazione a rischio variabile.

### 10.1 Bilanciamento M4 (#17)

Metodo: bot di playtest `tools/autoplay.gd` (kiting dai nemici vicini, mira automatica sul più vicino, va all'estrazione appena appare, upgrade casuale al level-up), 20–30 run per configurazione a velocità massima (`--fixed-fps`). Il bot mira meglio di un umano e schiva peggio: i numeri servono a confrontare configurazioni, non come verità assoluta.

| Configurazione | Estrazioni | Durata media | Uccisioni | Gelatina / run | Nuclei / run |
|---|---|---|---|---|---|
| Valori M3 (zona a 60s) | 70% | 74s | 88 | 46,6 | 2,3 |
| Zona a 120s, ondate M3 | 0% | 96s | 188 | — | — |
| **Finale** senza equip | 63% | 129s | 182 | 34,5 | 3,5 |
| Finale, Bacchetta di gelatina + Amuleto | 90% | 132s | 200 | — | — |
| Finale, Bacchetta rapida + Stivali | 80% | 134s | 200 | — | — |

Problemi trovati e scelte:
- Con la zona a 60s la run era troppo corta e l'economia regalava tutto: una sola estrazione bastava per craftare tutti e 4 i pezzi. Zona portata a **120s**, canale **6s**.
- Con la zona a 120s e le ondate di M3 il bot moriva sempre prima di 130s: intervallo tra batch che si riduce più lentamente (`interval_decay` 0.015 → **0.008**), batch che cresce ogni **40s** (era 25s), tetto iniziale **45** nemici vivi (era 60).
- **Fase avanzata (M6, #30, dal playtest del proprietario)**: dal secondo 60 l'intervallo tra batch si accorcia del 40% (`late_interval_multiplier` 0,6, anche sotto `min_interval`) e il tetto di nemici vivi sale di +20 (`late_max_alive_bonus`), oltre alla crescita di +5 ogni 30s. Valori in `WaveData` (gruppo "Fase avanzata"). Bot che sceglie bene (15 run): estrazioni dal 100% all'**80%**, uccisioni medie da 195 a 293, gelatina per run da ~32 a ~45 (l'economia accelera di circa il 40%: da rivedere se i pezzi arrivano troppo in fretta).
- **Bug di design trovato dal bot**: con un tetto fisso di nemici la pressione si fermava attorno ai 3 minuti e una run è durata 45 minuti, cioè farming infinito senza rischio. Ora il tetto cresce di **+5 ogni 30s** (`WaveData.max_alive_at`, coperto da test).
- Economia: Gelatina **20% ×1** (era 35% ×1–2), Nucleo **1,5%** (era 3%). Costi: Bacchetta di gelatina 25 Gelatina, Stivali 30, Amuleto 20 + 3 Nuclei, Bacchetta rapida 40 + 4 Nuclei. Obiettivo: primo pezzo dopo la prima estrazione riuscita, tutti e 4 dopo circa 4–5 estrazioni (6–8 run).
- L'equipaggiamento pesa: con 2 pezzi le estrazioni salgono dal 63% all'80–90%.

### 10.2 Playtest M4 (#20)

Playtest end-to-end automatico `tools/flow.gd` (bot): hub → run fino a un'estrazione riuscita → hub (baule aggiornato) → craft dal fabbro → equip → run con equip applicato → morte → hub (baule invariato) → ricarica del salvataggio da disco. Tutti i passi verificati; `Engine.time_scale` e pausa tornano sempre a normale. Trovati e corretti:
- **Crash**: il ripristino differito del focus nell'hub partiva dopo il cambio scena (`gui_get_focus_owner` su null) → controllo `is_inside_tree()`.
- **Blocco di UX**: con la zona a 120s in un'arena più grande dello schermo non c'era modo di sapere dove fosse → indicatore a bordo schermo.
- **Farming infinito** (vedi §10.1) → tetto di nemici crescente.

Non verificabile da bot, resta da fare a mano: feeling di controlli e mira col mouse, leggibilità degli sprite a 2x, volumi reali di SFX/musica, chiarezza di hub e fabbro per chi non conosce il gioco. Noti e accettati per l'MVP: nessun menu di pausa/uscita durante la run, nessun menu opzioni (volumi), nessuna schermata titolo.

### 10.3 Verifica M5 (#22, raccolta a magnete)

Con exp e materiali da raccogliere il bot che si limita a scappare crolla (estrazioni 20%, livello medio 4,2): conferma che la raccolta è una scelta attiva di rischio. Con il bot aggiornato (raccoglie gli oggetti quando non ha nemici vicini) i numeri tornano a quelli di M4 senza ritoccare i dati: estrazioni 65%, livello medio 8,8, ~31 gelatine per run (20 run). Raggio del magnete lasciato a 90px.

Con i nuovi potenziamenti (#25) il bot sceglie al level-up come un giocatore (prima combattimento: danno, cadenza, Ventaglio, Perforazione, HP). Risultato: **100% di estrazioni** su 20 run, ma lo stesso bot con i soli 5 potenziamenti di M4 fa ugualmente 100% (12 run). Il 63% misurato in M4 dipendeva dalla scelta casuale del bot, non dal gioco. **Da verificare con il playtest umano**: se chi sceglie bene estrae quasi sempre, la run a 120s è troppo facile e va alzata la pressione (ondate o zona più tardi). Non ritoccato ora per non bilanciare contro un bot.
Stress test "rompere tutto": 300 colpi/s × 20 proiettili × perforazione 5 → ~5.800 proiettili attivi, il gioco resta stabile ma la simulazione scende a circa metà velocità su una CPU cloud. Accettato: nessun tetto per scelta; eventuale ottimizzazione (proiettili fusi o fisica più leggera) solo se diventa un problema nel gioco reale.

### 10.4 Verifica M6 (#29, rage)

Con il bot che sceglie bene i potenziamenti la rage non cambia l'esito: 100% di estrazioni su 20 run; in una run campione 22 slime su 179 sono andati in rage e il player non ha subito nessun danno. Il problema non è la rage ma la potenza del player a metà run (Ventaglio, Perforazione, cadenza senza tetto). Leve possibili, da decidere dopo il playtest umano: rage più aggressiva (soglia più bassa, +velocità), più HP ai nemici nel tempo, un nemico a distanza, ondate più fitte dopo i 60s.

### 10.5 Verifica M7 (#33/#34, Ossario)

Bot migliorato per le arene affollate (schiva i dardi nemici; con la zona aperta dà priorità all'estrazione) e con resoconto del loot per materiale. Risultati:

| Arena | Equipaggiamento | Estrazioni | Uccisioni medie | Loot raccolto per run |
|---|---|---|---|---|
| Cripta | nessuno | 90% (10 run) | 273 | ~43 Gelatina, ~2,8 Nuclei |
| Ossario | nessuno | 20% (5 run) | 616 | — |
| Ossario | Bacchetta di gelatina + Amuleto | 60% (5 run) | 602 | ~27 Frammenti d'osso, ~2 Essenze |

Correzioni fatte durante la verifica: prima versione impossibile (0% anche con equip) perché i ghoul in rage erano più veloci del player e gli arcieri colpivano 5–8 volte per run senza possibilità di schivare → ghoul rage ×1,25 dopo 4s, dardi a 240px/s ogni 2,6s, meno arcieri (peso 0,3). Drop ridotti perché nell'Ossario si uccide 2–3 volte più che nella Cripta; la Bacchetta d'ossa arriva dopo ~3 estrazioni riuscite nell'Ossario.

## 11. Open questions

- Godot version confermata: 4.6 (da project.godot). Se si prevede export mobile o console, valutare per tempo eventuali limitazioni.
- ~~Dimensione sprite definitiva~~ → in M6 si passa alla grafica vettoriale (vedi §8): la domanda non si pone più. Storico: in M4 era stato deciso **16x16**, disegnati a scala 2 (32px a schermo), filtro nearest. Arena 1600x1000 con UI reale: a 32x32 i personaggi sarebbero stati troppo grandi rispetto al campo visivo e alla densità di nemici.
- ~~Persistenza meta-progressione~~ → decisa in M2 (da M8 solo salvataggi manuali, vedi §7): `ConfigFile` in `user://` (leggibile, versionato; niente `.tres` caricati da `user://`, che possono eseguire script). Cloud save fuori scope.
- ~~Durata target di una run~~ → M4: **~2–2,5 minuti** fino alla prima estrazione possibile (zona a 120s + 6s di canale); chi resta oltre rischia di più (tetto nemici crescente). Da confermare con playtest umano.
- **Zoom della camera in arena**: in attesa del valore scelto dal playtest del proprietario (oggi zoom 1). Nell'hub è 0,85.
- **Difficoltà per giocatori esperti**: il bot estrae nel 90% delle run nella Cripta; da verificare con giocatori umani se serve una curva più dura o se basta l'Ossario come sfida.
- **Scelta del personaggio**: non prevista finora; percorso tecnico descritto in `docs/GUIDA_CONTENUTI.md` §3.3, da pianificare con una issue.

## 12. Processo e versionamento

- Repo GitHub: `danieleadelfio/Wanderloot` (remote `origin`, branch `main`).
- Task tracking: GitHub Issues + Projects, attivo. Una milestone per ogni M del §10; nessun sistema di task parallelo.
- Vedi `docs/BEST_PRACTICES.md` per convenzioni di codice, architettura e testing (GdUnit4). Vedi `docs/CHANGELOG.md` per lo storico modifiche. Vedi `docs/GUIDA_CONTENUTI.md` per le procedure operative (nuovi nemici, arene, personaggi, equipaggiamento, suoni).
- **Regola fissa**: ogni modifica a feature/grafica/scope/genere/gameplay loop va riportata in questo documento (sezione pertinente) e come voce in `docs/CHANGELOG.md`, nello stesso commit della modifica.
