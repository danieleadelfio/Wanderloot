# FirstAiGame — Game Design Document (MVP)

Ultimo aggiornamento: 2026-09-22
Engine: Godot 4.6
Stato: MVP scope — prima versione giocabile

## 1. Pitch

Dungeon crawler/arena 2D top-down, ranged, in pixel art (16x16 o 32x32), fantasy. Il giocatore parte da un hub centrale sicuro e si lancia in run procedurali/semi-fisse in stile "arena survivor" (Vampire Survivors / Brotato / Hades): durante la run sale di livello e sceglie potenziamenti temporanei, mentre nemici e forzieri droppano loot ed equipaggiamento grezzo. Quel loot resta "a rischio" finché non si compie un'estrazione riuscita: morire prima di estrarre significa perderlo tutto. Solo il loot estratto entra nell'inventario permanente e alimenta crafting ed equipaggiamento nell'hub, che a sua volta sblocca nuove strutture e NPC.

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
- Exp guadagnata uccidendo nemici → level-up.
- Ad ogni level-up: pausa, 3 scelte casuali (pesate) tra potenziamenti d'arma, abilità passive, statistiche.
- Tutto ciò che riguarda questa progressione si azzera all'inizio di ogni run, indipendentemente dall'esito.

### 3.2 Progressione esterna alla run (permanente, meta)
- Alimentata **solo** dal loot estratto con successo.
- Due filoni:
  - **Materiali da crafting** (comuni/rari) → usati per craftare o potenziare equipaggiamento nell'hub.
  - **Equipaggiamento grezzo/non identificato** → utilizzabile solo dopo l'estrazione; una volta in hub può essere equipaggiato o smontato in materiali.
- L'equipaggiamento permanente scelto in hub prima della run (arma di partenza, oggetti passivi permanenti) influenza il power level di partenza della run successiva.
- Sblocco progressivo di strutture/NPC nell'hub in base a milestone (es. numero di estrazioni riuscite, materiali totali raccolti, boss sconfitti).

## 4. Extraction shooter layer — regole di rischio

- Il loot grezzo vive in un "inventario di run" separato da quello permanente.
- **Morte prima dell'estrazione = perdita totale del loot di run.** (Regola scelta per l'MVP: nessuna mitigazione parziale, per mantenere la tensione rischio/ricompensa netta.)
- L'estrazione è un punto/area che appare dopo un certo tempo o dopo un trigger (es. uccisione di un'elite), e richiede di rimanere nella zona per N secondi (rischio: i nemici continuano ad arrivare durante il canale).
- Possibile estensione futura (fuori scope MVP): possibilità di estrarre "in anticipo" con meno loot ma meno rischio, o zone a rischio/reward crescente.

## 5. Combattimento (ranged)

- Player controllato con movimento in 8 direzioni (WASD/stick) + mira libera (mouse o stick destro) — twin-stick style.
- Arma di partenza singola (es. "arco" o "baccheta magica base"), a distanza, con cooldown/fire-rate.
- I proiettili sono sprite semplici (piccoli cerchi/frecce), riutilizzabili via object pooling per performance.
- Nemici: pattern semplici (inseguimento diretto, mantenimento distanza + attacco ranged, pattern a pattuglia). Nessuna animazione complessa richiesta: 1-2 frame di movimento + 1 di attacco/morte sono sufficienti in stile pixel art.
- Combat feel gestito via codice: knockback, hit-flash, hitstop leggero, i-frames sul player — nessun bisogno di asset aggiuntivi per "sentire" l'impatto.

## 6. Loot e crafting (scope MVP)

- I nemici droppano: exp (sempre) + eventualmente 1 tipo di materiale comune.
- Rari drop: pezzo di equipaggiamento grezzo (non identificato/non equipaggiabile finché non estratto).
- Crafting MVP: sistema semplice "materiali → oggetto", con ricette fisse (niente crafting proceduralmente generato in v1).
- Equipaggiamento MVP: slot minimi (arma, 1 accessorio) per non esplodere lo scope.

## 7. Hub centrale (scope MVP)

Per l'MVP, hub ridotto a:
- **1 NPC "Fabbro/Blacksmith"**: crafting base e potenziamento equipaggiamento con i materiali estratti.
- **1 baule/inventario permanente**: dove finisce il loot dopo un'estrazione riuscita.
- **1 portale/punto di partenza run**.

Fuori scope MVP ma parte della visione a lungo termine (da aggiungere per fasi successive): NPC mercante (compra/vendi), NPC alchimista (pozioni/buff), strutture che si sbloccano con la progressione (nuova ala dell'hub, arena di addestramento, ecc.), più tipi di run/arena, più armi ranged ed elite/boss.

## 8. Arte e stile

- Stile: pixel art, griglia 16x16 o 32x32 (da fissare in fase di prototipo in base alla leggibilità a schermo; 32x32 dà più margine per dettagli su armi/effetti).
- Palette limitata (4-8 colori dominanti) per coerenza visiva e per ridurre il lavoro di produzione asset.
- Fonte asset consigliata: pacchetti pronti stile Kenney.nl (gratuiti) o pacchetti a pagamento coerenti (es. "Tiny Dungeon", "Cute Fantasy RPG") su itch.io, integrati con generazione AI mirata (sprite singoli, icone oggetti, tileset) per colmare i buchi specifici del proprio gioco.
- Nessuna animazione complessa richiesta per l'MVP: idle, movimento (2-4 frame), attacco, hit, morte per player e nemici base.

## 9. Struttura tecnica (Godot 4.6)

Struttura scene proposta (indicativa, da rifinire in fase di implementazione):

```
res://
  scenes/
    hub/
      Hub.tscn
      NpcBlacksmith.tscn
    run/
      Arena.tscn
      Player.tscn
      Enemies/
        EnemyBasic.tscn
        EnemyRanged.tscn
      Projectile.tscn
      ExtractionPoint.tscn
    ui/
      LevelUpChoice.tscn
      HubMenu.tscn
      HUD.tscn
  scripts/
    player/
      player_controller.gd
      player_stats.gd
    combat/
      projectile_pool.gd
      hitbox.gd
      hurtbox.gd
    run/
      run_manager.gd        # stato della run corrente, exp, level, timer estrazione
      loot_run_inventory.gd # inventario "a rischio" della run
    meta/
      meta_progression.gd   # inventario permanente, materiali, equip
      crafting_system.gd
    enemies/
      enemy_ai_base.gd
  data/
    weapons.tres / .json
    enemies.tres / .json
    upgrades.tres / .json
    recipes.tres / .json
  assets/
    sprites/
    tiles/
    audio/
```

Note tecniche:
- Autoload consigliati: `RunManager` (stato run corrente, azzerato ad ogni run) e `MetaProgression` (persistito su disco, es. tramite `ConfigFile` o risorse `.tres`/JSON in `user://`).
- Separare nettamente lo stato "run" da quello "meta" fin dall'inizio: è la base tecnica di tutta la meccanica extraction/estrazione (vedi §4). Il `RunManager` non deve mai scrivere direttamente su `MetaProgression`: lo fa solo l'evento "estrazione riuscita".
- Object pooling per proiettili e nemici comuni, utile fin da subito viste le run ad orde (arena survivor-like).
- Godot's `TileMap`/`TileSet` per l'arena, `Area2D` per hitbox/hurtbox e per il trigger di estrazione.

## 10. Roadmap per milestone

**M0 — Skeleton tecnico**: player che si muove e spara in un'arena vuota, un nemico che insegue, proiettili con pool, HUD minimale (HP/exp).
**M1 — Run loop completo**: level-up con scelta di 3 upgrade, spawn di nemici a ondate, punto di estrazione funzionante, morte = reset run.
**M2 — Loot ed extraction**: inventario di run separato da quello permanente, drop di materiali, trasferimento del loot solo su estrazione riuscita.
**M3 — Hub minimo**: scena hub, 1 NPC fabbro, crafting con ricette fisse, equipaggiamento persistente selezionabile prima della run.
**M4 — Rifinitura MVP**: bilanciamento (curve exp/danno/drop rate), asset pixel art definitivi, audio minimo, primo playtest completo hub→run→estrazione/morte→hub.

Fuori da questa roadmap (v2+): più NPC/strutture nell'hub, crafting proceduralmente ricco, più biomi/arene, boss, sistema di rarità loot più profondo, meccaniche di estrazione a rischio variabile.

## 11. Open questions

- Godot version confermata: 4.6 (da project.godot). Se si prevede export mobile o console, valutare per tempo eventuali limitazioni.
- Dimensione sprite definitiva (16x16 vs 32x32): da decidere dopo un primo test visivo in arena con la UI reale.
- Persistenza meta-progressione: `ConfigFile`/risorse `.tres` locali sono sufficienti per l'MVP; un salvataggio cloud non è nello scope iniziale.
- Durata target di una run (utile per bilanciare drop rate e timer di estrazione): da definire con il primo playtest.

## 12. Processo e versionamento

- Repo git locale inizializzato (nessun remote ancora collegato).
- Task tracking: GitHub Issues + Projects, da attivare quando viene collegato un remote GitHub. Fino ad allora nessun sistema di task parallelo.
- Vedi `docs/BEST_PRACTICES.md` per convenzioni di codice, architettura e testing (GdUnit4). Vedi `docs/CHANGELOG.md` per lo storico modifiche.
- **Regola fissa**: ogni modifica a feature/grafica/scope/genere/gameplay loop va riportata in questo documento (sezione pertinente) e come voce in `docs/CHANGELOG.md`, nello stesso commit della modifica.
