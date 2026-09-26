# Patch Notes (beta)

Note in linguaggio semplice per i beta tester. Ogni versione elenca solo cosa cambia rispetto alla precedente. Le note tecniche complete sono in `docs/CHANGELOG.md`.

## e72df9b — 26/09/2026

### Correzioni
- Fusione: il tooltip, il tutorial del fabbro e la voce del Codex dicevano ancora "tre oggetti" per fondere un item al tier successivo. Ora dicono correttamente "sei", come il gioco richiede da qualche versione.

### Novità
- Nuova statistica **Mana** (valore assoluto) visibile nella scheda Statistiche, sia in hub che in run.
- Nuovo potenziamento di run **Riserva**: +10% mana massimo. L'aumento si accredita subito al mana attuale, non è un rabbocco gratuito.

## ab6409e — 26/09/2026

### Bilanciamento
- Fusione: serve **sei** oggetti dello stesso tipo e tier (prima tre) per ottenere un pezzo del tier successivo.
- Fabbro: il costo in risorse per craftare ogni pezzo è **triplicato**.
- Raggio magnete (calamita per il loot): il bonus ottenibile da equip e potenziamenti di run è ridotto a **un terzo** di prima.

## 707aeab — 26/09/2026

### Bilanciamento
- Danno e Vita massima: i bonus che prima erano un numero fisso (es. "+1 danno", "+1 HP") ora sono **percentuali** (es. "+10% danno", "+10% HP"), sia sui pezzi di equip che sui potenziamenti di run. Stesso principio già usato per la cadenza di fuoco.

## 594be3f — 26/09/2026

### Bilanciamento
- Riscalati danno, vita e esperienza in tutto il gioco (circa x100 rispetto a prima): vita del player, danno delle armi, HP/exp dei nemici e dei boss. È un cambio di scala interno, il gioco si gioca allo stesso modo — serve solo per dare più margine ai numeri futuri.

## In lavorazione — 26/09/2026

### Novità
- Arene **10 volte più grandi** (stessi rapporti di prima, tutto scalato x10: muri, decorazioni, zona di spawn).
- La zona di estrazione non compare comunque mai a più di 1000px dal player, anche su un'arena così grande.

## In lavorazione (2) — 26/09/2026

### Novità
- Mappa dell'arena: premi **M** per aprirla (o Esc per chiuderla). Mostra i confini dell'arena e la tua posizione; i punti di interesse arriveranno in futuro.
- Sulla mappa puoi piazzare fino a **5 indicatori** con un clic: ognuno diventa una freccia colorata a bordo schermo per orientarti verso quel punto (il giallo è riservato al portale di estrazione).
- Nuova **minimappa** in alto a destra durante la run: ti tiene sempre al centro, con una bussola N/S/E/O sul bordo, e mostra i tuoi indicatori e il portale quando è attivo.
- Il tutorial dell'obiettivo di run ora ricorda anche il tasto M.

## In lavorazione (3) — 26/09/2026

### Novità
- Le statistiche a sinistra in run si possono nascondere con un pulsante accanto al titolo, comodo nei combattimenti più affollati.
- Il tutorial e il Codex del Passo d'ombra ora spiegano che durante lo scatto sei invulnerabile e attraversi i nemici senza subire danno.

### Miglioramenti visivi
- L'attacco a carica in linea di alcuni boss ora mostra una striscia rettangolare unica invece di una fila di cerchi separati.

## In lavorazione (4) — 26/09/2026

### Bilanciamento
- I nemici ora compaiono in una fascia di distanza ragionevole dal player (appena fuori vista, ma abbastanza vicini da arrivare in fretta), non più ovunque nell'arena enorme: prima capitava che arrivassero già furiosi solo per la lunga camminata. (aggiustato: 700–1200px di spawn, despawn oltre 1600px)
- Se ti allontani troppo, i nemici rimasti troppo indietro spariscono e vengono sostituiti da altri più vicini a te.

## In lavorazione (5) — 26/09/2026

### Bilanciamento
- Tempo prima che un nemico vada in rage alzato da 5 a 10 secondi (in linea con le arene più grandi): prima molti arrivavano già furiosi solo per la camminata dal punto di spawn.

## In lavorazione (6) — 26/09/2026

### Verifiche
- Controllato il tiro casuale delle statistiche dell'equipaggiamento (es. Guanti del fabbro): funziona correttamente, gli affissi variano tra un drop e l'altro. Aggiunto un test per tenerlo d'occhio in futuro.
- Controllato il raggio d'azione del Magnete: attira già tutto ciò che è a terra nell'arena a prescindere dalla distanza. Aumentata solo la velocità con cui gli oggetti arrivano, per non farli aspettare troppo su arene enormi.

### Novità
- Le icone di Magnete, Cuore e Furia, quando droppati a terra, compaiono anche su mappa e minimappa finché non li raccogli.

## In lavorazione (7) — 26/09/2026

### Novità
- Evento Pentagramma di sangue ripensato: niente più comparsa a caso durante la run. Ora, fin dall'inizio, da qualche parte nell'arena trovi un pentagramma con le candele spente e una statua di demone al centro — visibile anche su mappa e minimappa, così sai dove andare. Avvicinati e premi E: la statua sparisce e le candele si accendono. Restano accese per un po', poi iniziano a spegnersi una al secondo mentre i mostri si fanno più numerosi e aggressivi: resta nel cerchio finché non si spegne l'ultima, uscire fa fallire l'evento. Il cerchio è anche più grande di prima.

## In lavorazione (8) — 26/09/2026

### Novità
- Vicino alla statua del Pentagramma ora compare la scritta "E — Interagisci", così è chiaro cosa fare.
- Aprendo la mappa: clic destro cancella l'indicatore sotto il cursore, la legenda in basso lo spiega insieme agli altri comandi; gli indicatori sono ora dei triangoli (la tua posizione resta un cerchio); passando il cursore sulla statua del Pentagramma o su Cuore/Furia/Magnete a terra compare il loro nome.

### Correzioni
- La finestra dell'inventario di run (tasto I) non sborda più dallo schermo su finestre piccole.
- Il pezzo scelto dall'armadio degli Scheletri ora compare indossato sul manichino nell'inventario di run, non più nel mucchio del loot raccolto — resta comunque a rischio: si perde se muori, diventa tuo solo estraendo.

### Bilanciamento
- Con il Ventaglio, il mana consumato per colpo è ora maggiore rispetto allo sparo singolo (proporzionale al numero di proiettili).
