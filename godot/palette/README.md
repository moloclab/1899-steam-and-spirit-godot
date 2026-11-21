# Palette base di 1899

Prima palette di riferimento da 128 colori, estratta dagli asset di `../../EP01/img`. Serve come base flessibile per il redesign: sono ammesse sfumature aggiuntive coerenti con materiali, luce e leggibilità. Non è un limite tecnico ai colori del gioco.

## File

- `1899-base-128.png`: tavola con i codici HEX, ordinata per famiglie cromatiche e luminosità all'interno delle famiglie. Le righe non rappresentano rampe di uno specifico materiale.
- `1899-base-128-swatches.png`: gli stessi 128 colori senza testo, in una griglia di 16 colonne per 8 righe, da usare come riferimento visivo.
- `1899-base-128.gpl`: palette importabile negli editor compatibili con il formato GIMP Palette.
- `1899-base-128.json`: elenco ordinato dei codici HEX; `strict: false` indica l'uso flessibile.

## Estrazione

Sono stati analizzati tutti i 383 GIF e i 23 JPG della cartella, per complessivi 615 fotogrammi. L'unico ICO, `favicon.ico`, è escluso perché è un contenitore di icone per il browser con più risoluzioni. Sono esclusi i pixel completamente trasparenti.

La selezione usa questi passaggi:

1. Istogramma dei pixel visibili di ogni file, includendo tutti i fotogrammi delle GIF animate. Ogni file viene normalizzato, così dimensioni e numero di fotogrammi non ne aumentano il peso complessivo.
2. Media degli istogrammi per famiglia di soggetti e poi per categoria. Le famiglie raggruppano, tramite il nome, le pose principali di personaggi, alcuni stati di oggetti, i tutorial e le varianti del cielo. La classificazione è euristica ed è consultabile in `../../output/palette/sources.csv`; non costituisce una deduplicazione visiva completa.
3. Pesi di categoria: fondali 25%, oggetti della scena 30%, personaggi 25%, inventario 15%, interfaccia e tutorial 5%. Sono scelte progettuali per bilanciare il contenuto, non frequenze grezze dei pixel.
4. Raggruppamento RGB a 5 bit per canale per attenuare le piccole variazioni, incluse quelle dei JPG. Per ciascun gruppo si preferisce un colore presente nei GIF, quando disponibile.
5. Clustering pesato in CIELAB, con inizializzazione deterministica, seguito dalla scelta di un colore sorgente rappresentativo per ciascuno dei 128 gruppi. I colori finali provengono dalle immagini, senza inventare valori intermedi.

I bruni, gli ocra e i verdi desaturati prevalgono perché caratterizzano le sorgenti. I colori freddi e saturi hanno una presenza più contenuta. La palette è una prima proposta estratta automaticamente e controllata nella tavola colori; resta da validare nelle scene e su un primo redesign. Non è stata imposta retroattivamente a Churchill o agli altri asset approvati, e non è stata ancora ottimizzata rispetto ai loro colori.

## Uso nel redesign

Seguire `../ASSET-REDESIGN.md`. Usare la palette per orientare tonalità, ombre e luci, preservando i colori distintivi del soggetto. La tavola dei campioni guida soltanto i colori, non composizione o forma dell'asset. Sono consentiti colori aggiuntivi; non quantizzare automaticamente gli output ai soli colori della palette.

## Riproduzione

Dalla radice del progetto, su Windows con PowerShell e System.Drawing:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File output/palette/build-palette.ps1
```

Lo script rigenera i quattro file della palette e l'inventario `output/palette/sources.csv`. Le immagini sorgenti non vengono modificate. Lo stesso contenuto sorgente produce lo stesso elenco di colori.
