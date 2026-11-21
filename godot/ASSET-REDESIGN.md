# Redesign degli asset di 1899 con Sprite Fusion

Il metodo principale approvato è `same-style`, tramite lo strumento MCP Sprite Fusion `generate_sprites_in_style`, con dimensione `size` esplicita. Gli asset devono ricevere un livello di dettaglio coerente con Churchill, conservando identità, funzione nella scena e ingombro del soggetto. Il procedimento lavora direttamente sui file presenti in `godot/assets/graphics` (cartella `assets/graphics` rispetto a questa guida).

## Riferimento approvato

| Ruolo | File | Dimensioni |
| --- | --- | --- |
| Originale del confronto storico | `assets/graphics/characters/churchill/churchillStand.gif` | 44×100 px |
| Risultato approvato | `assets/graphics/characters/churchill/churchill-stand.png` | 46×100 px |

Nell'originale tutti i blocchi allineati 4×4 sono uniformi: il file contiene già l'ingrandimento della griglia di base. Il risultato approvato usa dettagli più fini all'interno di quella griglia, mantenendo l'altezza. Entrambi hanno trasparenza binaria, con alpha 0 o 255. I colori opachi passano da 63 a 38: aggiungere dettaglio non richiede aumentare il numero di colori.

Churchill definisce il risultato visivo desiderato. Il metodo `same-style` è stato approvato nelle prove sul comò e sul calamaio con penna d'oca. L'applicazione a fondali e animazioni va verificata sui primi esempi di ciascuna categoria.

churchillStand.gif documenta soltanto il confronto storico di Churchill. Tutte le sorgenti da modificare sono già in `godot/assets/graphics`. Churchill approvato si usa come riferimento e non va ridisegnato salvo richiesta esplicita.

## Stile e contorno comuni

Tutti gli asset devono avere un contorno esterno scuro di un pixel, coerente con Churchill e con il calamaio approvato. Lo spessore si misura in pixel dell'asset finale, prima della scala di visualizzazione del gioco; il ritaglio dei margini trasparenti non lo modifica.

Usare un tono molto scuro, vicino al nero o al marrone scuro dei riferimenti, con una linea di spessore uniforme che segua la sagoma. Evitare bordi raddoppiati, aloni, sfocature e antialiasing; per gli sprite su trasparenza mantenere alpha binario. Le diagonali seguono la griglia dei pixel. Le linee interne restano subordinate al contorno e non devono appesantire i dettagli.

Per fondali e superfici continue, applicare questo linguaggio ai contorni degli elementi rappresentati e ai raccordi pertinenti, senza aggiungere una cornice artificiale intorno al canvas. I fotogrammi di un'animazione devono mantenere lo stesso trattamento del bordo.

Il primo comò approvato (prova `same-style-48`) resta un riferimento storico per il dettaglio del legno e per le proporzioni, ma non per il contorno, che era ancora da uniformare. Il comò attualmente integrato è la variante 9 della prova con palette flessibile, scelta esplicitamente dall'utente anche per il nuovo trattamento del frontale e della ferramenta.

## Palette cromatica di riferimento

La prima palette comune di 128 colori di base è stata estratta dagli asset originali in `../EP01/img`, bilanciando fondali, personaggi, oggetti, inventario e interfaccia. La [tavola con codici HEX](palette/1899-base-128.png), i [campioni senza testo](palette/1899-base-128-swatches.png), il [file GPL](palette/1899-base-128.gpl) e il [file JSON](palette/1899-base-128.json) sono in `palette/`. Il [README della palette](palette/README.md) documenta metodo, pesi e riproduzione. La prima selezione resta da confrontare con i redesign approvati e da validare su scene rappresentative; le righe della tavola raggruppano colori affini e non definiscono rampe di materiale già approvate.

Usare la palette come base cromatica trasversale per il redesign. I 128 colori costituiscono un riferimento comune, non un limite al numero di colori del gioco o dei singoli asset. Ogni asset può usarne un sottoinsieme e introdurre sfumature aggiuntive quando aiutano a rappresentare materiali, illuminazione, dettagli o leggibilità, mantenendo coerenza con le tonalità di base, l'identità del soggetto e l'atmosfera della scena.

Non richiedere l'aderenza esatta ai codici della palette, né applicare conversioni automatiche dei risultati ai soli 128 colori. Valutare la coerenza visiva nella scena, senza scartare un risultato per la sola presenza di colori aggiuntivi. Stati e fotogrammi dello stesso soggetto devono mantenere continuità cromatica. Un vincolo cromatico esatto si applica soltanto su richiesta esplicita.

## Preparare gli input

1. Individuare l'asset da modificare direttamente in `godot/assets/graphics`, con gli eventuali stati o fotogrammi associati. Il file attuale è il riferimento del soggetto.
2. Descrivere accuratamente che cosa rappresenta, usando il contesto fornito dall'utente. Registrare dimensioni del file, rettangolo dei pixel visibili, trasparenza e ancoraggi importanti: piedi, base dell'oggetto, attacchi, aperture o raccordi con altri elementi. Per un soggetto ambiguo chiarirne la natura prima della generazione.
3. Controllare la griglia effettiva e usare le dimensioni attuali del file come risoluzione di lavoro. Non applicare un ulteriore ×4 agli asset già ingranditi.
4. Per gli spritesheet estrarre i singoli fotogrammi e ricavare ordine, regioni e durate dalle risorse e dalle scene Godot che li utilizzano.
5. Conservare il file sorgente invariato. Salvare il risultato nella stessa cartella, aggiungendo `-redesign` al nome prima dell'estensione: per esempio, `assets/graphics/ep01_cabin/bed.png` diventa `assets/graphics/ep01_cabin/bed-redesign.png`. Salvare eventuali file di preparazione, confronti e metadati in `../output/spritefusion/<nome-asset>/`.

## Eseguire il redesign

Usare `generate_sprites_in_style` con questi riferimenti, nell'ordine:

1. Il file da ridisegnare in `godot/assets/graphics`, alle dimensioni attuali, oppure un suo fotogramma estratto nel caso di uno spritesheet. Guida soggetto, composizione, proporzioni e colori dominanti.
2. Churchill approvato come riferimento per il grado di dettaglio, le ombreggiature e il contorno scuro di un pixel. Il calamaio approvato può fornire un ulteriore riferimento per il bordo.
3. Quando disponibile, un asset approvato della stessa categoria o lo stesso personaggio nella posa principale, dichiarandone il ruolo nel prompt.

Per un oggetto o un fondale, specificare che Churchill fornisce soltanto un riferimento stilistico: abiti, anatomia e colori del personaggio non devono trasferirsi all'asset. Quando esiste un riferimento più pertinente già approvato, preferirlo per quella categoria.

### Scegliere il canvas

Impostare sempre `size`: è il lato del canvas quadrato, non la larghezza o l'altezza garantita del soggetto. I valori attualmente disponibili sono 16, 24, 32, 48, 64, 80, 96, 112 e 128. Scegliere un canvas che contenga il soggetto alle dimensioni obiettivo e descriverne nel prompt le proporzioni e l'occupazione relativa, senza inserire misure in pixel nel testo destinato al generatore.

Per il comò da 40×36 px si è usato `size: 48`, chiedendo un oggetto largo quasi quanto il canvas e alto circa tre quarti. Per il calamaio da 16×28 px si è usato `size: 32`, chiedendo circa metà larghezza e sette ottavi dell'altezza. Queste indicazioni guidano la composizione, ma l'ingombro effettivo va misurato sugli output.

Il canvas può contenere margini trasparenti: conservarli negli output nativi e misurare separatamente il soggetto. Se la dimensione richiesta supera 128 px, segnalare il limite prima di generare e concordare una prova specifica; non ridurre implicitamente l'obiettivo o forzare un ingrandimento successivo.

### Prompt di base

```text
Create [accurate description of the subject and its role in the game],
using the first reference for the subject, recognizable silhouette,
proportions, orientation, perspective, composition and dominant colors.
Use the second reference only for the amount of finer detail, deliberate
pixel clusters, restrained shading and dark outline treatment.

Give the subject a consistent dark outline exactly one final-image pixel
thick, following its outer silhouette, matching Churchill and the approved
quill and inkwell. Keep the outline continuous and readable, with stepped
pixel diagonals, no doubled border, blur, antialiasing or halo.
Keep internal lines subtle and subordinate to the outer outline.

Preserve important contact points, the original design and broad readable
areas. Add purposeful finer contours, material details and subtle shading.
Do not transfer unrelated anatomy, clothing, objects or colors from the
style references. Preserve the source's transparency and background treatment.

[Describe the subject's width and height relative to the square composition.]
[Describe the specific existing surfaces or features to refine.]
[State the contact points, openings or landmarks that must remain aligned.]
[Explain the role of any additional reference images.]
[Use the shared 128-color palette as a base color reference.
Allow additional harmonious shades where needed for materials, lighting,
detail or readability; exact palette matching is not required.]
```

Adattare le ultime righe al soggetto: pieghe e volumi per abiti, venature per legno, giunti e riflessi contenuti per metallo. Conservare i tratti stilizzati dei personaggi; il volto di Churchill approvato resta privo di occhi e bocca disegnati. Non aggiungere elementi narrativi o funzionali assenti dall'originale.

Precisare sempre la natura del soggetto. Per esempio, `feather.png` rappresenta un calamaio con penna d'oca per scrivere; `map.png` è la planimetria del Leviathian, il sottomarino steampunk a forma di manta su cui viaggia Churchill. La descrizione deve chiarire il contenuto, oltre ai materiali e allo stile.

Mantenere i colori dominanti del soggetto nel prompt e indicare la palette comune di 128 colori come base flessibile, secondo la sezione dedicata. Quando si allegano i campioni `palette/1899-base-128-swatches.png`, dichiarare che guidano soltanto i colori, senza modificare l'ordine dei riferimenti del soggetto e dello stile. Il contorno scuro è un requisito comune da specificare sempre.

Ogni chiamata `generate_sprites_in_style` costa attualmente 15 crediti e restituisce più varianti. Comunicare il costo prima della generazione e iniziare con una chiamata per asset da valutare. Dopo un timeout controllare `list_assets` prima di qualsiasi nuovo tentativo: il risultato potrebbe essere già salvato e addebitato.

## Valutare i risultati

Scaricare il risultato nativo nella stessa cartella della sorgente con il nome `<nome-originale>-redesign.png`, prima di modificarlo. Se una chiamata produce più varianti, usare `-redesign.png` per la prima e `-redesign-2.png`, `-redesign-3.png` per le successive, mostrandole nel confronto. Conservare eventuali risultati già presenti senza sovrascriverli, proseguendo la numerazione. Annotare prompt, input nell'ordine usato, ID degli asset Sprite Fusion, dimensioni effettive e decisione sul risultato.

Confrontare originale, risultato e riferimento approvato:

- A dimensione effettiva nel gioco, per leggibilità e coerenza del dettaglio.
- Con ingrandimento nearest neighbor, per controllare contorni, cluster e trasparenza.
- Dentro la scena, per verificare ingombro, ancoraggi e continuità con gli altri asset.

Verificare esplicitamente che il bordo esterno sia scuro e di un pixel alla risoluzione nativa, anche quando l'asset sorgente ne è privo. Un output con bordo assente, troppo spesso o incoerente richiede una correzione prima dell'integrazione; non considerare sufficiente la sola somiglianza dei colori o del dettaglio.

Larghezza e altezza del soggetto visibile, contorno incluso, devono restare ciascuna tra il 95% e il 105% della corrispondente dimensione della sorgente visibile, escludendo i margini completamente trasparenti. Per dimensioni intere, il minimo è `ceil(dimensione × 0.95)` e il massimo è `floor(dimensione × 1.05)`. Registrare separatamente le dimensioni del canvas. Un output fuori intervallo non è conforme per impostazione predefinita: segnalarlo e attendere una deroga esplicita prima di integrarlo, anche se il disegno è interessante.

Churchill approvato passa da 44 a 46 px di larghezza e rientra nella tolleranza. Valutare anche l'ingombro del soggetto e i punti di contatto; il numero di pixel da solo non misura la compatibilità. Deformazioni, cambi di prospettiva o spostamenti degli ancoraggi richiedono una valutazione distinta.

### Prove approvate

| Asset | Parametro | Risultato scelto e integrazione |
| --- | --- | --- |
| Comò | `size: 48` | Variante 5, soggetto 40×36 px nel canvas 48×48. Rimossi solo i margini trasparenti e sostituito `como.png`. Il bordo resta da uniformare alla nuova regola comune. |
| Comò, palette flessibile 128 | `size: 48` | Variante 9 scelta dall'utente, inclusi i cambiamenti al frontale e alla ferramenta. Soggetto 40×37 px nel canvas 48×48; rimossi solo i margini trasparenti e sostituito `como.png`. Posizione y da 164 a 163 e hotspot 40×37 per mantenere la base a y=200. Nativo e copia precedente in `../output/spritefusion/como/palette-128/`; eliminate le altre otto varianti locali. |
| Calamaio con penna d'oca | `size: 32` | Variante 3, soggetto 20×28 px nel canvas 32×32. L'utente ha approvato esplicitamente la larghezza maggiore rispetto ai 16×28 px originali. Rimossi solo i margini trasparenti e sostituito `feather.png`. |
| Lavabo abbinato al comò | `size: 64` | Variante 4 scelta dall'utente dopo la segnalazione delle dimensioni fuori tolleranza: soggetto 36×62 px nel canvas 64×64, rispetto ai 40×56 px originali. Rimossi solo i margini trasparenti e sostituito `sink.png`. Posizione (272, 138) e hotspot 36×62 mantengono la base a y=200. Originale e nativo in `../output/spritefusion/sink/same-set-64/`; eliminate le altre otto varianti locali. |

Le deroghe dimensionali del calamaio e del lavabo riguardano soltanto i rispettivi asset e non modificano la tolleranza predefinita per i successivi. I file delle prime prove e i metadati sono in `../output/spritefusion/como/same-style-48/` e `../output/spritefusion/feather/same-style-32/`.

`edit_sprite` non è il metodo principale per questo redesign: nelle prove ha variato sensibilmente le dimensioni, anche con un input ingrandito preventivamente ×2. Non applicare compensazioni automatiche basate su un presunto rapporto fisso fra input e output.

Conservare i risultati nativi. Per la variante scelta è consentito eliminare soltanto i margini completamente trasparenti, senza ridimensionare o modificare i pixel visibili. Conservare il file nativo tra i materiali della prova e verificare che il ritaglio lasci intatti soggetto e contorno. Il ritaglio non corregge un soggetto troppo grande o troppo piccolo. Non ridimensionare, tagliare pixel visibili, aggiungere margini o rigenerare automaticamente per forzare il rispetto delle dimensioni.

## Applicare il metodo alle categorie

| Categoria | Vincoli da aggiungere |
| --- | --- |
| Personaggi statici | Identità, posa, proporzioni, quota dei piedi, orientamento e trattamento del volto. Usare la posa approvata come riferimento per le altre. |
| Oggetti della stanza | Base, sagoma, attacchi e punti usati nelle interazioni. Conservare la posizione rispetto al fondale. |
| Icone inventario e cursori | Riconoscibilità alla dimensione effettiva. Per i cursori preservare anche il punto attivo. |
| Stati dello stesso oggetto | Usare lo stato approvato come riferimento comune, mantenendo identiche le parti che non cambiano. |
| Animazioni | Lavorare sui singoli fotogrammi con un riferimento comune. Conservare ordine, durate, ancoraggi e continuità dei volumi; verificare il ciclo in movimento. |
| Fondali | Conservare prospettiva, pavimento, aperture e raccordi con gli oggetti. Validare un primo fondale nella scena prima di estendere il metodo agli altri. |

Non inviare uno spritesheet come se fosse un singolo soggetto da ridisegnare. Per mantenere una sequenza esistente, estrarre i fotogrammi e ricomporre il foglio dopo la validazione, mantenendo allineamento e margini comuni invece di ritagliare ogni fotogramma in modo indipendente. Generare una nuova animazione con `animate_sprite` è una scelta separata, perché può cambiare pose e tempi.

## Integrare e riutilizzare

Integrare un risultato dopo l'approvazione visiva e il controllo del bordo, verificando scala, offset, regioni degli atlas e riferimenti delle scene. Conservare una copia dell'originale e l'output nativo nei materiali della prova. Quando l'utente chiede di sostituire l'asset, rimuovere i soli margini trasparenti della variante scelta e salvarla al percorso originale, così le scene esistenti la utilizzano. Mantenere le coordinate di gioco e gli hotspot coerenti con l'ingombro approvato. Conservare la scala esistente salvo un adattamento motivato e verificato.

Eliminare le varianti scartate e i relativi `.import` solo quando richiesto; controllare prima eventuali riferimenti nelle scene. La loro eliminazione riguarda i file locali, senza cancellare la libreria Sprite Fusion.

Ogni nuovo asset approvato amplia i riferimenti disponibili: Churchill resta il riferimento iniziale per i personaggi; il primo oggetto e il primo fondale approvati diventano riferimenti per le rispettive categorie.

### Richiesta riutilizzabile

È sufficiente indicare il percorso dell'asset originale. Il riferimento stilistico predefinito è Churchill approvato; la destinazione deriva automaticamente dal percorso sorgente.

```text
Fai il redesign di [percorso asset originale] seguendo godot/ASSET-REDESIGN.md.
```

Questa richiesta comporta una chiamata `generate_sprites_in_style`, con `size` esplicito, costo comunicato prima della generazione e richiesta del contorno scuro di un pixel. Salvare le varianti native nella stessa cartella con il suffisso `-redesign` e la numerazione progressiva. Mostrare il confronto con l'originale, indicando separatamente dimensioni del canvas, ingombro del soggetto e rispetto del bordo. Attendere la scelta dell'utente prima di sostituire il file originale o aggiornare riferimenti nelle scene. Eventuali vincoli specifici o riferimenti alternativi possono essere aggiunti alla richiesta.

## Documentazione Sprite Fusion

- [Generazione con riferimenti di stile e dimensione](https://www.spritefusion.com/docs/pixel-art-generator/api/generate-and-transform-images)
- [Strumenti MCP e costi](https://www.spritefusion.com/docs/pixel-art-generator/api/mcp)
