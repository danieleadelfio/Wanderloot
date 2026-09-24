# Guida operativa — creare contenuti in Wanderloot (Godot 4.6)

Come aggiungere nemici, arene, personaggi e gli altri contenuti sfruttando quello che il progetto ha già: classi `Resource` in `scripts/data/`, istanze `.tres` in `data/`, generatori di asset in `tools/`, bot di playtest e test GdUnit4.

Regola d'oro: **prima i dati, poi il codice**. Quasi tutto si fa creando o duplicando `.tres` e scene. Serve codice solo quando si introduce un *comportamento* nuovo (sezione 6).

---

## 0. Strumenti e operazioni base

### 0.1 Nell'editor di Godot

| Operazione | Come |
|---|---|
| Creare un `.tres` | FileSystem → tasto destro sulla cartella in `data/` → **Nuovo → Risorsa…** → cerca la classe (`EnemyData`, `ArenaData`, …) → salva. |
| Copiare un `.tres` esistente (consigliato) | FileSystem → tasto destro sul file → **Duplica…** → nuovo nome. Poi modifichi i valori nell'Inspector. |
| Copiare una scena | FileSystem → tasto destro sul `.tscn` → **Duplica…**, nella sua cartella (`scenes/<dominio>/<NomeScena>/`). Le forme di collisione interne restano indipendenti dall'originale. |
| Variante di una scena che segue l'originale | **Scena → Nuova scena ereditata…**. Le modifiche all'originale si propagano. Utile per i personaggi (§3). |
| Risorsa annidata condivisa per errore | Inspector → freccia sul campo → **Rendi unica**. Serve quando modifichi uno `Shape` o una `Gradient` di una scena duplicata e cambia anche l'originale. |
| Nodi con `%Nome` | Il codice li cerca per *unique name* (tasto destro sul nodo → **Accesso come nome univoco**). Se rinomini o togli quel flag, lo script si rompe. |

### 0.2 Generatori di asset (fuori dall'editor)

Dalla root del progetto, con Python 3 (`pip install cairosvg pillow numpy`):

```bash
python3 tools/sprites.py   # grafica: SVG in assets/art/, PNG a 2x in assets/sprites/
python3 tools/audio.py     # suoni e musiche WAV in assets/audio/
```

- **Grafica**: ogni asset è una funzione Python che restituisce un SVG. `save(nome, [frame1, frame2], lato_px)` affianca i frame in un solo PNG. Il PNG è a **2x** della dimensione a schermo: nella scena lo `Sprite2D` ha `scale = 0.5`, con `hframes` pari al numero di frame. Le dimensioni di riferimento sono nella §7.
- Puoi anche disegnare in Inkscape (o altro) e mettere un PNG in `assets/sprites/`, rispettando il 2x e lo stile (contorno scuro, sfumature). Se lo generi a mano, non aggiungerlo a `sprites.py`, che lo sovrascriverebbe.
- **Audio**: aggiungi i suoni nuovi **in fondo** a `tools/audio.py`, così i WAV esistenti restano identici e git non li vede cambiati. Per le musiche in loop: selezionale nel FileSystem → dock **Importa** → *Loop Mode* **Forward** → **Reimporta** (in `.import`: `edit/loop_mode=2`).
- Dopo aver generato, torna nell'editor: Godot importa i file nuovi da solo.

### 0.3 Verifica

| Cosa | Comando / dove |
|---|---|
| Test | Pannello GdUnit4 nell'editor, oppure `addons/gdUnit4/runtest.sh --godot_binary "/Applications/Godot.app/Contents/MacOS/Godot" -a res://tests` |
| Bilanciamento (bot) | `godot --headless --fixed-fps 60 --path . -s tools/autoplay.gd -- 10 arena=<id>` (aggiungi gli id di equipaggiamento dopo il numero di run: `-- 5 gel_wand core_amulet arena=ossuary`) |
| Giro completo hub→run→hub | `godot --headless --fixed-fps 60 --path . -s tools/flow.gd` |

Il bot stampa percentuale di estrazioni, durata, uccisioni e loot per materiale. Confronta i numeri **prima e dopo** ogni modifica ai `.tres` di bilanciamento e riporta i risultati nel GDD (§10).

---

## 1. Nuovo nemico

Tutti i nemici usano lo stesso script `scenes/run/Enemies/enemy.gd`: cambiano solo i dati (`EnemyData`) e la grafica. Esempi completi: `Ghoul` (in mischia, veloce) e `SkeletonArcher` (a distanza).

### 1.1 Grafica

1. In `tools/sprites.py` copia una funzione esistente (`ghoul_svg(up=False, rage=False)` o `skeleton_svg`) con un nome nuovo, es. `wraith_svg`. Il parametro `up` è il secondo frame dell'animazione, `rage` la variante rossa.
2. Aggiungi le chiamate in una funzione `build_...` richiamata in fondo al file (in `if __name__ == "__main__":`):
   ```python
   save("wraith", [wraith_svg(), wraith_svg(up=True)], 96)
   save("wraith_rage", [wraith_svg(rage=True), wraith_svg(up=True, rage=True)], 96)
   ```
3. `python3 tools/sprites.py`.

La variante rage è **obbligatoria**: lo script dissolve `%RageBody` verso il rosso quando il nemico va in rage. Se non vuoi la rage, crea comunque il nodo e imposta `rage_after = 0`.

### 1.2 Dati: `data/enemies/<id>.tres`

Duplica `ghoul.tres` (in mischia) o `skeleton_archer.tres` (a distanza) e modifica:

| Campo | Significato | Riferimenti |
|---|---|---|
| `max_hp`, `move_speed`, `contact_damage`, `exp_reward` | statistiche base | player: 220 di velocità, 10 HP |
| `contact_knockback`, `knockback_resistance` (0–1), `hit_freeze` | feeling dei colpi | |
| **Comportamento** `behavior` | `CHASE` (insegue) o `KEEP_DISTANCE` (tiene `preferred_distance`) | |
| `ranged_weapon` | un `WeaponData` → il nemico spara ogni `attack_interval` s entro `attack_range` | `data/weapons/skeleton_bow.tres` |
| **Rage** `rage_after`, `rage_speed_multiplier`, `rage_damage_bonus`, `rage_fade_time` | dopo N secondi in vita diventa rosso, più veloce e più dannoso; `rage_after = 0` la disattiva | con moltiplicatore alto supera la velocità del player |
| `drops` | lista di `DropEntry` (materiale, probabilità 0–1, quantità min/max) | Ossario: ossa 6–10%, essenza 0,4–1,2% |

I proiettili nemici usano un pool unico (`EnemyProjectile.tscn`, layer `enemy_attack`). Per un nemico a distanza basta creare un `WeaponData` (danno, velocità, durata, numero di proiettili e dispersione per i colpi a ventaglio).

### 1.3 Scena: `scenes/run/Enemies/<Nome>/<Nome>.tscn`

1. Duplica `Ghoul/Ghoul.tscn` nella nuova cartella.
2. Nodo radice: rinominalo, poi nell'Inspector imposta `data` → il tuo `.tres`.
3. `Body` e `%RageBody`: texture → i due PNG, `hframes = 2`. `offset` va regolato perché i piedi cadano sull'origine.
4. `%CollisionShape` (corpo, contro muri e altri nemici) e le forme di `%Hurtbox` e `%Hitbox`: raggio proporzionato allo sprite. Se cambi il raggio, usa prima **Rendi unica**.
5. Non toccare layer e mask:

| Nodo | layer | mask |
|---|---|---|
| radice | 4 (`enemy`, valore 4) | world + enemy (valore 5) |
| `%Hurtbox` | 0 | `player_attack` (valore 8) |
| `%Hitbox` | `enemy_attack` (valore 16) | 0 |

Nodi obbligatori, con questi unique name: `%Health`, `%Hurtbox`, `%Hitbox`, `%CollisionShape`, `%Knockback`, `%RageBody`, più `HitFlash` con `target` → `Body`.

### 1.4 Farlo comparire in un'arena

Apri `data/arenas/<arena>.tres` → **Gioco → enemies** → aggiungi un `EnemySpawn`:

- `scene`: la tua scena;
- `weight`: peso relativo nella scelta (il Ghoul dell'Ossario ha 1, l'arciere 0,3);
- `min_time`: da che secondo della run può comparire.

Non serve altro: `Arena` crea un `EnemyPool` per ogni voce e il `WaveSpawner` sceglie il tipo per peso. Suoni, exp, drop, knockback e rage sono già collegati.

### 1.5 Nuovo materiale di drop (se serve)

1. Icona: funzione `icon_...` in `sprites.py`, `save("icon_<id>", [..], 64)`.
2. `data/materials/<id>.tres` (`MaterialData`): `id` (StringName univoco, **finisce nel salvataggio: non cambiarlo più**), `display_name`, `rarity`, `color`, `icon`.
3. Aggiungilo all'array `materials` di **`scenes/hub/Hub/Hub.tscn`** (radice) e di **`scenes/ui/RunInventory/RunInventory.tscn`**, altrimenti baule e inventario mostrano l'id grezzo senza icona.
4. Usalo nei `drops` del nemico e in una ricetta (§4.2).

### 1.6 Verifica

- Test: prendi `tests/run/test_enemy_behaviours.gd` come modello (carica il `.tres` e verifica i valori chiave, per esempio "più lento del player in rage" oppure "a distanza ha un'arma").
- Bot: `-- 10 arena=<id>`. Se le estrazioni crollano, i sospetti tipici sono velocità in rage ≥ player, proiettili troppo veloci o drop troppo generosi.

---

## 1b. Nuovo boss

Tutti i boss usano lo script `scenes/run/Bosses/boss.gd`; cambiano dati (`BossData` + `BossAttack`) e grafica. Esempio completo: **Re Slime** (`scenes/run/Bosses/KingSlime/`, `data/bosses/king_slime.tres`, `data/bosses/attacks/king_slime_*.tres`).

1. **Grafica**: in `sprites.py` copia `king_slime_svg` e `build_boss()`. Il PNG del Re Slime è 256 px per frame (128 a schermo), 2 frame. Serve anche l'ombra (`boss_shadow.png`, riutilizzabile).
2. **Proiettili**: crea un `WeaponData` (danno, velocità, durata) con `projectile_texture` e `projectile_scale` per un aspetto dedicato (es. `king_slime_goo.tres`). I proiettili usano il pool dei proiettili nemici.
3. **Attacchi**: un `.tres` per attacco (`BossAttack`), riutilizzabili tra boss:

| Campo | Significato |
|---|---|
| `kind` | `AIMED_FAN` (ventaglio verso il player), `RING` (anello a 360°), `LEAP_SLAM` (salto sulla posizione del player) |
| `weight`, `min_phase` | peso nella scelta; 2 = solo in fase 2 |
| `telegraph_time` | preavviso: carica arancione attorno al boss (raffiche) o cerchio rosso a terra (salto) |
| `recovery` | pausa dopo l'attacco: la finestra per colpirlo |
| `projectile`, `projectile_count`, `spread_degrees`, `repeats`, `repeat_interval`, `ring_rotation_degrees` | proiettili (anche all'impatto del salto) |
| `radius`, `damage`, `knockback`, `leap_time`, `leap_height` | salto schiacciante |

   Regola: per `LEAP_SLAM`, `telegraph_time + leap_time` deve bastare a uscire dal cerchio anche partendo dal centro (`radius / 220` s × 1,5; lo verifica `tests/data/test_king_slime.gd`).
4. **Boss**: duplica `king_slime.tres` → HP, velocità, contatto, exp, `drops` (chance 1 = garantito), `attacks`, `first_attack_delay`, `chase_time`, gruppo **Fase 2** (soglia di HP, velocità, ritmo, tinta).
5. **Scena**: duplica `KingSlime.tscn`: radice → `data`; `Body/Sprite` → texture; raggi di collisione. Nodi obbligatori con unique name: `%Health`, `%Hurtbox` (mask 8), `%Hitbox` (layer 16), `%Body`, `%HitFlash`, `%Impact` (Telegraph con `top_level = true`), `%Windup` (Telegraph). La radice ha layer 4 e mask 1.
6. **Arena**: in `ArenaData`, gruppo **Boss** → `boss_scene`, `boss_delay` (secondi dopo l'apertura dell'estrazione), `boss_spawn_min_distance`. Barra HP, suoni, drop ed exp sono già collegati.
7. **Verifica**: `-- 8 boss arena=<id>` (il bot resta a combatterlo) e `-- 8 arena=<id>` (gioco normale); riporta la tabella nel GDD come in §10.6.

Un **tipo di attacco nuovo** (es. carica in linea retta) è codice: voce in coda a `BossAttack.Kind`, ramo in `Boss._begin_attack`/`_execute`, test sulla parte pura in `BossPatterns`.

## 2. Nuova arena

Un'arena è **un solo `.tres`** (`ArenaData`). La scena `Arena.tscn` è unica e si configura da lì: pavimento, muri, luci, torce, candele, nebbia, decorazioni, musica, ondate, estrazione, nemici e sblocco.

### 2.1 Asset

| Asset | Formato | Esempio |
|---|---|---|
| Pavimento | tile ripetibile 384x384 px (192 px di mondo) | `ossuary_floor_svg` → `ossuary_floor.png` |
| Muri | tile 64x64 px (32 px di mondo) | `ossuary_wall.png` |
| Decorazioni | PNG singoli (teschi, lapidi…), sparsi a caso | `deco_*.png` |
| Musica | WAV in loop (loop Forward all'import) | `music_ossuary` in `tools/audio.py` |

Copia `build_ossuary()` in `sprites.py` come modello. Le tile devono essere seamless (i bordi combaciano).

### 2.2 Dati

1. **Ondate**: duplica `data/waves/wave_default.tres` (o `wave_ossuary.tres` per un'arena più dura). `start_interval`, `min_interval` e `interval_decay` regolano la cadenza; `start_batch` e `batch_growth_period` la dimensione dei gruppi; `max_alive` e i campi `max_alive_growth_*` il tetto di nemici vivi. Il gruppo **Fase avanzata** (da `late_start` s) accelera gli spawn e alza il tetto.
2. **Estrazione**: duplica `data/run/extraction_default.tres`: `appear_after` (s), `channel_time` (s nella zona), `decay_rate` (quanto scende il progresso se esci), `spawn_min_distance` (distanza minima dal player).
3. **Arena**: duplica `data/arenas/ossuary.tres` e imposta:
   - `id` (univoco, **finisce nel salvataggio**), `display_name`, `description` (mostrata nel portale);
   - **Aspetto**: `floor_texture`, `wall_texture`, `ambient_color` (più è scuro più è cupo: Cripta 0,4, Ossario 0,19), luce del player (`player_light_*`), `torches_per_wall` e `torch_color`, `decorations` e `decoration_count`, `candle_count` e `candle_color`, `fog_color` (alfa 0 = niente nebbia) e `fog_count`, `music`;
   - **Gioco**: `wave_data`, `extraction_data`, `enemies` (§1.4);
   - **Sblocco**: `unlock_arena` + `unlock_extractions` (es. `crypt` + 3). Vuoto = sempre disponibile.
4. Aggiungi l'arena all'array `arenas` di **`data/arenas/arena_catalog.tres`**. L'ordine dell'array è quello del portale.

Già automatico: la voce nel portale dell'hub (col motivo del blocco), il conteggio delle estrazioni per arena nel salvataggio, la posizione stabile delle decorazioni (seme dall'`id`) e i pool di nemici.

### 2.3 Premio dell'arena

Un materiale nuovo (§1.5) negli `drops` dei suoi nemici e una ricetta che lo usa (§4.2). È questo che dà un motivo per rischiare l'arena più dura.

### 2.4 Verifica

- Test: modello `tests/data/test_ossuary.gd` (arena nel catalogo, sblocco dopo N estrazioni, ricetta presente).
- Bot, con e senza equipaggiamento: `-- 5 arena=<id>` e `-- 5 gel_wand core_amulet arena=<id>`. Riporta la tabella nel GDD §10 come per l'Ossario (§10.5).
- A mano: controlla che nemici, dardi e pickup si leggano con la luce scelta.

---

## 3. Personaggio giocante

**Stato attuale**: c'è un solo personaggio, `scenes/run/Player/Player.tscn`, istanziato in **due** scene: `Arena.tscn` (combatte) e `Hub.tscn` (cammina nella piazza con `weapon_enabled = false`). La scelta del personaggio non esiste ancora.

### 3.1 Modificare il personaggio attuale (solo dati)

| Cosa | Dove |
|---|---|
| HP, velocità, i-frames, raggio magnete, moltiplicatori exp/drop | `data/player/player_default.tres` (`PlayerStats`) |
| Arma di partenza (danno, cadenza, velocità e durata del proiettile, knockback, numero di proiettili, dispersione, perforazione) | `data/weapons/starter_wand.tres` (`WeaponData`), assegnata a `%Weapon` in `Player.tscn` |
| Aspetto | `player_svg(up)` in `sprites.py` → `player.png` (2 frame, 96 px per frame) |
| Luce portata | `%Light` in `Player.tscn`; per arena la sovrascrive `ArenaData.player_light_*` |

Equipaggiamento e potenziamenti lavorano su **copie** di stats e arma (`Player.begin_run()`): i `.tres` base non cambiano mai durante la partita.

### 3.2 Creare un personaggio alternativo (per prova)

1. **Scena → Nuova scena ereditata…** da `Player.tscn` → salva in `scenes/run/Player<Nome>/Player<Nome>.tscn`.
2. Crea `data/player/<nome>.tres` (duplica `player_default.tres`) e un'arma `data/weapons/<nome>_weapon.tres`.
3. Nella scena ereditata: radice → `stats` = il nuovo `.tres`; `%Weapon` → `data` = la nuova arma; `Body` → nuova texture.
4. Per giocarlo: in `Arena.tscn` e `Hub.tscn` cambia la scena istanziata dal nodo `Player`. Il modo più sicuro è aprire i due `.tscn` in un editor di testo e sostituire `res://scenes/run/Player/Player.tscn` nella riga `[ext_resource …]` con il percorso della nuova scena. Così restano il nome `Player`, il flag unique, la `Camera2D` figlia e le sovrascritture (es. `weapon_enabled = false` nell'hub). Se cancelli e reistanzi il nodo dall'editor, devi rifare tutto questo a mano.

Questo cambia il personaggio per tutti: va bene per provare, non è una selezione.

### 3.3 Selezione del personaggio (da fare, fuori scope attuale)

Va aperta una issue dedicata, perché serve codice. Percorso previsto, coerente con il resto del progetto:

- una classe `CharacterData` (`Resource`) con `id`, nome, `PlayerStats`, `WeaponData` iniziale e texture, più un `CharacterCatalog` come quello delle arene;
- personaggio scelto e sblocchi salvati in `MetaProgression` (salvataggio v4, compatibile con v3), come `selected_arena`;
- `Player` applica il `CharacterData` in `begin_run()`, così resta **una sola** scena `Player.tscn`;
- scelta nella piazza con un nuovo `Interactable` (es. una statua o un NPC) che apre una finestra, come il portale.

---

## 4. Altri contenuti rapidi

### 4.1 Equipaggiamento

1. Icona `icon_<id>` a 64 px in `sprites.py`.
2. `data/equipment/<id>.tres` (`EquipmentData`): `id` (nel salvataggio), nome, descrizione, `slot` (`WEAPON` o `ACCESSORY`), `icon`, `modifiers` (lista di `StatModifier`: `stat`, `amount`, `is_multiplier`).
3. Aggiungilo a `data/equipment/equipment_catalog.tres`: gli oggetti posseduti il cui oggetto base non è nel catalogo vengono scartati al caricamento del salvataggio. Da M11 ogni oggetto posseduto è un'istanza con rarità e bonus propri (GDD §6.0).

### 4.2 Ricetta del fabbro

`data/recipes/<id>.tres` (`RecipeData`): `result` = l'equipaggiamento, `costs` = righe `MaterialCost` (materiale + quantità). Poi aggiungila a `data/recipes/recipe_book.tres`. Ogni pezzo si crafta una sola volta.

### 4.3 Potenziamento di level-up

`data/upgrades/<id>.tres` (`UpgradeData`): nome, descrizione, `stat`, `amount`, `is_multiplier`, `weight` (frequenza di comparsa). Poi aggiungilo a `data/upgrades/upgrade_table.tres`.

Le stat disponibili sono quelle dell'enum `UpgradeData.Stat` (danno, cadenza, velocità e durata del proiettile, velocità, HP, raggio magnete, exp, drop, i-frames, knockback, numero di proiettili, perforazione). **Una stat nuova è codice** (§6).

### 4.4 Suono

1. Sintetizzalo in fondo a `tools/audio.py` con `save("<id>", segnale, gain)`.
2. Aggiungi una voce `SoundEntry` (id, stream, volume) a `data/audio/sound_bank.tres`.
3. Collega il suono a un **segnale** nella composition root (`arena.gd` o `hub.gd`) con `_sfx.play(&"<id>")`. Mai dalle entità.
4. Aggiungi l'id a `USED_IDS` in `tests/audio/test_sound_bank.gd`.

### 4.5 Punto di interazione nella piazza

1. Aggiungi l'oggetto (sprite + collisione) sotto `World/Props` in `Hub.tscn`, che ordina i nodi per Y.
2. Aggiungi un `Area2D` con script `Interactable` sotto `World`: `collision_layer = 0`, `collision_mask = 2`, `prompt = "E — …"` e `window` → una finestra sotto `UI`.
3. La finestra è un `CenterContainer` con un `PanelContainer` (stile `window_style`) che contiene la scena UI. L'hub gestisce da solo apertura, pausa, focus e chiusura con ESC/E. La logica della finestra (segnali verso `MetaProgression`) va collegata in `hub.gd`.

---

## 4.6 Testi e traduzioni

Ogni testo visibile è una chiave: nel `.tres` o nella scena scrivi la chiave (es. `display_name = "MAT_BONE_SHARD"`), poi aggiungi una riga a `data/i18n/strings.csv` con `keys,it,en,fr,es` (virgolette se il testo contiene virgole). Godot reimporta il CSV da solo. Convenzione dei prefissi: `MAT_` materiali, `EQ_` equipaggiamento (`_DESC` per la descrizione), `UPG_` potenziamenti, `ARENA_` arene, `BOSS_` boss, `STAT_` statistiche, `UI_`/`MENU_`/`PAUSE_`/`OPT_`/`HUD_` interfaccia. I test controllano che ogni chiave usata esista e abbia le 4 lingue.

## 4.7 Catalogo

Ogni abilità, evento, oggetto o achievement nuovo va aggiunto anche a `docs/catalog/catalog.json` (con `source`: `magicraft_steam`/`magicraft_shapes` se l'idea viene da Magicraft, `wanderloot` se originale, e `status`), poi `python3 tools/catalog_pdf.py` rigenera il PDF. È la base dell'enciclopedia in gioco (GDD §13).

## 5. Cose da non fare

- **Non chiamare `MetaProgression.save_to_disk()` dal gameplay**: i salvataggi sono solo manuali (Salva nel menu di pausa → `GameSession.save()`). Per provare contenuti nuovi parti da **Nuova partita** o da un salvataggio di prova.

- **Non cambiare un `id`** di materiale, equipaggiamento o arena già usato: i salvataggi dei giocatori lo referenziano.
- **Non riordinare gli enum** salvati nei `.tres` (`UpgradeData.Stat`, `EnemyData.Behavior`, `EquipmentData.Slot`): voci nuove solo in coda, perché nei `.tres` sono salvati come numeri.
- **Non modificare un `.tres` condiviso a runtime** (es. `stats.max_hp += 1` sul file caricato): lavora su `duplicate()`, come fa `Player.begin_run()`.
- Niente `instantiate()`/`queue_free()` per nemici e proiettili in combattimento: si usano i pool (`activate`/`deactivate`).
- Niente nuove `PointLight2D` per nemico o proiettile: per farli brillare si usa il materiale *unshaded*.
- Non collegare suoni o UI dalle entità: si emette un segnale e lo collega la composition root.

---

## 6. Quando serve codice

| Novità | Dove | Test |
|---|---|---|
| Tipo di attacco del boss | voce **in coda** a `BossAttack.Kind`, rami in `boss.gd`, pattern puri in `scripts/run/boss_patterns.gd` | `tests/run/test_boss_logic.gd` |
| Comportamento di movimento nemico (es. "gira attorno", "carica") | voce **in coda** a `EnemyData.Behavior`, funzione statica pura in `scripts/run/enemy_movement.gd`, ramo in `enemy.gd::_desired_direction()` | sulla funzione statica (modello `keep_distance`) |
| Attacco nemico diverso (es. esplosione a contatto) | nuovo componente-nodo in `scripts/combat/` (composizione), collegato via segnale in `arena.gd` | logica pura del componente |
| Nuova stat per upgrade o equipaggiamento | voce **in coda** a `UpgradeData.Stat`, campo in `PlayerStats` o `WeaponData`, ramo in `StatApplier` | `tests/run/test_stat_applier.gd` |
| Selezione del personaggio | §3.3 | catalogo e salvataggio v4 |
| Nuova regola di sblocco (non solo "N estrazioni in X") | `ArenaData.is_unlocked()` | `tests/data/test_arena_data.gd` |

Prima di scrivere: apri una issue e dichiara lo scope. Dopo: aggiorna GDD e CHANGELOG nello stesso commit, e `BEST_PRACTICES.md` se cambia un pattern.

---

## 7. Dimensioni di riferimento (a schermo = metà del PNG)

| Oggetto | PNG per frame | A schermo |
|---|---|---|
| Player | 96 px | 48 px |
| Slime / Ghoul / Scheletro | 88–96 px | 44–48 px |
| Proiettile, gemma exp, dardo | 32 px | 16 px |
| Icone (materiali, equip) | 64 px | 32 px nell'UI |
| Tile pavimento / muro | 384 / 64 px | 192 / 32 px |
| Arena calpestabile | — | 1600 x 1000 px |
| Piazza dell'hub | — | circa 1720 x 960 px calpestabili, camera con zoom 0,85 |

---

## 8. Bilanciamento (fine tuning) dall'editor

Tutti i numeri del gioco stanno nei `.tres`: si aprono con doppio clic nel FileSystem di Godot e si cambiano nell'**Inspector** (salvataggio con Ctrl/Cmd+S). Non serve toccare codice. Metodo consigliato:

1. Cambia **un valore alla volta** (o un gruppo coerente).
2. Misura col bot prima e dopo, stessa configurazione: `godot --headless --fixed-fps 60 --path . -s tools/autoplay.gd -- 10 arena=crypt` (aggiungi `boss` per restare a combattere il boss, gli id di equipaggiamento per provarlo).
3. Prova a mano: il bot schiva meglio di un giocatore e sceglie sempre i potenziamenti di combattimento.
4. Annota nel GDD (§10) il valore e il risultato, e aggiungi una riga al CHANGELOG.

I test in `tests/data/` controllano alcuni vincoli (es. i cerchi dei boss e dei fulmini sono sempre evitabili a velocità base): se un test fallisce dopo una modifica, il valore rompe una regola di gioco.

### 8.1 Player e livelli

| Cosa | File | Campo | Attuale | Effetto |
|---|---|---|---|---|
| Vita | `data/player/player_default.tres` | `max_hp` | 10 | HP a inizio run |
| Velocità | idem | `move_speed` | 220 | px/s; è anche il riferimento per i test dei cerchi |
| Invulnerabilità dopo un colpo | idem | `invulnerability_time` | 0,8 s | |
| Raggio del magnete | idem | `pickup_radius` | 90 | px da cui exp e oggetti volano verso il player |
| Bonus exp / drop / Contatore | idem | `exp_multiplier`, `drop_chance_multiplier`, `count_bonus` | 1 / 1 / 0 | valori di partenza (li alzano potenziamenti ed equip) |
| Danno, cadenza, proiettili | `data/weapons/starter_wand.tres` | `damage`, `fire_rate`, `projectile_count`, `spread_degrees`, `pierce` | 1, 4/s, 1, 10°, 0 | arma di partenza |
| Gittata | idem | `projectile_speed`, `projectile_lifetime` | 650, 1 s | distanza = velocità × durata |
| Spinta dei colpi | idem | `knockback` | 320 | |
| Exp per livello | `data/run/level_curve.tres` | `base_exp`, `growth` | 5, 1,35 | exp per il livello N = base × growth^(N−1): growth più alto = livelli più lenti |
| Scelte al level-up | `scenes/run/Arena/Arena.tscn` (nodo Arena) | `choices_per_level` | 3 | |

### 8.2 Potenziamenti di level-up

File in `data/upgrades/`, elenco in `upgrade_table.tres`. Per ciascuno: `amount` (quanto aggiunge), `is_multiplier` (vero = moltiplica, es. 1,2 = +20%), `weight` (frequenza di comparsa rispetto agli altri: 0,5 = metà delle volte). Ventaglio, Perforazione e Contatore hanno peso 0,6/0,6/0,5 perché cambiano molto la potenza. Il Contatore potenzia i Ventagli presi dopo (GDD §3.1).

### 8.3 Nemici

File in `data/enemies/` (`enemy_basic` = Slime, `ghoul`, `skeleton_archer`).

| Campo | Effetto | Slime / Ghoul / Arciere |
|---|---|---|
| `max_hp` | colpi necessari (con danno 1) | 3 / 2 / 3 |
| `contact_damage` | danno a contatto | 1 / 1 / 1 |
| `move_speed` | px/s (il player ne fa 220) | 110 / 175 / 95 |
| `exp_reward` | exp della gemma | 1 / 1 / 2 |
| `contact_knockback`, `knockback_resistance` | spinta data / resistenza a quella ricevuta (0–1) | |
| `rage_after`, `rage_speed_multiplier`, `rage_damage_bonus` | dopo quanti secondi in vita vanno in rage, quanto accelerano, danno in più (0 = niente rage) | 5 s ×1,8 +1 / 4 s ×1,25 +1 / 5 s |
| `drops` | materiali: `chance` 0–1, `min_amount`/`max_amount` | Slime: Gelatina 20%, Nucleo 1,5% |
| `ranged_weapon`, `attack_interval`, `attack_range`, `preferred_distance` | solo nemici a distanza (arciere: `data/weapons/skeleton_bow.tres` per danno e velocità del dardo) | |

Regola: un nemico in rage non dovrebbe superare la velocità del player (`move_speed × rage_speed_multiplier` < 220), altrimenti non si può scappare.

### 8.3b Slime della Cripta e proiettili speciali

| Cosa | File | Campi |
|---|---|---|
| Slime tossico / del vuoto / di pietra | `data/enemies/slime_toxic.tres`, `slime_void.tres`, `slime_stone.tres` | `max_hp` (6 / 6 / 12), `move_speed` (110 / 110 / 55), `attack_interval`, `attack_range` |
| Frequenza | `data/arenas/crypt.tres` → `enemies` | `weight` (celeste 1, tossico 0,18, vuoto 0,15, pietra 0,22), `min_time` (30 / 45 / 20 s) |
| Veleno | `WeaponData` gruppo *Veleno* | `poison_duration`, `poison_interval`, `poison_damage` |
| Buco nero | `WeaponData` gruppo *Buco nero* | `grow_after` (px), `grow_scale`, `grown_speed_multiplier`, `pull_radius`, `pull_strength` |

### 8.4 Ondate e numero di mostri

File in `data/waves/` (`wave_default` = Cripta, `wave_ossuary`), assegnati in `ArenaData.wave_data`.

| Campo | Effetto | Cripta / Ossario |
|---|---|---|
| `start_interval`, `min_interval`, `interval_decay` | secondi tra un gruppo e l'altro: parte da start, scende di decay ogni secondo fino a min | 2 → 0,5 (−0,008/s) / 1,6 → 0,45 (−0,01/s) |
| `start_batch`, `batch_growth_period` | mostri per gruppo: +1 ogni N secondi | 1, +1 ogni 40 s / ogni 35 s |
| `max_alive`, `max_alive_growth`, `max_alive_growth_period` | tetto dei mostri vivi: parte bassa e cresce di growth ogni period secondi fino a max | 45 (+5 ogni 30 s) / 55 (+6 ogni 30 s) |
| `late_start`, `late_interval_multiplier`, `late_max_alive_bonus` | fase avanzata: dal secondo late_start gruppi più ravvicinati e tetto più alto | 60 s, ×0,6, +20 / 50 s, ×0,55, +25 |
| Tipi di nemici | `data/arenas/<arena>.tres` → `enemies` (`weight` = frequenza, `min_time` = da che secondo) | Ossario: Ghoul 1, Arciere 0,3 dal 15° s |

### 8.5 Estrazione

File in `data/run/` (`extraction_default` = Cripta, `extraction_ossuary`): `appear_after` (secondi prima che compaia la zona: 120), `channel_time` (secondi da restare dentro: 6 / 7), `decay_rate` (quanto scende il progresso se esci), `spawn_min_distance` (distanza minima dal player).

### 8.6 Boss

| Cosa | File | Campo | Attuale |
|---|---|---|---|
| Quando compare | `data/arenas/<arena>.tres` | `boss_delay` (s dopo l'apertura dell'estrazione) | 20 |
| **Quanti boss** | idem | `boss_count` | 1 (+1 per ogni Pentagramma superato) |
| Distanza tra boss / dal player | idem | `boss_min_separation`, `boss_spawn_min_distance` | 350 / 380 |
| Vita, velocità, contatto, exp | `data/bosses/king_slime.tres` | `max_hp`, `move_speed`, `contact_damage`, `exp_reward` | 400, 80, 2, 40 |
| Drop | idem | `drops` | Gelatina 12–18, Nuclei 3–5 (garantiti) |
| Ritmo | idem | `first_attack_delay`, `chase_time` | 2,5 s, 1,4 s |
| Fase 2 | idem | `phase_two_threshold`, `phase_two_speed_multiplier`, `phase_two_tempo_multiplier` | 50% HP, ×1,25, ×0,7 |
| Attacchi | `data/bosses/attacks/king_slime_*.tres` | `weight`, `telegraph_time`, `recovery`, `projectile_count`, `repeats`, `radius`, `damage` | vedi GDD §5.1 |
| Proiettili del boss | `data/weapons/king_slime_goo.tres` | `damage`, `projectile_speed`, `projectile_lifetime` | 1, 220, 3 s |

### 8.5b Overtime

`data/run/overtime_default.tres` (assegnato in `ArenaData.overtime`, vuoto = niente overtime): `start_after` (50 s dall'apertura dell'estrazione), `level_every` (50 s), `warnings` (30, 10), `boss_interval` (10 s, diviso per il livello), `min_boss_interval` (2 s), `speed_multiplier` (x2, per livello), `hp_bonus` (+25%, per livello), `spawn_raged`. Per misurarlo: `tools/autoplay.gd -- N stay` (il bot non estrae mai) e guardare `death_times`.

### 8.7 Eventi

Tempi in `data/arenas/<arena>.tres` → `event_times` (Cripta 35 e 80 s), `events` (quali eventi possono uscire) e `boss_event_delay` (evento in più 10 s dopo aver sconfitto tutti i boss; negativo = nessuno).

| Evento | File | Campi principali | Attuale |
|---|---|---|---|
| Tempesta di fulmini | `data/events/lightning_storm.tres` | `duration`, `strike_interval`, `strike_telegraph`, `strike_radius`, `strike_damage`, `aimed_chance`, `reward_choices` | 10 s, 0,55 s, 0,8 s, 70 px, 1, 35%, 3 abilità |
| Passo d'ombra | `data/events/shadow_step.tres` | `duration`, `dash_charges`, `dash_recharge`, `dash_speed`, `dash_duration` (= invulnerabilità), `reward_choices` | 10 s, 6, 2 s, 850 px/s, 0,2 s, 3 abilità |
| Pentagramma di sangue | `data/events/blood_pentagram.tres` | `activation_timeout`, `duration`, `candle_count`, `circle_radius`, `monster_bonus`, `spawn_raged`, `bonus_bosses` | 20 s, 15 s, 15, 110 px, +30%, sì, +1 boss |

### 8.7b Rarità e bonus dell'equipaggiamento

| Cosa | File | Campi |
|---|---|---|
| Rarità | `data/equipment/rarity_table.tres` | per ogni rarità: `affix_count`, `roll_min`/`roll_max` (qualità 0–1 dei tiri), `ability_count`, `drop_weight` (tra gli oggetti trovati), `salvage_multiplier`, `color`, `drop_sound` (id del banco suoni), `glow_scale` (alone a terra) |
| Bonus possibili | `data/equipment/affix_table.tres` | `stat`, `min_value`/`max_value` (moltiplicatori es. 1,05–1,25), `is_multiplier`, `slots` (tipi di oggetto ammessi, vuoto = tutti), `weight` |

### 8.7c Oggetti trovati in run

Ogni arena ha `item_drops` (`data/equipment/drops_<arena>.tres`, script `ItemDropTable`): `items` (oggetti base possibili, anche senza ricetta), `drop_chance`, `max_tier`, `boss_drops`, `boss_min_tier`. Per un oggetto nuovo trovabile in run basta aggiungerlo alla lista `items` della tabella dell'arena; la rarità segue i `drop_weight` di `rarity_table.tres`.

### 8.7d Fusione e smontaggio

Resa dello smontaggio: `salvage_multiplier` in `rarity_table.tres` e `SALVAGE_SHARE` in `scripts/meta/forge.gd` (25 % del costo della ricetta). Rarità massima per fusione: la penultima della tabella (`Forge.max_fusion_tier`). Un oggetto senza ricetta rende `FALLBACK_SALVAGE` × moltiplicatore.

### 8.8 Loot, consumabili e abilità

| Cosa | File | Campo | Attuale |
|---|---|---|---|
| Drop dei materiali | `data/enemies/*.tres` → `drops` | `chance`, quantità | vedi §8.3 |
| Consumabili | `data/consumables/consumable_table.tres` | `drop_chance` (per uccisione), `weight` di ciascuno | 1,2%; Magnete 1, Cuore 1, Furia 0,8 |
| Durata ed effetto | `data/consumables/*.tres` | `duration`, `amount` | Magnete 4 s; Cuore 2 HP; Furia ×1,5 per 6 s |
| Abilità | `data/abilities/*.tres` | `every_shots`, `every_distance`, `cooldown` e i campi dell'effetto (`count`, `damage_bonus`, `radius`, `range`) | Anello 8 colpi/10 proiettili; Fulmine 350 px/+2 danno; Barriera 12 s |
| Ricette del fabbro | `data/recipes/*.tres` | `costs` | GDD §7 |
