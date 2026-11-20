# Redesign degli asset di 1899 con Sprite Fusion

Il riferimento approvato è Churchill già presente nel gioco. Gli altri asset devono ricevere un livello di dettaglio coerente con questo riferimento, conservando dimensioni visive, identità e funzione nella scena. Il procedimento usa Sprite Fusion tramite MCP e lavora direttamente sui file presenti in `godot/assets/graphics` (cartella `assets/graphics` rispetto a questa guida).

## Riferimento approvato

| Ruolo | File | Dimensioni |
| --- | --- | --- |
| Originale del confronto storico | `assets/graphics/characters/churchill/churchillStand.gif` | 44×100 px |
| Risultato approvato | `assets/graphics/characters/churchill/churchill-stand.png` | 46×100 px |

Nell'originale tutti i blocchi allineati 4×4 sono uniformi: il file contiene già l'ingrandimento della griglia di base. Il risultato approvato usa dettagli più fini all'interno di quella griglia, mantenendo l'altezza. Entrambi hanno trasparenza binaria, con alpha 0 o 255. I colori opachi passano da 63 a 38: aggiungere dettaglio non richiede aumentare il numero di colori.

Il riferimento definisce il risultato visivo desiderato. Questa procedura ne standardizza il riuso; il confronto tra i due file non ricostruisce il prompt o i passaggi esatti della prima generazione. L'applicazione a oggetti, fondali e animazioni va verificata sui primi esempi di ciascuna categoria.

churchillStand.gif documenta soltanto il confronto storico di Churchill. Tutte le sorgenti da modificare sono già in `godot/assets/graphics`. Churchill approvato si usa come riferimento e non va ridisegnato salvo richiesta esplicita.

## Preparare gli input

1. Individuare l'asset da modificare direttamente in `godot/assets/graphics`, con gli eventuali stati o fotogrammi associati. Il file attuale è la sorgente per l'edit.
2. Registrare dimensioni del file, ingombro del soggetto, trasparenza e ancoraggi importanti: piedi, base dell'oggetto, attacchi, aperture o raccordi con altri elementi.
3. Controllare la griglia effettiva e usare le dimensioni attuali del file come risoluzione di lavoro. Non applicare un ulteriore ×4 agli asset già ingranditi.
4. Per gli spritesheet estrarre i singoli fotogrammi e ricavare ordine, regioni e durate dalle risorse e dalle scene Godot che li utilizzano.
5. Conservare il file sorgente invariato. Salvare il risultato nella stessa cartella, aggiungendo `-redesign` al nome prima dell'estensione: per esempio, `assets/graphics/ep01_cabin/bed.png` diventa `assets/graphics/ep01_cabin/bed-redesign.png`. Salvare eventuali file di preparazione, confronti e metadati in `../output/spritefusion/<nome-asset>/`.

## Eseguire il redesign

Usare `edit_sprite` con questi input, nell'ordine:

1. Il file da modificare in `godot/assets/graphics`, alle dimensioni attuali, oppure un suo fotogramma estratto nel caso di uno spritesheet.
2. Churchill approvato come riferimento per il grado di dettaglio e il trattamento della pixel art.
3. Quando disponibile, un asset approvato della stessa categoria o lo stesso personaggio nella posa principale, dichiarandone il ruolo nel prompt.

Per un oggetto o un fondale, specificare che Churchill fornisce soltanto un riferimento stilistico: abiti, anatomia e colori del personaggio non devono trasferirsi all'asset. Quando esiste un riferimento più pertinente già approvato, preferirlo per quella categoria.

### Prompt di base

```text
Refine the asset in the first image with finer pixel-level detail within its
existing shapes. Use the second image only as a reference for the amount of
detail, deliberate pixel clusters and shading treatment.

Preserve the first image's subject, recognizable silhouette, proportions,
orientation, perspective, composition and dominant colors. Keep its placement,
important contact points and overall visual footprint close to the source.
Replace coarse block transitions with purposeful finer contours and shading.
Keep broad readable areas and a level of detail consistent with the reference.
Preserve the source's transparency and background treatment.
Keep the primary image's canvas size and visual footprint. Add finer detail
within the existing coarse pixels rather than reducing the image to a coarser
logical pixel grid. The supporting reference guides style, not output resolution.

[Describe the asset and the specific surfaces or features to refine.]
[State the contact points, openings or landmarks that must remain aligned.]
[Explain the role of any additional reference images.]
```

Adattare le ultime righe al soggetto: pieghe e volumi per abiti, venature per legno, giunti e riflessi contenuti per metallo. Conservare i tratti stilizzati dei personaggi; il volto di Churchill approvato resta privo di occhi e bocca disegnati. Non aggiungere elementi narrativi o funzionali assenti dall'originale.

Le dimensioni obiettivo derivano dall'immagine primaria: `edit_sprite` non espone un parametro `size`, quindi il prompt non garantisce il rispetto della risoluzione. Verificare le dimensioni effettive degli output prima di considerarli sostituti utilizzabili. Non imporre automaticamente una palette: mantenere i colori dominanti nel prompt e applicare un vincolo esatto solo quando richiesto.

Ogni chiamata `edit_sprite` costa attualmente 15 crediti. Comunicare il costo prima della generazione e iniziare con una chiamata per asset da valutare. Dopo un timeout controllare `list_assets` prima di qualsiasi nuovo tentativo: il risultato potrebbe essere già salvato e addebitato.

## Valutare i risultati

Scaricare il risultato nativo nella stessa cartella della sorgente con il nome `<nome-originale>-redesign.png`, prima di modificarlo. Se una chiamata produce più varianti, usare `-redesign.png` per la prima e `-redesign-2.png`, `-redesign-3.png` per le successive, mostrandole nel confronto. Conservare eventuali risultati già presenti senza sovrascriverli, proseguendo la numerazione. Annotare prompt, input nell'ordine usato, ID degli asset Sprite Fusion, dimensioni effettive e decisione sul risultato.

Confrontare originale, risultato e riferimento approvato:

- A dimensione effettiva nel gioco, per leggibilità e coerenza del dettaglio.
- Con ingrandimento nearest neighbor, per controllare contorni, cluster e trasparenza.
- Dentro la scena, per verificare ingombro, ancoraggi e continuità con gli altri asset.

Larghezza e altezza devono restare ciascuna tra il 95% e il 105% della corrispondente dimensione della sorgente. Per dimensioni intere, il minimo è `ceil(dimensione × 0.95)` e il massimo è `floor(dimensione × 1.05)`. Per il letto da 140×48 px sono ammesse larghezze da 133 a 147 px e altezze da 46 a 50 px. Un output fuori intervallo è non conforme e non è un sostituto utilizzabile, anche se il disegno è interessante.

Churchill approvato passa da 44 a 46 px di larghezza e rientra nella tolleranza. Valutare anche l'ingombro del soggetto e i punti di contatto; il numero di pixel da solo non misura la compatibilità. Deformazioni, cambi di prospettiva o spostamenti degli ancoraggi richiedono una valutazione distinta.

La prima prova sul letto ha prodotto 70×24 e 80×27 px: entrambi gli output sono non conformi. La causa della riduzione non è accertata. Un eventuale test con input preparati a una risoluzione maggiore serve a verificare un'ipotesi, non costituisce una correzione garantita. Ingrandire un output con nearest neighbor ripristina l'ingombro ma non aggiunge dettaglio; non considerarlo equivalente a un redesign nativo alla risoluzione richiesta.

La seconda prova sul letto usa una copia dell'originale ingrandita esattamente ×2 con nearest neighbor, da 140×48 a 280×96 px, e Churchill come riferimento. Sprite Fusion ha restituito varianti dichiarate da 106×35 e 70×35 px, entrambe fuori tolleranza rispetto all'originale. Questo test non conferma un rapporto fisso fra dimensioni dell'input e dell'output: l'ingrandimento preventivo ×2 non è una soluzione validata e non va applicato automaticamente agli altri asset.

Non ridimensionare, tagliare o aggiungere margini automaticamente per far coincidere le dimensioni. Conservare il risultato nativo e concordare l'eventuale adattamento dopo il confronto. Non rigenerare automaticamente per una lieve differenza di dimensioni.

## Applicare il metodo alle categorie

| Categoria | Vincoli da aggiungere |
| --- | --- |
| Personaggi statici | Identità, posa, proporzioni, quota dei piedi, orientamento e trattamento del volto. Usare la posa approvata come riferimento per le altre. |
| Oggetti della stanza | Base, sagoma, attacchi e punti usati nelle interazioni. Conservare la posizione rispetto al fondale. |
| Icone inventario e cursori | Riconoscibilità alla dimensione effettiva. Per i cursori preservare anche il punto attivo. |
| Stati dello stesso oggetto | Usare lo stato approvato come riferimento comune, mantenendo identiche le parti che non cambiano. |
| Animazioni | Lavorare sui singoli fotogrammi con un riferimento comune. Conservare ordine, durate, ancoraggi e continuità dei volumi; verificare il ciclo in movimento. |
| Fondali | Conservare prospettiva, pavimento, aperture e raccordi con gli oggetti. Validare un primo fondale nella scena prima di estendere il metodo agli altri. |

Non inviare uno spritesheet come se fosse un singolo sprite da ridisegnare. Per mantenere una sequenza esistente, estrarre i fotogrammi e ricomporre il foglio dopo la validazione. Generare una nuova animazione con `animate_sprite` è una scelta separata, perché può cambiare pose e tempi.

## Integrare e riutilizzare

Integrare un risultato dopo l'approvazione visiva, verificando scala, offset, regioni degli atlas e riferimenti delle scene. Mantenere le coordinate di gioco e gli hotspot coerenti con l'ingombro originale. Per un redesign alla stessa risoluzione, conservare la scala esistente salvo un adattamento motivato e verificato.

Ogni nuovo asset approvato amplia i riferimenti disponibili: Churchill resta il riferimento iniziale per i personaggi; il primo oggetto e il primo fondale approvati diventano riferimenti per le rispettive categorie.

### Richiesta riutilizzabile

È sufficiente indicare il percorso dell'asset originale. Il riferimento stilistico predefinito è Churchill approvato; la destinazione deriva automaticamente dal percorso sorgente.

```text
Fai il redesign di [percorso asset originale] seguendo godot/ASSET-REDESIGN.md.
```

Questa richiesta comporta una chiamata `edit_sprite`, con costo comunicato prima della generazione, e il salvataggio nella stessa cartella con il suffisso `-redesign` prima dell'estensione. Mostrare il confronto con l'originale e attendere la scelta dell'utente prima di aggiornare i riferimenti nelle scene. Eventuali vincoli specifici o riferimenti alternativi possono essere aggiunti alla richiesta.

## Documentazione Sprite Fusion

- [Edit e riferimenti visivi](https://www.spritefusion.com/docs/pixel-art-generator/api/generate-and-transform-images)
- [Strumenti MCP e costi](https://www.spritefusion.com/docs/pixel-art-generator/api/mcp)
