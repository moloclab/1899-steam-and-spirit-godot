# Redesign degli asset di 1899 con Sprite Fusion

Il metodo principale approvato è `same-style`, tramite lo strumento MCP Sprite Fusion `generate_sprites_in_style`, con dimensione `size` esplicita. Gli asset devono ricevere un livello di dettaglio coerente con Churchill, conservando identità, funzione nella scena e ingombro del soggetto. Il procedimento lavora direttamente sui file presenti in `godot/assets/graphics` (cartella `assets/graphics` rispetto a questa guida).

## Riferimenti approvati

| Ruolo | File | Dimensioni |
| --- | --- | --- |
| Risultato approvato | `assets/graphics/characters/churchill/churchill-stand.png` | 46×100 px |

Tutte le immagini attualmente presenti in `assets/graphics/ep01_cabin/` e `assets/graphics/characters/`, incluse le sottocartelle, sono già state ridisegnate e approvate dall'utente al 25 novembre 2026. Possono essere usate come riferimenti per i successivi redesign, scegliendo quelle più pertinenti per categoria, soggetto, materiali e posa. Questa approvazione riguarda i file attuali e non si estende automaticamente a nuove varianti o aggiunte future.

Churchill resta il riferimento stilistico generale e non va ridisegnato salvo richiesta esplicita. Per gli spritesheet approvati estrarre i fotogrammi pertinenti prima di usarli come riferimenti.

## Stile e contorno comuni

Tutti gli asset devono avere un contorno esterno scuro di un pixel, coerente con Churchill e con il calamaio approvato. Lo spessore si misura in pixel dell'asset finale, prima della scala di visualizzazione del gioco; il ritaglio dei margini trasparenti non lo modifica.

Usare un tono molto scuro, vicino al nero o al marrone scuro dei riferimenti, con una linea di spessore uniforme che segua la sagoma. Evitare bordi raddoppiati, aloni, sfocature e antialiasing; per gli sprite su trasparenza mantenere alpha binario. Le diagonali seguono la griglia dei pixel. Le linee interne restano subordinate al contorno e non devono appesantire i dettagli.

Per fondali e superfici continue, applicare questo linguaggio ai contorni degli elementi rappresentati e ai raccordi pertinenti, senza aggiungere una cornice artificiale intorno al canvas. I fotogrammi di un'animazione devono mantenere lo stesso trattamento del bordo.

Per mobili coordinati usare il comò approvato attualmente integrato, `assets/graphics/ep01_cabin/como.png`, come riferimento del set.

## Palette cromatica di riferimento

La palette comune di 128 colori è disponibile come [tavola con codici HEX](palette/1899-base-128.png), [campioni senza testo](palette/1899-base-128-swatches.png), [file GPL](palette/1899-base-128.gpl) e [file JSON](palette/1899-base-128.json). Il [README della palette](palette/README.md) documenta origine e metodo di estrazione. Validare la coerenza con i redesign nella scena; i gruppi di colori della tavola non definiscono rampe di materiale già approvate.

Usare la palette come base cromatica trasversale per il redesign. I 128 colori costituiscono un riferimento comune, non un limite al numero di colori del gioco o dei singoli asset. Ogni asset può usarne un sottoinsieme e introdurre sfumature aggiuntive quando aiutano a rappresentare materiali, illuminazione, dettagli o leggibilità, mantenendo coerenza con le tonalità di base, l'identità del soggetto e l'atmosfera della scena.

Non richiedere l'aderenza esatta ai codici della palette, né applicare conversioni automatiche dei risultati ai soli 128 colori. Valutare la coerenza visiva nella scena, senza scartare un risultato per la sola presenza di colori aggiuntivi. Stati e fotogrammi dello stesso soggetto devono mantenere continuità cromatica. Un vincolo cromatico esatto si applica soltanto su richiesta esplicita.

## Preparare gli input

1. Individuare l'asset da modificare direttamente in `godot/assets/graphics`, con gli eventuali stati o fotogrammi associati. Il file attuale è il riferimento del soggetto.
2. Descrivere accuratamente che cosa rappresenta, usando il contesto fornito dall'utente. Registrare dimensioni del file, rettangolo dei pixel visibili, trasparenza e ancoraggi importanti: piedi, base dell'oggetto, attacchi, aperture o raccordi con altri elementi. Per un soggetto ambiguo chiarirne la natura prima della generazione.
3. Controllare la griglia effettiva e usare le dimensioni attuali del file come risoluzione di lavoro, salvo per le icone inventario: il loro soggetto deve rientrare nel canvas finale di 40×40 px, indipendentemente dalle dimensioni originali. Non applicare un ulteriore ×4 agli asset già ingranditi.
4. Per gli spritesheet estrarre i singoli fotogrammi e ricavare ordine, regioni e durate dalle risorse e dalle scene Godot che li utilizzano.
5. Conservare il file sorgente invariato fino alla scelta dell'utente. Salvare file di preparazione, confronti e metadati in `../output/spritefusion/<nome-asset>/`; per i risultati nativi seguire la numerazione indicata in “Valutare i risultati”.

## Eseguire il redesign

Usare `generate_sprites_in_style` con questi riferimenti, nell'ordine:

1. Il file da ridisegnare in `godot/assets/graphics`, alle dimensioni attuali, oppure un suo fotogramma estratto nel caso di uno spritesheet. Guida soggetto, composizione, proporzioni e colori dominanti.
2. Churchill approvato come riferimento per il grado di dettaglio, le ombreggiature e il contorno scuro di un pixel. Il calamaio approvato può fornire un ulteriore riferimento per il bordo.
3. Un asset approvato pertinente da `assets/graphics/ep01_cabin/` o `assets/graphics/characters/`, preferendo la stessa categoria o lo stesso personaggio nella posa principale e dichiarandone il ruolo nel prompt.

Per un oggetto o un fondale, specificare che Churchill fornisce soltanto un riferimento stilistico: abiti, anatomia e colori del personaggio non devono trasferirsi all'asset. Quando esiste un riferimento più pertinente già approvato, preferirlo per quella categoria.

### Scegliere il canvas

Impostare sempre `size`: è il lato del canvas quadrato, non la larghezza o l'altezza garantita del soggetto. I valori attualmente disponibili sono 16, 24, 32, 48, 64, 80, 96, 112 e 128. Scegliere un canvas che contenga il soggetto alle dimensioni obiettivo e descriverne nel prompt le proporzioni e l'occupazione relativa, senza inserire misure in pixel nel testo destinato al generatore.

Per il comò da 40×36 px si è usato `size: 48`, chiedendo un oggetto largo quasi quanto il canvas e alto circa tre quarti. Per il calamaio da 16×28 px si è usato `size: 32`, chiedendo circa metà larghezza e sette ottavi dell'altezza. Queste indicazioni guidano la composizione, ma l'ingombro effettivo va misurato sugli output.

Per le icone inventario, scegliere dimensioni del soggetto adatte alla leggibilità entro 40×40 px, contorno incluso, senza vincoli rispetto all'ingombro originale. Poiché `size: 40` non è disponibile, si può usare `size: 48` chiedendo che il soggetto occupi al massimo circa cinque sesti del canvas lungo ciascun asse. Misurare comunque l'output: il canvas nativo di generazione è distinto dal canvas finale dell'icona.

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

Quando si allegano i campioni `palette/1899-base-128-swatches.png`, dichiarare nel prompt che guidano soltanto i colori, senza modificare l'ordine dei riferimenti del soggetto e dello stile.

Ogni chiamata `generate_sprites_in_style` costa attualmente 15 crediti e restituisce più varianti. Comunicare il costo prima della generazione e iniziare con una chiamata per asset da valutare. Dopo un timeout controllare `list_assets` prima di qualsiasi nuovo tentativo: il risultato potrebbe essere già salvato e addebitato.

## Valutare i risultati

Scaricare il risultato nativo nella stessa cartella della sorgente con il nome `<nome-originale>-redesign.png`, prima di modificarlo. Se una chiamata produce più varianti, usare `-redesign.png` per la prima e `-redesign-2.png`, `-redesign-3.png` per le successive, mostrandole nel confronto. Conservare eventuali risultati già presenti senza sovrascriverli, proseguendo la numerazione. Annotare prompt, input nell'ordine usato, ID degli asset Sprite Fusion, dimensioni effettive e decisione sul risultato.

Confrontare originale, risultato e riferimento approvato:

- A dimensione effettiva nel gioco, per leggibilità e coerenza del dettaglio.
- Con ingrandimento nearest neighbor, per controllare contorni, cluster e trasparenza.
- Dentro la scena, per verificare ingombro, ancoraggi e continuità con gli altri asset.

Verificare esplicitamente che il bordo esterno sia scuro e di un pixel alla risoluzione nativa, anche quando l'asset sorgente ne è privo. Un output con bordo assente, troppo spesso o incoerente richiede una correzione prima dell'integrazione; non considerare sufficiente la sola somiglianza dei colori o del dettaglio.

Per tutti gli asset tranne le icone inventario, larghezza e altezza del soggetto visibile, contorno incluso, devono restare ciascuna tra il 95% e il 105% della corrispondente dimensione della sorgente visibile, escludendo i margini completamente trasparenti. Per dimensioni intere, il minimo è `ceil(dimensione × 0.95)` e il massimo è `floor(dimensione × 1.05)`. Registrare separatamente le dimensioni del canvas. Un output fuori intervallo non è conforme per impostazione predefinita: segnalarlo e attendere una deroga esplicita prima di integrarlo, anche se il disegno è interessante.

Le icone inventario non devono rispettare le dimensioni del soggetto originale né la tolleranza del 95–105%: il soggetto visibile, contorno incluso, deve rientrare interamente in 40×40 px ed essere riconoscibile alla dimensione effettiva nel gioco.

Valutare anche i punti di contatto: le dimensioni da sole non misurano la compatibilità. Deformazioni, cambi di prospettiva o spostamenti degli ancoraggi richiedono una valutazione distinta. Ogni deroga dimensionale vale soltanto per l'asset approvato e non modifica la tolleranza per i successivi.

`edit_sprite` non è il metodo principale per questo redesign. Non applicare compensazioni automatiche basate su un presunto rapporto fisso fra dimensioni di input e output.

## Applicare il metodo alle categorie

| Categoria | Vincoli da aggiungere |
| --- | --- |
| Personaggi statici | Identità, posa, proporzioni, quota dei piedi, orientamento e trattamento del volto. Usare la posa approvata come riferimento per le altre. |
| Oggetti della stanza | Base, sagoma, attacchi e punti usati nelle interazioni. Conservare la posizione rispetto al fondale. |
| Icone inventario | Riconoscibilità alla dimensione effettiva. PNG trasparenti di 40×40 px, con il soggetto centrato e interamente contenuto nel canvas, senza vincoli sulle dimensioni originali. |
| Cursori | Riconoscibilità alla dimensione effettiva e conservazione del punto attivo. |
| Stati dello stesso oggetto | Usare lo stato approvato come riferimento comune, mantenendo identiche le parti che non cambiano. |
| Animazioni | Lavorare sui singoli fotogrammi con un riferimento comune. Conservare ordine, durate, ancoraggi e continuità dei volumi; verificare il ciclo in movimento. |
| Fondali | Conservare prospettiva, pavimento, aperture e raccordi con gli oggetti. Validare un primo fondale nella scena prima di estendere il metodo agli altri. |

Non inviare uno spritesheet come se fosse un singolo soggetto da ridisegnare. Per mantenere una sequenza esistente, estrarre i fotogrammi e ricomporre il foglio dopo la validazione, mantenendo allineamento e margini comuni invece di ritagliare ogni fotogramma in modo indipendente. Generare una nuova animazione con `animate_sprite` è una scelta separata, perché può cambiare pose e tempi.

## Integrare e riutilizzare

Attendere la scelta dell'utente prima di sostituire il file originale o aggiornare i riferimenti nelle scene. Dopo l'approvazione visiva e i controlli di bordo e dimensioni, verificare scala, offset e regioni degli atlas. Conservare una copia dell'originale e l'output nativo nei materiali della prova. Rimuovere soltanto i margini completamente trasparenti della variante scelta e salvarla al percorso originale, mantenendo intatti i pixel visibili e il contorno. Mantenere coordinate di gioco e hotspot coerenti con l'ingombro approvato; conservare la scala esistente salvo un adattamento motivato e verificato.

Il ritaglio non corregge un soggetto troppo grande o troppo piccolo. Non ridimensionare, tagliare pixel visibili, aggiungere margini o rigenerare automaticamente per forzare il rispetto delle dimensioni. Fa eccezione il canvas comune per le icone inventario descritto di seguito, che lascia invariato il soggetto.

Per le icone inventario, verificare che il soggetto visibile, contorno incluso, non superi 40 px lungo ciascun asse. Dopo il ritaglio dei margini nativi, collocarlo al centro di un canvas trasparente di 40×40 px, mantenendone intatti i pixel. Distribuire i margini in modo uguale; quando la differenza è dispari, lasciare il pixel aggiuntivo a destra o in basso. Un soggetto che supera il canvas richiede una nuova valutazione prima dell'integrazione; non tagliare pixel visibili per farlo rientrare.

Applicare questa regola quando l'utente specifica nel prompt che si tratta di un oggetto dell'inventario. Il canvas finale di 40×40 px riguarda il PNG integrato nel gioco; conservare invariati i risultati nativi della generazione e continuare a misurare separatamente l'ingombro visibile del soggetto.

Eliminare le varianti scartate e i relativi `.import` solo quando richiesto; controllare prima eventuali riferimenti nelle scene. La loro eliminazione riguarda i file locali, senza cancellare la libreria Sprite Fusion.

Ogni nuovo asset approvato amplia i riferimenti disponibili nelle rispettive categorie, aggiungendosi alle immagini già approvate di `assets/graphics/ep01_cabin/` e `assets/graphics/characters/`. Churchill resta il riferimento stilistico generale; preferire un riferimento della stessa categoria quando più pertinente.

### Richiesta riutilizzabile

È sufficiente indicare il percorso dell'asset originale. Il riferimento stilistico predefinito è Churchill approvato; la destinazione deriva automaticamente dal percorso sorgente.

```text
Fai il redesign di [percorso asset originale] seguendo godot/ASSET-REDESIGN.md.
```

Eventuali vincoli specifici o riferimenti alternativi possono essere aggiunti alla richiesta.

## Documentazione Sprite Fusion

- [Generazione con riferimenti di stile e dimensione](https://www.spritefusion.com/docs/pixel-art-generator/api/generate-and-transform-images)
- [Strumenti MCP e costi](https://www.spritefusion.com/docs/pixel-art-generator/api/mcp)
