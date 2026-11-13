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
Musica, effetti, conversazioni a scelta e altre stanze di EP01 devono ancora essere portati.
La lingua visualizzata è l'italiano; il catalogo conserva anche le traduzioni inglesi.
Le stanze vengono caricate in modo **sincrono**.

## Comandi

| Azione | Mouse / tastiera | Controller (etichette Xbox) |
| --- | --- | --- |
| Camminare | Clic sul pavimento, A/D o frecce | Levetta sinistra |
| Scegliere un bersaglio | Tab / Maiusc+Tab | RB / LB |
| Stanza ↔ inventario | I | Y |
| Aprire le due scelte | Clic sinistro su oggetto, persona, uscita o inventario | — |
| Agire / selezionare | Mano, bocca o uscita; Invio o Spazio | A |
| Esaminare | Lente; destro o E | X |
| Annullare una selezione | Pavimento o Esc | B |
| Menu comandi / pausa | ? / F1 | Start |
| Avanzare una conversazione | Clic sinistro, Invio o Spazio | A |
| Salva / carica | Pulsanti in alto o nel menu | Dal menu |

Il tasto sinistro apre il pannello originale con **lente** e **mano/bocca/uscita**.
L'azione parte dopo la scelta e dopo l'avvicinamento di Churchill.

Per usare un oggetto: clic nell'inventario, poi sulla mano, quindi sul bersaglio.
Per combinare: seleziona il primo con la mano e clicca il secondo nell'inventario.
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
| `scripts/save_store.gd` | Salvataggi versione 2, validazione e migrazione dalla versione 1 |
| `scripts/world/room_manager.gd` | Sostituzione delle stanze, personaggi, centratura/scorrimento e pausa delle animazioni |
| `scripts/world/room.gd` | Cache degli hotspot, anche annidati, con invalidazione dopo aggiunte e rimozioni |
| `scripts/world/character.gd` | Movimento e animazioni riutilizzabili per Churchill e altri personaggi |
| `scripts/actions/interaction_controller.gd` | Richiesta di avvicinamento e rivalutazione del bersaglio all'arrivo |
| `scripts/actions/sequence_runner.gd` | Esecuzione ordinata dei passi e attese di conferma/completamento |
| `scripts/hotspot.gd`, `scripts/hotspots/` | Area interattiva e regole dei singoli oggetti/enigmi |
| `scripts/data/` | Tipi di risorsa, cataloghi e schema dei progressi |
| `assets/data/` | Oggetti, ricette, metadati delle stanze, sequenze e testi IT/EN |
| `scenes/characters/churchill.tscn` | Personaggio giocante riutilizzabile con animazioni già configurate |

I componenti ricevono stato e dipendenze esplicitamente, senza singleton.
Le risorse descrivono i contenuti e restano condivise; le mutazioni della partita
appartengono a `GameState`. Nessun nodo della stanza viene scritto nel salvataggio.

## Aggiungere contenuti

### Oggetti e combinazioni

1. Crea un `.tres` con lo script `data/item_definition.gd` in `assets/data/items/`.
2. Configura ID, icona, chiavi di nome e descrizione; abilita `collectible` per le raccolte dalla stanza.
3. Registra la definizione in `ItemCatalog.ITEMS` e aggiungi i testi IT/EN in `dialogue.json`.
4. Per una ricetta crea una `combination_definition.gd` in `assets/data/combinations/`
   e registrala in `ItemCatalog.RECIPES`: ingredienti, consumi, risultati e risposta.

Le combinazioni comuni sono simmetriche. Una regola narrativa particolare può
specializzare `apply(state)`, senza ampliare un elenco di condizioni in `GameState`.

### Stanze e progressi

1. Crea una scena con radice `Node2D` e script `world/room.gd`.
2. Crea una definizione `data/room_definition.gd` in `assets/data/rooms/` e assegnala alla radice.
3. Imposta ID, percorso della scena, larghezza, margine percorribile, quota dei piedi,
   scala e ingressi nominati. Registra la definizione in `RoomCatalog.ROOMS`.
4. Le uscite indicano stanza e **nome dell'ingresso**; le coordinate appartengono alla destinazione.
5. Dichiara valori iniziali e intervalli dei progressi in `ProgressSchema.SCOPES`.
   Lo schema attuale gestisce flag booleani e stadi interi.
6. Leggi/scrivi con `get_progress(ambito, chiave)` e `set_progress(ambito, chiave, valore)`.

Gli hotspot hanno ID univoci nella propria stanza e possono essere annidati in contenitori.
`sync_from_state()` aggiorna immagini e visibilità anche dei nodi nascosti.
Per un oggetto semplice bastano le risposte nell'Inspector; per un enigma estendi `Hotspot`.
Le richieste verso nodi rimossi, in eliminazione o nascosti da un antenato vengono scartate.

### Personaggi e sequenze

Il componente `world/character.gd` gestisce centro orizzontale, altezza, velocità,
animazioni e destinazione. Il marinaio nel corridoio usa lo stesso componente del giocatore,
con la sua animazione originale e un hotspot figlio `character_hotspot.gd` che lo segue.
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
`assets/data/sequences/interphone.tres` è un esempio giocabile.
Per sequenze dipendenti dal progresso ridefinisci `actions(state, item_id, examining)`.
Le regole semplici continuano a usare `examine`, `interact` e `use_item`: l'adattatore
le esegue come effetti e visualizza la risposta restituita.

## Salvataggi

Il percorso resta `user://cabin_save.json`, normalmente sotto
`%APPDATA%\Godot\app_userdata\1899 — Steam & Spirit\` su Windows.
Il gioco non carica automaticamente. Ricomincia azzera la partita corrente e conserva il file.

Il formato versione 2 contiene inventario, raccolte, progressi per ambito, stanza e posizione.
I file versione 1 vengono migrati in memoria; la successiva scrittura usa la versione 2.
Prima di applicare i dati vengono controllati ID, tipi, duplicati, ambiti e intervalli.
I progressi assenti ricevono i valori iniziali, permettendo l'aggiunta di nuovi enigmi.
Il servizio scrive un temporaneo e sostituisce il file solo dopo la scrittura riuscita.

## Verifiche

Regressione automatica con la scena reale e input sintetici:

```powershell
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\htdocs\_OLD\_GAMES\1899\godot' --script res://tests/prototype_test.gd
```

Copre cataloghi, ricette, percorso della cabina col solo sinistro, transizioni,
ripresa intermedia, migrazione versione 1, file corrotti senza mutazioni parziali,
conversazione con mouse/tastiera/controller, pausa, passi temporizzati, animazioni,
movimento di altri personaggi, hotspot annidati/nascosti/rimossi e inventario scorrevole.
Il file di test è distinto dal salvataggio del giocatore e viene rimosso al termine.

Catture con il renderer reale, da eseguire senza `--headless`:

```powershell
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --path 'C:\htdocs\_OLD\_GAMES\1899\godot' --script res://tests/visual_check.gd --resolution 1152x720
```

Le immagini finiscono in `test-output/`, esclusa da Git e dall'importazione Godot.
I test non sostituiscono una prova con controller fisico o una partita completa di EP01.
