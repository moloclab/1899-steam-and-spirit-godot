# 1899 — Steam & Spirit · Prototipo EP01

Progetto per **Godot 4.7.2 standard / GDScript**, renderer Compatibility.
Non richiede .NET, Docker o un server web. L'originale in `../EP01` resta invariato.

## Avvio

1. Avvia `C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe`.
2. Nel gestore progetti scegli **Importa** e seleziona `project.godot` in questa cartella.
3. Apri il progetto e premi **F5** per giocare. Il primo avvio importa le immagini.

In alternativa, da PowerShell:

```powershell
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe' --editor --path 'C:\htdocs\_OLD\_GAMES\1899\godot'
```

## Cosa è giocabile

- Cabina ricostruita dalle coordinate degli oggetti originali.
- Churchill cammina con l'animazione originale; oblò e marinaio sono animati.
- Esame degli oggetti, raccolta di Bourbon, penna e calamita.
- Combinazione penna/calamita, enigma del lavandino, recupero della chiave.
- Apertura della porta, corridoio con scorrimento e ritorno alla cabina.
- Inventario e oggetti raccolti persistenti tra le stanze.
- Un salvataggio manuale locale, con versione del formato e gestione dei file illeggibili.
- Comandi mouse, tastiera e controller; menu con istruzioni, salva, carica e ricomincia.
- Giocabile con il solo tasto sinistro: menu a due scelte con le immagini originali.

Il corridoio è un primo ambiente di collegamento: gli altri accessi sono segnaposto.
L'interfono e il marinaio hanno una battuta semplificata. Per ora si gioca in italiano,
senza musica ed effetti sonori. Il restyling grafico e le altre stanze non sono inclusi.

## Comandi

| Azione | Mouse / tastiera | Controller (etichette Xbox) |
| --- | --- | --- |
| Camminare | Clic sul pavimento, A/D o frecce | Levetta sinistra |
| Scegliere un bersaglio | Tab / Maiusc+Tab | RB / LB |
| Stanza ↔ inventario | I | Y |
| Aprire le due scelte | Clic sinistro su oggetto, persona, uscita o inventario | — |
| Agire / selezionare | Clic sulla mano, bocca o uscita; Invio o Spazio | A |
| Esaminare | Clic sulla lente; scorciatoie: destro o E | X |
| Annullare | Clic sul pavimento o Esc | B |
| Menu comandi | ? / F1 / pulsante ? | Start |
| Salva / carica | F5 / F9 durante il gioco | Dal menu |

Un clic sinistro su un oggetto apre il pannello originale: **lente** per esaminare,
**mano** per usare/raccogliere, **bocca** per parlare, **uscita** per attraversare una porta.
Il personaggio agisce solo dopo la scelta. Un clic su un altro oggetto cambia bersaglio;
un clic sul pavimento chiude il pannello e cammina.

Per usare un oggetto: clic nell'inventario, poi sulla mano, quindi sul bersaglio nella stanza.
L'uso dell'oggetto selezionato è diretto, come nell'originale.
Per combinare due oggetti: scegli il primo con la mano, poi clic sul secondo nell'inventario.
Anche gli oggetti dell'inventario si possono esaminare con la lente.
Per annullare clicca di nuovo l'oggetto selezionato o clicca sul pavimento.
Il cursore diventa una lente sopra gli hotspot e torna una freccia fuori dagli oggetti.
Il testo in basso indica il bersaglio; la cornice dorata resta per tastiera e controller.
Nel menu usa croce direzionale e A, oppure mouse e tastiera.

**F5 nell'editor avvia il gioco; F5 nella finestra del gioco salva.**

Il file è `user://cabin_save.json`, normalmente sotto
`%APPDATA%\Godot\app_userdata\1899 — Steam & Spirit\` su Windows.
Non viene caricato automaticamente: premi Carica o F9.
Ricomincia azzera soltanto la partita corrente, lasciando disponibile il file salvato.

## Struttura

- `scenes/main.tscn`: scena iniziale del prototipo.
- `scenes/rooms/cabin.tscn`, `corridor.tscn`: stanze native Godot; oggetti e coordinate sono modificabili nell'editor.
- `scripts/main.gd`: interfaccia, movimento, input e transizioni; invia l'azione all'hotspot dopo l'avvicinamento.
- `scripts/hotspot.gd`: classe base `Hotspot extends Node2D`, con dati dell'Inspector, selezione e risposte degli oggetti semplici.
- `scripts/hotspots/`: sottoclassi per raccoglibili, mappa, lavandino, uscita semplice e porta della cabina.
- `scripts/action_menu.gd`: pannello a due scelte con `panel_hand`, `panel_mouth`, `panel_exit`.
- `scripts/game_state.gd`: dati persistenti, raccolta, combinazioni dell'inventario e salvataggio; non contiene più un dispatcher delle azioni della stanza.
- `assets/graphics/original/`: immagini PNG e animazioni SpriteFrames convertite da EP01.
- `assets/data/dialogue.json`: unico catalogo modificabile dei dialoghi, con chiavi descrittive e lingue `it`/`en`.
- `assets/audio/`: cartella predisposta per musica, effetti e voci future.
- `assets/PROVENIENZA.md`: origine delle risorse grafiche e dei testi.
- `tools/import_original_assets.ps1`: conversione riproducibile dei GIF con System.Drawing di Windows.

L'importatore rigenera anche le due scene: usarlo deliberatamente perché sovrascrive
eventuali modifiche manuali a quelle scene. Non serve eseguirlo per giocare.
Il catalogo dei dialoghi è gestito manualmente e non viene rigenerato dall'importatore.

### Catalogo dei dialoghi

Le risposte usano chiavi `stanza.oggetto.situazione`, per esempio `cabin.bottle.pickup`.
Le risposte condivise usano `common.*`; descrizioni e combinazioni dell'inventario usano
`inventory.*`. Ogni voce contiene le traduzioni esplicite:

```json
"cabin.bottle.pickup": {
  "it": "Meglio eliminare le prove.",
  "en": "Better hide the evidence."
}
```

Il prototipo visualizza `it` e, quando il testo contiene alternative separate da `|`,
mostra la prima. `_text(id)` risolve la chiave; una chiave mancante produce un avviso
nel log e una risposta generica. Anche le conversazioni semplificate e le sequenze
composte sono nel catalogo. Non è conservata una copia del dizionario numerico.
Per aggiungere una risposta, inserisci la voce nel JSON e usa la stessa chiave negli
hotspot o negli script. Se l'oggetto è generato dall'importatore, aggiorna anche lì
la chiave. Il formato dei salvataggi resta invariato.

### Comportamenti degli oggetti

Ogni oggetto cliccabile è un `Hotspot` oppure una sua sottoclasse. L'interfaccia comune è
`examine(state)`, `interact(state)`, `use_item(state, item_id)` e `sync_from_state(state)`.
Le prime tre restituiscono l'ID della risposta; la sincronizzazione aggiorna la grafica leggendo lo stato.
`execute(state, item_id, examining)` sceglie l'azione e verifica il possesso dell'oggetto usato.

Letto, comodino, oblò, interfono, marinaio e segnaposto usano le risposte esportate della classe base.
Bottiglia e penna condividono `collectible.gd`, con ID dell'oggetto e battuta di raccolta configurabili.
La mappa conserva il proprio nodo dopo la raccolta della calamita; il lavandino gestisce l'enigma;
la porta estende l'uscita semplice aggiungendo il requisito della chiave.

Gli script ricevono lo stato esplicitamente, senza singleton: inventario e progressi non risiedono
nei nodi che vengono distrutti al cambio stanza. Il coordinatore sincronizza anche gli hotspot
nascosti, così un caricamento può ripristinare immagini e visibilità. Se il bersaglio scompare
durante l'avvicinamento, la richiesta viene annullata.

Per un nuovo oggetto semplice configura le risposte nell'Inspector; per una regola specifica
estendi `Hotspot` e ridefinisci i metodi necessari. Non serve ampliare un `match` centrale.
Se l'oggetto deve essere ricreato dall'HTML originale, aggiorna anche la configurazione dell'importatore.
Il refactoring mantiene il JSON versione 1: i salvataggi precedenti restano caricabili.

## Verifiche

Test automatico delle regole e del percorso attraverso la scena reale, con eventi sintetici
di mouse, tastiera e controller, inventario, uscita/ritorno, salvataggio intermedio e nel
corridoio, più rifiuto di un file corrotto senza alterare la partita corrente:

```powershell
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\htdocs\_OLD\_GAMES\1899\godot' --script res://tests/prototype_test.gd
```

Catture di cabina, inventario, corridoio e menu usando il renderer reale:

```powershell
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --path 'C:\htdocs\_OLD\_GAMES\1899\godot' --script res://tests/visual_check.gd --resolution 1152x720
```

Il test include anche una partita completa dell'enigma usando **soltanto eventi del
tasto sinistro**, con lente, raccolta, esame nell'inventario, annullamento, combinazione,
recupero della chiave, uscita e ritorno. Controlla le icone distinte per oggetti, persone e uscite.
Controlla inoltre l'ereditarietà degli hotspot, la sincronizzazione di nodi nascosti, l'annullamento
di bersagli nascosti o rimossi e il caricamento di una fixture nel formato versione 1 precedente.

Le catture finiscono in `test-output/`, esclusa dal progetto e da Git.
I test usano un file separato dal salvataggio del giocatore.
I test automatici e il controllo visivo sono stati eseguiti con Godot 4.7.2 su Windows.
La prova con un controller fisico e la valutazione della giocabilità restano da fare.

Riferimento per i comandi: [documentazione ufficiale Godot](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html).
