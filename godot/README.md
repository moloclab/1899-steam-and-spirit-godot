# 1899 — Steam & Spirit · Base EP01

Progetto per **Godot 4.7.2 standard / GDScript**, renderer Compatibility.
Non richiede .NET, Docker o un server web. L'originale in `../EP01` resta il riferimento.

## Avvio

1. Avvia `C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe`.
2. Importa `project.godot` in questa cartella.
3. Premi **F5 nell'editor** per avviare il gioco.

```powershell
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe' --editor --path 'C:\htdocs\_OLD\_GAMES\1899\godot'
```

## Cosa è giocabile

- Cabina con grafica e animazioni originali.
- Esame, raccolta di Bourbon, penna e calamita, combinazione della penna magnetica.
- Enigma del lavandino, recupero della chiave e apertura della porta.
- Apertura con quattro battute e posa seduta; versamento del Bourbon in tre battute e uscita dopo la battuta sulla porta, con posa di spalle.
- Corridoio con scorrimento e ritorno alla cabina, conservando i progressi.
- Conversazione dell'interfono in battute successive, con Churchill e Kelvin distinti.
- Inventario scorrevole, accessibile anche col focus di tastiera e controller.
- Un salvataggio manuale locale e menu con istruzioni, caricamento e nuova partita.

Gli altri accessi del corridoio sono segnaposto; la battuta del marinaio resta semplificata.
Effetti, conversazioni a scelta e altre stanze di EP01 devono ancora essere portati.
La lingua predefinita è l'inglese; il pulsante Lingua nel pannello aiuti alterna italiano e inglese.
Le stanze vengono caricate in modo **sincrono**.

## Schermo e mobile landscape

La base logica è **1280 × 720 (16:9)**, definita in `project.godot`.
Lo stretch `canvas_items`, con proporzioni `keep` e scala `fractional`, ingrandisce
o riduce il gioco fino a occupare lo spazio disponibile senza deformarlo.
Gli schermi di proporzioni diverse mostrano bande simmetriche; la pixel art può
avere pixel di ampiezza non uniforme con scale frazionarie.
L'orientamento mobile è landscape. La UI ricava la larghezza dalla base del progetto;
le stanze conservano scala e coordinate, con centraggio o scorrimento già esistenti.
Leggibilità, tocchi e aree sicure di notch e fotocamere richiedono una prova su device reale.

## Comandi

| Azione | Mouse / tastiera | Controller (etichette Xbox) |
| --- | --- | --- |
| Camminare | Clic sul pavimento, A/D o frecce | Levetta sinistra |
| Scegliere un bersaglio | Tab / Maiusc+Tab | RB / LB |
| Stanza ↔ inventario | I | Y |
| Aprire le due scelte | Clic sinistro su oggetto della stanza, persona o uscita | — |
| Agire / selezionare | Mano, bocca o uscita; Invio o Spazio | A |
| Esaminare | Lente; destro o E | X |
| Annullare una selezione | Pavimento o Esc | B |
| Menu comandi / pausa | ? / F1 | Start |
| Avanzare una conversazione | Clic sinistro, Invio o Spazio | A |
| Salva / carica | Dal pannello aiuti | Dal menu |

Nella stanza il tasto sinistro apre il pannello originale con **lente** e **mano/bocca/uscita**.
L'azione parte dopo la scelta e dopo l'avvicinamento di Churchill.

Un clic nell'inventario mostra subito la descrizione e seleziona l'oggetto per l'uso. Per usarlo nella stanza, clicca poi sul bersaglio.
Per combinare: clicca sul primo oggetto e poi sul secondo nell'inventario.
Con tastiera e controller, conferma seleziona direttamente l'oggetto o esegue l'azione.
La cornice dorata identifica il focus da tastiera/controller; il mouse usa il cursore a mano.

Durante una sequenza, movimento e interazioni liberi sono sospesi.
Un clic sinistro avvia la riga successiva, con tutte le sue azioni insieme.
Cammini, attese e animazioni bloccanti proseguono automaticamente al loro completamento.
Il menu mette in pausa anche attese e animazioni. Salva, Carica e Ricomincia sono
disabilitati fino alla fine della sequenza, per evitare salvataggi a metà di un effetto.

**F5 avvia dall'editor; F5/F9 non sono scorciatoie del gioco.**

## Struttura

| Componente | Responsabilità |
| --- | --- |
| `scripts/main.gd` | Collega i componenti, inoltra input e conserva la selezione temporanea |
| `scripts/game_ui.gd` | Controlli, inventario scorrevole, speaker, dialoghi e menu; emette segnali |
| `scripts/game_state.gd` | Inventario, raccolte definitive e progressi per ambito; nessun accesso al disco |
| `scripts/save_store.gd` | Salvataggi versione 3, con episodio, ID univoci e validazione |
| `scripts/world/room_manager.gd` | Sostituzione delle stanze, personaggi, centratura/scorrimento e pausa delle animazioni |
| `scripts/world/room.gd` | Cache degli hotspot, inoltro delle azioni e sincronizzazione dello stato |
| `scripts/world/character.gd` | Movimento e animazioni riutilizzabili per Churchill e altri personaggi |
| `scripts/actions/interaction_controller.gd` | Richiesta di avvicinamento e rivalutazione del bersaglio all'arrivo |
| `scripts/actions/sequence_runner.gd` | Esecuzione ordinata dei passi e attese di conferma/completamento |
| `scripts/hotspot.gd`, `scripts/hotspots/` | Interfaccia comune e comportamenti condivisi: raccolta, uscita e interazione con personaggi |
| `scenes/rooms/epNN_<stanza>.tscn` | Fondale, oggetti, animazioni, interazioni base e definizioni inventario incorporate |
| `scenes/rooms/epNN_<stanza>.gd` | Azioni narrative, conversazioni e aggiornamenti visivi della stanza |
| `scenes/episodes/epNN/` | Scena e script dell'episodio, con configurazione incorporata |
| `scripts/data/` | Tipi di risorsa, cataloghi e schema dei progressi |
| `assets/dictionaries/common/`, `assets/dictionaries/epNN/` | Vocabolario comune (UI inclusa) e testi IT/EN degli episodi |
| `scripts/data/episode_catalog.gd` | Registro degli episodi disponibili |
| `scenes/characters/churchill.tscn` | Personaggio giocante riutilizzabile con animazioni già configurate |

I componenti ricevono stato e dipendenze esplicitamente, senza singleton.
Le risorse descrivono i contenuti e restano condivise; le mutazioni della partita
appartengono a `GameState`. Nessun nodo della stanza viene scritto nel salvataggio.

## Aggiungere contenuti

### Episodi, ID e asset

Ogni episodio ha una cartella `scenes/episodes/epNN/`, con scena `epNN.tscn` e script
`epNN.gd`, come le stanze. Apri la scena, seleziona la radice ed espandi `definition`
nell'Inspector: la risorsa incorporata, basata su `scripts/data/episode_definition.gd`,
contiene ID, stanza e ingresso iniziali, sottofondo, chiavi dell'introduzione e percorso
dei dialoghi. Registra il percorso della scena in `EpisodeCatalog.EPISODES`.
Il catalogo legge la definizione senza istanziare la scena dell'episodio; le stanze
restano indipendenti e vengono istanziate una alla volta dal gestore delle stanze.
La proprietà `starting_episode` di `main.tscn` sceglie l'episodio per avvio e nuova partita.
L'ingresso della stanza definisce anche la posizione iniziale; musica e testi si aggiornano
quando una transizione o un caricamento porta a un altro episodio.

Convenzioni per i contenuti persistenti:

- Stanze e ambiti dei progressi: `epNN_<stanza>`, per esempio `ep01_cabin`.
- Oggetti dell'inventario: `epNN_<stanza_origine>_<oggetto>`, per esempio `ep01_cabin_bottle`.
- Testi dell'episodio: `epNN.<ambito>.<testo>`; risposte condivise: `common.<testo>`.
- Hotspot, nodi e ingressi: ID locali alla stanza, senza prefissi obbligatori.

Gli oggetti riutilizzati mantengono gli ID di origine anche negli episodi successivi.
Il servizio dei testi carica `assets/dictionaries/common/dictionary.json` e il catalogo dell'episodio;
i cataloghi già caricati restano disponibili. I testi della UI usano chiavi `common.ui.*`,
i nomi degli interlocutori `common.speaker.*` (anche nel campo `speaker` dei passi).
Pulsanti e aiuti condividono `texts.language` con i dialoghi e si aggiornano al cambio lingua.
Per un oggetto proveniente da un altro episodio,
la sua chiave carica su richiesta anche il catalogo di origine, senza cambiare episodio attivo.

Gli asset grafici sono organizzati in `assets/graphics/epNN_<stanza_origine>/`,
`assets/graphics/characters/<personaggio>/` e `assets/graphics/ui/` (inclusi i cursori).
Musica e futuri effetti vanno in `assets/audio/music/epNN/` e `assets/audio/sfx/`.
La ripetizione del sottofondo si imposta nelle proprietà di importazione dell'audio.
I file `.import` e `.gd.uid` si conservano in Git; la cache `.godot/` è esclusa.
Anche `tests/` è versionata, mentre `test-output/` contiene solo catture locali escluse.

### Stanze, oggetti e combinazioni

Ogni stanza ha due file in `scenes/rooms/`:

- **`epNN_<stanza>.tscn`**: fondale e nodi degli oggetti, con posizione, ordine di disegno,
  grafica, animazioni, area cliccabile e risposte statiche di esame e interazione.
- **`epNN_<stanza>.gd`**: estende `scripts/world/room.gd` e raccoglie azioni specifiche,
  conversazioni, risposte dipendenti dal progresso e sincronizzazione delle varianti grafiche.

Apri la scena della stanza e modifica direttamente i nodi nell'editor.
Gli oggetti semplici usano `Hotspot`, i raccoglibili `hotspots/collectible.gd`,
i passaggi `hotspots/room_exit.gd`; non occorrono scene o script per singolo oggetto.
Gli oblò condividono i fotogrammi, ma rimangono nodi distinti con ID propri.
Churchill conserva la propria scena riutilizzabile.

La radice contiene `definition` e `inventory_definitions`. L'elenco delle definizioni
inventario include anche oggetti ottenuti da enigmi o combinazioni, come chiave e
penna magnetica. Il catalogo lo legge dalle scene registrate in `RoomCatalog.SCENES`
senza istanziarle. Serializza l'elenco anche quando è vuoto.
Il raccoglibile usa `item_id` per riferirsi alla definizione.

Le combinazioni appartengono all'episodio: `scenes/episodes/ep01/combo.tscn`, con
script `combo.gd`, contiene l'elenco incorporato `combination_definitions`, modificabile
nell'Inspector. Configura `combo_scene_path` nella definizione dell'episodio per
collegare la scena. Il catalogo legge le ricette dagli episodi registrati senza
istanziare nodi: penna e calamita si possono combinare anche fuori dalla cabina.
Ogni ricetta definisce ingredienti, oggetti consumati, risultati e risposta;
le combinazioni comuni restano simmetriche. Un episodio senza scena combo non aggiunge ricette.

Per aggiungere una stanza:

1. Crea scena e script omonimi; lo script estende `scripts/world/room.gd`.
2. Configura la risorsa incorporata `definition`: ID, episodio, percorso, larghezza,
   margine percorribile, quota dei piedi, scala e ingressi nominati.
3. Registra il percorso della scena in `RoomCatalog.SCENES`.
4. Aggiungi i nodi degli oggetti con ID univoci, area e risposte nell'Inspector.
   Churchill si avvicina al bordo dell'area dal proprio lato.
5. Inserisci le definizioni inventario nell'elenco della radice e le eventuali
   ricette nella scena combo dell'episodio.
6. Dichiara i progressi in `ProgressSchema.SCOPES` e usa
   `get_progress(ambito, chiave)` / `set_progress(ambito, chiave, valore)`.

Lo script della stanza riceve `actions(state, hotspot_id, item_id, examining)`.
Delega le interazioni semplici a `super.actions(...)` e restituisce righe
`ActionRow`, ciascuna con azioni `ActionStep`, per quelle specifiche. Gli effetti applicano le mutazioni soltanto
durante l'esecuzione, rivalutando il possesso degli oggetti.
La cabina mostra il modello con `drop_bottle`, `collect_key` e `use_key`.

`sync_from_state(state)` richiama prima la versione comune, che aggiorna anche
gli hotspot nascosti, poi ricostruisce le varianti della stanza.
Le uscite indicano stanza e nome dell'ingresso; le coordinate appartengono alla
destinazione. Le richieste verso nodi nascosti o rimossi vengono scartate.
Gli hotspot vengono registrati una sola volta al caricamento della stanza, anche
se annidati: definiscili nella scena e usa la visibilità per mostrarli o nasconderli.
Gli hotspot creati a runtime non vengono registrati.

### Personaggi e sequenze

Il componente `world/character.gd` gestisce centro orizzontale, altezza, velocità,
animazioni e destinazione. Il marinaio nel corridoio è invece un normale hotspot statico,
con un figlio animato `Visual` e lo stesso avvicinamento ai bordi usato per gli oggetti.
Ogni personaggio ha un `character_id` usato dai passi della sequenza.

Una risorsa `action_sequence.gd` contiene `rows`, una lista di `ActionRow`.
Ogni riga contiene `actions`, una lista di `ActionStep` avviate insieme nello stesso frame.
Nell'Inspector si aggiunge prima la riga, poi le sue azioni: è una matrice con un numero
di colonne variabile per riga. Negli script si costruisce una riga con `Row.of([...])`.

- Ogni passo indica `subject_id`: `player` per Churchill, oppure il `character_id`
  di un altro personaggio o l'`hotspot_id` di un oggetto.
- `SAY`: il soggetto dice `text_key`; voce e posizione della battuta vengono dal suo `speaker_key`.
- `WALK`: il soggetto cammina fino al bordo di `target_hotspot_id`; se vuoto usa `target_x`.
- `ANIMATE`: personaggio, animazione e attesa facoltativa della sua conclusione.
- `WAIT`: durata in secondi.
- `EFFECT`: Callable creato dallo script, per applicare una regola al momento corretto.
- `CHANGE_ROOM`: stanza e ingresso nominato.
- `HIDE`: nasconde il soggetto nella stanza corrente. Per una scomparsa salvata nei progressi
  usa invece `EFFECT` e la sincronizzazione della stanza in `sync_from_state()`.

Le animazioni cicliche devono partire senza attenderne il completamento.
Per parlare e girarsi insieme si mettono `SAY` e `ANIMATE` nella stessa riga.
L'introduzione usa le chiavi dell'episodio e `introduction()` della stanza per aggiungere
la posa seduta alla prima riga e il ritorno in piedi alla chiusura.
Il comando iniziale avvia la prima riga; ogni clic successivo avvia una nuova riga immediata.
Come nel vecchio EP01, se una riga contiene `WALK`, `WAIT` o `ANIMATE` con attesa,
il motore attende tutte le sue azioni bloccanti e poi avvia automaticamente la riga successiva.
Ogni colonna conserva il proprio timer o personaggio: due cammini possono procedere insieme.
I clic durante l'attesa vengono ignorati, senza essere accodati; il menu sospende tutta la riga.
L'ultima riga con `SAY` richiede un clic per chiuderla; le altre righe finali terminano da sole.
`cancel()` ferma tutti i cammini attivi ed elimina le righe future, preservando gli effetti già applicati.
Le righe vuote e le attese nulle avanzano automaticamente. Le risorse restano immutate.
Due azioni di cammino/animazione sullo stesso personaggio sono incompatibili nella stessa riga;
un cambio stanza `CHANGE_ROOM` occupa una riga propria. Le righe invalide vengono annullate prima degli effetti.

Per esempio, nell'Inspector configura tre righe:

| Riga | Azione 1 | Azione 2 |
| --- | --- | --- |
| 1 | `SAY`: Churchill dice la frase 1 | `ANIMATE`: posa `back`, senza attesa |
| 2 | `WALK`: Churchill raggiunge `sink` | — |
| 3 | `SAY`: Churchill dice la frase 2 | — |

La prima riga avvia insieme frase e posa. Un clic avvia il cammino della seconda riga;
all'arrivo parte automaticamente la frase della terza. Un ultimo clic chiude la conversazione.

Le conversazioni senza condizioni sono risorse `conversation` degli hotspot,
configurabili nell'Inspector: `ep01_cabin.tscn` incorpora le quattro righe dell'interfono.
Le conversazioni con regole narrative possono essere costruite nello script della
stanza. Il motore delle sequenze rimane condiviso.

## Salvataggi

Il percorso è `user://game_save.json`, normalmente sotto
`%APPDATA%\Godot\app_userdata\1899 — Steam & Spirit\` su Windows.
Il gioco non carica automaticamente. Ricomincia azzera la partita corrente e conserva il file.

Il formato versione 3 contiene episodio, inventario, raccolte, progressi per ambito, stanza e posizione.
I precedenti formati 1 e 2 non sono supportati: avvia una nuova partita.
Prima di applicare i dati vengono controllati ID, tipi, duplicati, ambiti e intervalli.
I progressi assenti ricevono i valori iniziali, permettendo l'aggiunta di nuovi enigmi.
Il servizio scrive un temporaneo e sostituisce il file solo dopo la scrittura riuscita.

## Verifiche

Adattamento dello schermo e clic attraverso scala e bande, su cinque risoluzioni landscape:

```powershell
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path godot --script res://tests/resolution_test.gd
```

Regressione automatica con la scena reale e input sintetici:

```powershell
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\htdocs\_OLD\_GAMES\1899\godot' --script res://tests/prototype_test.gd
```

Copre cataloghi, ricette, percorso della cabina col solo sinistro, transizioni,
ripresa intermedia, rifiuto dei vecchi formati, file corrotti senza mutazioni parziali,
conversazione con mouse/tastiera/controller, pausa, passi temporizzati, animazioni,
movimento di altri personaggi, hotspot annidati/nascosti/rimossi e inventario scorrevole.
Il file di test è distinto dal salvataggio del giocatore e viene rimosso al termine.

Catture con il renderer reale, da eseguire senza `--headless`:

```powershell
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --path 'C:\htdocs\_OLD\_GAMES\1899\godot' --script res://tests/visual_check.gd --resolution 1280x720
```

Le immagini finiscono in `test-output/`, esclusa da Git e dall'importazione Godot.
I test non sostituiscono una prova con controller fisico o una partita completa di EP01.

Regressione del refactor delle stanze e ripristino degli enigmi:

```powershell
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path godot --script res://tests/room_flow_test.gd
```
