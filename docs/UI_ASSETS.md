# UI — asset, specifiche e concept (reskin HUD e menu)

Documento operativo per il reskin di tutta la UI (HUD, menu, finestre). Aggiornarlo quando cambia un elemento
della UI o il suo tipo di tema. Decisioni prese (M13, #86):

- **Higgsfield solo per i concept.** Le immagini generate sono riferimenti visivi, non asset di gioco: gli asset
  finali si ridisegnano in SVG (`assets/art/ui/`, generati da `tools/sprites.py` come il resto) ed esportati in
  PNG a 2x (`assets/sprites/ui/`). Resta valida la regola di BEST_PRACTICES §3.1.0 (sorgente SVG, niente mix
  raster/vettoriale).
- **Direzione artistica: gotico cupo oro/viola**, evoluzione della palette attuale (Cripta/Ossario).
- **Un solo punto di aggancio: il tema** `data/ui/wanderloot_theme.tres`. Ogni elemento ha un tipo di tema
  (colonna "Tipo" sotto); il reskin sostituisce gli `StyleBoxFlat` di quel tipo con `StyleBoxTexture`
  (9-slice), senza toccare scene o script. Guardia: `tests/ui/test_ui_theme.gd`.

## 1. Flusso di lavoro

1. **Concept** (tu, Higgsfield): prima il foglio di stile generale (§4.1), poi i dettagli per famiglia
   (§4.2). Salva le immagini scelte in `docs/concepts/ui/` con il nome dell'elemento (es. `window_panel.png`).
2. **Ridisegno** (io): per ogni elemento leggo il concept e ne ricavo sagoma, ornamenti e toni, poi scrivo
   l'SVG con le misure di §3. Dal concept non si copia la resa pittorica: si traduce in forme piatte.
3. **Aggancio** (io): PNG 2x → `StyleBoxTexture` del tipo di tema, margini 9-slice di §3. Test del tema e
   dimensioni delle finestre (`tests/scenes/hub/test_*`) devono restare verdi.
4. **Verifica**: screenshot prima/dopo di hub, HUD in run, menu, fine run.

## 2. Palette (valori attuali, base del reskin)

| Ruolo | Colore | Uso |
|---|---|---|
| Fondo finestra | `#1A1724` | pannelli, slot |
| Fondo scuro | `#120F1A` | tooltip, fine run |
| Oro | `#C79E5C` | bordi, maniglie, titoli |
| Oro chiaro | `#D9B359` | bordo evidenziato (fine run) |
| Vita | `#DB3340` | barra HP |
| Mana | `#40BFF2` | barra mana |
| Exp / evento | `#408CFF` | barra exp, avanzamento evento |
| Boss | `#9E33D9` | barra boss |
| Testo | `#F2F2FF` | etichette |

Rarità (bordo degli oggetti, da `rarity_table.tres`): Comune `#B8B8B8`, Non comune `#5CD16B`, Raro `#4A8FD1`,
Super raro `#B05CD6`, Leggendario `#F0A130`, Mitico `#E8423B`. Le cornici degli oggetti si disegnano **chiare
e neutre** e prendono il colore della rarità dal codice (`UiTheme.tint`, `StyleBoxTexture.modulate_color`):
un solo asset per tutte le rarità.

## 3. Elementi e specifiche degli asset finali

Misure a schermo (risoluzione base 1280x720); il PNG è a 2x. "9-slice" = margini in px a schermo
dell'angolo non deformabile; il centro e i lati devono potersi ripetere/stirare senza artefatti.

| Elemento | Tipo di tema | Dove | Misura a schermo | 9-slice | Stati / note |
|---|---|---|---|---|---|
| Finestra | `WindowPanel` | inventario, fabbro, portale, mappa, opzioni, tutorial, armadio | variabile (fino a 1220x620) | 24 | angoli decorati, centro pieno scuro |
| Finestra evidenziata | `WindowPanelHighlight` | fine run | variabile | 28 | variante più ricca della finestra |
| Tooltip | `TooltipPanel` | ovunque | variabile | 12 | sobrio, leggibile sopra tutto |
| Slot oggetto | `ItemSlot` | baule, loot, armadio, fine run | 64x64 | 12 | normal / hover / pressed; cornice chiara tintabile |
| Slot vuoto manichino | `EmptySlot` | manichino | 60x60 | 10 | una sola immagine, più spenta |
| Badge | `BadgePanel` | cestino sugli slot | ~22x22 | 4 | |
| Evidenziazione opzione | `OptionHighlight` | opzioni | variabile | 6 | |
| Barra vita | `HpBar` | HUD | 220x12 | 4 (sx/dx) | `background` (vuota) + `fill` (piena), stessa sagoma |
| Barra mana | `ManaBar` | HUD | 220x8 | 3 | come sopra |
| Barra exp | `ExpBar` | HUD | 220x8 | 3 | come sopra |
| Barra evento | `EventBar` | banner evento | variabile x8 | 3 | come sopra |
| Barra boss | `BossBar` | HUD in alto | ~600x14 | 6 | più decorata, teschi/rune agli estremi |
| Porte dell'armadio | `ClosetDoorLeft/Right`, `ClosetHandle` | evento Scheletri | variabile | 8 | legno scuro, maniglia oro |
| Bottone | base `Button` | menu, pausa, fine run, tutorial | variabile x~40 | 10 | normal / hover / pressed / disabled / focus |
| Carta level-up | da creare: `UpgradeCard` | scelta potenziamento | 220x110 | 16 | normal / hover / pressed / focus |
| Carta abilità | da creare: `AbilityCard` | scelta abilità | 250x150 | 16 | come sopra, più ricca |
| Schede | base `TabContainer` | inventario, fabbro | tab ~120x32 | 8 | selezionata / non selezionata / hover |
| Menu a tendina | base `OptionButton` | filtro baule, lingua | variabile x32 | 8 | come bottone + freccia |
| Casella | base `CheckBox` | opzioni | 20x20 | — | vuota / spuntata |
| Cursore volume | base `HSlider` | opzioni | variabile x8 | 3 | binario + pomello 16x16 |
| Barra di scorrimento | base `VScrollBar` | liste | 8 x variabile | 3 | |
| Slot abilità HUD | da creare: `AbilitySlot` | barra abilità in run | 36x36 (+cornice) | 8 | cornice + riempimento dal basso (già `TextureProgressBar`) |
| Minimappa | da creare: cornice minimappa | HUD in alto a destra | cerchio ~160 | — | anello con N/S/E/O, oggi disegnata in codice |
| Slot arma HUD | `WeaponSlot` | HUD, accanto alle abilità | 56x56 | 10 | cornice chiara tintata con la rarità (oro senza arma); icona dell'arma o `icon_starter_wand` |

"Da creare" = oggi è un `Button`/`Control` generico o disegnato in codice: il tipo si aggiunge al tema quando
arriva l'asset.

## 4. Prompt per i concept (Higgsfield)

Scrivi i prompt in inglese (i modelli rendono meglio). Usa **la stessa immagine di riferimento/stile per tutte
le generazioni** (la prima tavola che ti convince, §4.1), così le famiglie restano coerenti. Per ogni elemento
genera 3-4 varianti e scegline una.

**Stile comune** (da mettere in coda a ogni prompt):

> dark gothic fantasy game UI, burnished antique gold trim on deep violet-black panels, subtle arcane runes,
> crypt and ossuary mood, clean flat vector shapes, 2-3 tones per material, crisp dark outlines, symmetrical,
> front orthographic view, no perspective, plain dark background, no text, no letters, no numbers

**Negativo** (se lo strumento lo prevede):

> photorealistic, 3D render, noise, grain, heavy texture, blur, bloom, lens flare, perspective, text, watermark,
> logo, characters, busy background

### 4.1 Tavola di stile (una volta sola, 16:9)

> game UI kit sheet on a single board: one large window frame, a tooltip frame, a row of square item slots,
> an empty equipment slot, three thin horizontal bars (health red, mana cyan, experience blue), a wide boss
> health bar with skull ornaments, two buttons (normal and highlighted), a tab strip, a small round minimap
> frame with compass letters removed, laid out on a grid with space between elements + stile comune

### 4.2 Dettagli per famiglia (1:1 salvo dove indicato)

| File concept | Prompt (prima dello stile comune) |
|---|---|
| `window_panel.png` | ornate rectangular window frame for an inventory screen, decorated corners with small gothic spikes and a gem, thin straight repeating edges, empty flat dark center |
| `window_panel_highlight.png` | richer version of the same window frame for a victory/results screen, larger corner ornaments, faint golden glow on the border, empty dark center |
| `tooltip.png` | small minimal tooltip frame, thin gold line border, tiny corner rivets, empty dark center |
| `item_slot.png` | square inventory slot frame, three states side by side: idle, hovered (brighter rim), pressed (inset), **light neutral grey-gold frame** so it can be tinted, empty dark center |
| `empty_slot.png` | dim square equipment slot, worn stone texture look in flat shapes, faint engraved outline, empty center |
| `bars.png` (16:9) | three thin horizontal resource bars, each shown empty and full: health deep red, mana cyan, experience blue, gold metal caps at both ends, flat fill, rounded ends |
| `boss_bar.png` (16:9) | wide boss health bar, dark iron frame with small skulls and thorns at both ends, violet fill, shown empty and full |
| `buttons.png` | medieval button set in four states side by side: normal, hover (gold rim brighter), pressed (inset darker), disabled (desaturated), wide rectangle with small corner ornaments |
| `cards.png` (16:9) | two reward card frames: a level-up upgrade card and a larger rare ability card, tarot-like proportions but wider than tall, ornate gold border, dark violet body, empty space for icon and text |
| `tabs.png` | tab strip with one selected tab (gold, raised) and two unselected tabs (dark, flat), attached to the top edge of a panel |
| `widgets.png` | UI widget set: dropdown box with small arrow, checkbox empty and checked, volume slider track with round gold knob, thin vertical scrollbar |
| `ability_slot.png` | small square ability icon frame for the action bar, gold rim with rune notches, dark inner area |
| `weapon_slot.png` | square weapon display slot for the HUD, slightly larger and more ornate than the ability slot, crossed-wand motif on the corners, dark inner area |
| `minimap_frame.png` | round minimap frame, gold ring with four small compass notches, dark translucent inner disc |
| `closet.png` | pair of dark wooden wardrobe doors with gold handles, gothic carvings, closed, front view |
| `hud_mockup.png` (16:9) | full game HUD mockup over a dark top-down dungeon: health/mana/experience bars top-left, ability slots and weapon slot below them, round minimap top-right, boss bar top-center; shows placement and proportions only |

## 5. Stato

| Fase | Stato |
|---|---|
| Stili centralizzati nel tema (tipi sopra, aspetto invariato) | ✅ M13 #86 |
| Concept Higgsfield | da fare (Daniele) |
| Ridisegno SVG + aggancio al tema | da fare dopo i concept |
| Slot arma in HUD (nuovo elemento) | ✅ M13 #86 (stile provvisorio, reskin con gli altri) |
