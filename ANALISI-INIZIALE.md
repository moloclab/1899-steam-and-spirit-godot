# 1899 Steam & Spirit — Analisi iniziale della migrazione a Godot

## Obiettivo

Ricreare EP01 in Godot, mantenendo trama, enigmi e identità del gioco originale,
con una pixel art migliorata e una base tecnica adatta alla distribuzione commerciale.

Priorità concordate:
- Prima versione per Windows, destinata a Steam.
- Supporto a mouse e controller fin dall’inizio.
- Restyling grafico fedele all’originale.
- Console da valutare successivamente, con un budget dedicato al porting.
- Primo ambito di lavoro: EP01.

## Progetto esistente

Il gioco originale si trova in `EP01` ed è realizzato in HTML, CSS e JavaScript,
con jQuery e il motore proprietario JAWS.

Comprende nove stanze giocabili, introduzione e finale.

Struttura principale:
- `rooms/`: ambienti, oggetti interattivi, dialoghi ed enigmi.
- `js/jaws.core.js`: movimento, interazioni, inventario e salvataggi.
- `js/global.js`: variabili di avanzamento.
- `js/combo.js`: combinazioni tra oggetti dell’inventario.
- `js/dictionary.js`: testi italiani e inglesi.
- `img/` e `audio/`: risorse grafiche e sonore.

In `_MATERIALE/grafica` sono presenti anche PSD e cartelle di animazioni,
da inventariare prima di definire il lavoro grafico.

L’analisi svolta riguarda il codice. Il funzionamento completo dell’originale
deve ancora essere verificato con una partita dall’inizio alla fine.

## Tecnologia scelta

- Motore: Godot 4, versione stabile da fissare all’avvio del progetto.
- Linguaggio: GDScript.
- Progetto nuovo in una cartella separata da `EP01`.
- Conservazione dell’originale come riferimento funzionale.

La migrazione richiede una riscrittura del motore.
Le regole di gioco e i contenuti esistenti guideranno l’implementazione.

Godot consente la distribuzione commerciale su PC.
Le console richiedono approvazioni dei produttori e strumenti o servizi
di porting dedicati: non sono un’esportazione standard inclusa nel progetto.

## Struttura prevista

- Scene per gli ambienti, con personaggi e punti interattivi.
- Sistema comune per esaminare, raccogliere, usare e combinare oggetti.
- Inventario indipendente dalla rappresentazione grafica.
- Dialoghi con identificatori stabili e traduzioni italiano/inglese.
- Sequenze di azioni per movimento, battute e animazioni.
- Stato della partita separato dalle scene.
- Salvataggi su file con versione del formato.
- Audio gestito direttamente dal motore.

La coda di istruzioni testuali `aBox` verrà sostituita da sequenze
di azioni esplicite. I salvataggi non conterranno copie dell’HTML.

## Primo prototipo

Ricostruire la cabina di Churchill e il passaggio al corridoio.

Il prototipo dovrà permettere di:
1. Muovere il personaggio ed esaminare gli oggetti.
2. Raccogliere bottiglia, penna e calamita.
3. Combinare penna e calamita.
4. Recuperare la chiave e aprire la porta.
5. Passare al corridoio e tornare nella cabina.
6. Salvare e riprendere la partita mantenendo i progressi.
7. Completare le interazioni con mouse e con controller.

Gli asset originali potranno essere usati inizialmente.
La cabina, Churchill e l’interfaccia diventeranno poi il campione
del restyling prima di estenderlo alle altre stanze.

## Direzione grafica

Preservare atmosfera steampunk, riconoscibilità dei personaggi e tono originale.

Prima della produzione completa definire:
- Palette e livello di dettaglio.
- Dimensioni degli sprite e qualità delle animazioni.
- Risoluzione di riferimento e gestione delle stanze più larghe.
- Leggibilità di testi, inventario e oggetti interattivi.

La qualità finale dovrà essere valutata nel gioco in movimento,
oltre che sulle singole immagini.

## Verifiche e passi successivi

- Avviare Godot e fissare la versione utilizzata.
- Documentare la soluzione completa dell’originale.
- Inventariare asset e relative licenze.
- Realizzare e verificare il primo prototipo.
- Approvare il campione grafico.
- Migrare il resto di EP01 per gruppi di enigmi.
- Provare salvataggi, cambio lingua, controller e diverse risoluzioni.
- Preparare successivamente build, pagina e materiali per Steam.

Tempi e costi complessivi saranno stimati dopo il primo prototipo
e la valutazione del lavoro grafico.

Codex potrà scrivere direttamente script, scene e configurazioni
nella cartella del progetto, senza copia e incolla manuale.
Le verifiche tecniche saranno integrate da prove visive e di giocabilità.
