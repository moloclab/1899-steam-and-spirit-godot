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
- Corridoio con scorrimento e ritorno alla cabina, conservando i progressi.
- Conversazione dell'interfono in battute successive, con Churchill e Kelvin distinti.
- Inventario scorrevole, accessibile anche col focus di tastiera e controller.
- Un salvataggio manuale locale e menu con istruzioni, caricamento e nuova partita.

Gli altri accessi del corridoio sono segnaposto; la battuta del marinaio resta semplificata.
Effetti, conversazioni a scelta e altre stanze di EP01 devono ancora essere portati.
La lingua visualizzata è l'italiano; il catalogo conserva anche le traduzioni inglesi.
Le stanze vengono caricate in modo **sincrono**.

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
| Salva / carica | Pulsanti in alto o nel menu | Dal menu |

Nella stanza il tasto sinistro apre il pannello originale con **lente** e **mano/bocca/uscita**.
L'azione parte dopo la scelta e dopo l'avvicinamento di Churchill.

Un clic nell'inventario mostra subito la descrizione e seleziona l'oggetto per l'uso. Per usarlo nella stanza, clicca poi sul bersaglio.
Per combinare: clicca sul primo oggetto e poi sul secondo nell'inventario.
Con tastiera e controller, conferma seleziona direttamente l'oggetto o esegue l'azione.
La cornice dorata identifica il focus da tastiera/controller; il mouse usa il cursore a lente.

Durante una sequenza, movimento e interazioni sono sospesi. Le battute che attendono
una conferma mostrano il suggerimento **Clic / Invio / A per continuare**.
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
| `scripts/world/room.gd` | Cache degli hotspot, anche annidati, con invalidazione dopo aggiunte e rimozioni |
| `scripts/world/character.gd` | Movimento e animazioni riutilizzabili per Churchill e altri personaggi |
| `scripts/actions/interaction_controller.gd` | Richiesta di avvicinamento e rivalutazione del bersaglio all'arrivo |
| `scripts/actions/sequence_runner.gd` | Esecuzione ordinata dei passi e attese di conferma/completamento |
| `scripts/hotspot.gd`, `scripts/hotspots/` | Interfaccia comune e comportamenti condivisi: raccolta, uscita e interazione con personaggi |
| `scenes/objects/epNN_<stanza_origine>_<oggetto>/` | Scena e script di ciascun oggetto, con grafica, configurazione e risorse incorporate |
| `scenes/rooms/` | Sfondo, metadati della stanza e posizionamento delle istanze degli oggetti |
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
`epNN.gd`, come gli oggetti. Apri la scena, seleziona la radice ed espandi `definition`
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
Pulsanti, aiuti e tooltip condividono `texts.language` con i dialoghi e si aggiornano al cambio lingua.
Per un oggetto proveniente da un altro episodio,
la sua chiave carica su richiesta anche il catalogo di origine, senza cambiare episodio attivo.

Gli asset grafici sono organizzati in `assets/graphics/epNN_<stanza_origine>/`,
`assets/graphics/characters/<personaggio>/` e `assets/graphics/ui/` (inclusi i cursori).
Musica e futuri effetti vanno in `assets/audio/music/epNN/` e `assets/audio/sfx/`.
La ripetizione del sottofondo si imposta nelle proprietà di importazione dell'audio.
I file `.import` e `.gd.uid` si conservano in Git; la cache `.godot/` è esclusa.
Anche `tests/` è versionata, mentre `test-output/` contiene solo catture locali escluse.

### Oggetti e combinazioni

Ogni oggetto ha una cartella in `scenes/objects/epNN_<stanza_origine>_<oggetto>/`, con due file:

- **`<oggetto>.tscn`**: grafica, area cliccabile, nome e configurazione. Le risorse
  specifiche (dati inventario, conversazioni, fotogrammi, ricette) sono incorporate.
- **`<oggetto>.gd`**: comportamento. Gli oggetti semplici ereditano quello comune;
  gli enigmi ridefiniscono `examine`, `interact`, `use_item` o `actions`.

Esempio: `ep01_cabin_bed/bed.tscn`. Gli oggetti riutilizzati conservano episodio e
stanza di origine. Le scene delle stanze seguono `scenes/rooms/epNN_<stanza>.tscn`.

Per modificare un oggetto, apri la sua scena. Per collocarlo, trascina quella scena
nella stanza e imposta posizione e ordine di disegno. Non occorre rendere modificabili
i figli dell'istanza: modifica grafica e configurazione nella scena originale.
Le due istanze dell'oblò condividono `porthole.tscn` e hanno ID distinti nella stanza.

1. Crea la scena dell'oggetto con uno script che estende `Hotspot`, oppure uno dei
   comportamenti comuni in `scripts/hotspots/`.
2. Configura ID, nome, area e risposte nell'Inspector della scena dell'oggetto.
   L'avvicinamento usa i bordi di `hit_size`: Churchill si ferma a sinistra o a destra in base alla propria posizione,
   con il suo bordo a contatto con quello dell'oggetto. Se è già dentro l'area, sceglie il bordo più vicino.
   La destinazione rimane entro i limiti percorribili della stanza.
3. Se compare nell'inventario, crea una risorsa interna `ItemDefinition` nel campo
   `inventory_definition`, con ID, icona e chiavi dei testi. Abilita `collectible`
   per gli oggetti raccoglibili; registra il percorso della scena in `ItemCatalog.SCENES`.
4. Per una combinazione, configura `combination_definition` nella scena dell'oggetto
   risultante e registrala nel getter `ItemCatalog.RECIPES`. Vedi `magnet_feather.tscn`.
5. Aggiungi i testi IT/EN in `assets/dictionaries/epNN/dictionary.json`, con chiavi `epNN.<ambito>.<testo>`.

Il catalogo legge i dati incorporati senza istanziare l'oggetto e senza caricare la
stanza: inventario e salvataggi restano disponibili anche dopo averla lasciata.
Calamita, chiave e penna magnetica hanno una propria scena anche se vengono ottenute
da un altro hotspot o da una combinazione; la mappa rimane un oggetto distinto.

Le combinazioni comuni sono simmetriche. Una regola narrativa particolare può
specializzare `apply(state)`, senza ampliare un elenco di condizioni in `GameState`.

### Stanze e progressi

1. Crea una scena con radice `Node2D` e script `world/room.gd`.
2. Crea una risorsa interna `data/room_definition.gd` nel campo `definition` della radice.
3. Imposta ID univoco (`ep01_cabin`), episodio (`ep01`), percorso della scena, larghezza, margine percorribile, quota dei piedi,
   scala e ingressi nominati. Registra il percorso della scena in `RoomCatalog.SCENES`.
4. Le uscite indicano stanza e **nome dell'ingresso**; le coordinate appartengono alla destinazione.
5. Dichiara valori iniziali e intervalli dei progressi in `ProgressSchema.SCOPES`.
   Lo schema attuale gestisce flag booleani e stadi interi.
6. Leggi/scrivi con `get_progress(ambito, chiave)` e `set_progress(ambito, chiave, valore)`.

Gli hotspot hanno ID univoci nella propria stanza e possono essere annidati in contenitori.
`sync_from_state()` aggiorna immagini e visibilità anche dei nodi nascosti.
Per un oggetto semplice bastano le risposte nell'Inspector della sua scena; per un enigma
modifica il suo script, mantenendo l’interfaccia comune di `Hotspot`.
Le richieste verso nodi rimossi, in eliminazione o nascosti da un antenato vengono scartate.

### Personaggi e sequenze

Il componente `world/character.gd` gestisce centro orizzontale, altezza, velocità,
animazioni e destinazione. Il marinaio nel corridoio è invece un normale hotspot statico,
con un figlio animato `Visual` e lo stesso avvicinamento ai bordi usato per gli oggetti.
Ogni personaggio ha un `character_id` usato dai passi della sequenza.

Una risorsa `action_sequence.gd` contiene una lista di `ActionStep`:

- `SAY`: chiave del testo, speaker e attesa facoltativa di conferma.
- `WALK`: personaggio e coordinata di destinazione nella stanza, con attesa dell'arrivo.
- `ANIMATE`: personaggio, animazione e attesa facoltativa della sua conclusione.
- `WAIT`: durata in secondi.
- `EFFECT`: Callable creato dallo script, per applicare una regola al momento corretto.
- `CHANGE_ROOM`: stanza e ingresso nominato.

Le animazioni cicliche devono partire senza attenderne il completamento.
Le conferme avanzano solo le battute, senza saltare movimento, animazioni o attese.
`cancel()` elimina i passi futuri, preservando gli effetti già applicati.

Assegna una sequenza al campo `conversation` di un hotspot per il dialogo a mani libere;
`scenes/objects/ep01_cabin_interphone/interphone.tscn` contiene un esempio giocabile, come risorsa interna.
Per sequenze dipendenti dal progresso ridefinisci `actions(state, item_id, examining)`.
Le regole semplici continuano a usare `examine`, `interact` e `use_item`: l'adattatore
le esegue come effetti e visualizza la risposta restituita.

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
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --path 'C:\htdocs\_OLD\_GAMES\1899\godot' --script res://tests/visual_check.gd --resolution 1152x720
```

Le immagini finiscono in `test-output/`, esclusa da Git e dall'importazione Godot.
I test non sostituiscono una prova con controller fisico o una partita completa di EP01.
