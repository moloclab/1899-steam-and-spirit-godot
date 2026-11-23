# Tubo di comunicazione del Leviathan

Una chiamata Sprite Fusion `generate_sprites_in_style`, size 128, costo 15 crediti, quattro varianti native. Prompt e ordine dei riferimenti in request.json; ID e URL in generation.json e downloads.json.

Originale conservato: 24x120, bounds (0,0,24,120), alpha binario. Ancoraggio della scena esistente (478,0); scena attuale composta da interphone_tube.png e interphone.png, non usa ancora interphone_tube_full.png. Nessun riferimento modificato.

| Variante | Canvas | Soggetto | Dimensioni entro tolleranza |
| --- | --- | --- | --- |
| V1 | 128x128 | 24x122 | Si |
| V2 | 128x128 | 29x121 | No, larghezza |
| V3 | 128x128 | 34x121 | No, larghezza |
| V4 | 128x128 | 37x121 | No, larghezza |

Intervallo ammesso: larghezza 23-25, altezza 114-126. Tutte hanno alpha esclusivamente 0/255. Nessun ridimensionamento o modifica dei file nativi scaricati.

Controllo visivo a 4x: contorno scuro presente e generalmente sottile, con ispessimenti nei tappi/flange e raccordi. Non si certifica uno spessore uniforme di un pixel sull'intera sagoma: serve correggere o approvare separatamente questo aspetto prima dell'integrazione. Le zone scure dentro la bocca sono ombre interne, distinte dal bordo esterno.

V1 mantiene l'ingombro ma riduce e riposiziona i collari; V2 conserva meglio la cadenza dei collari e introduce una bocca piu' ramata e staffe laterali. V3 e V4 reinterpretano maggiormente spessore, attacchi e proporzioni. Nessuna variante mantiene esattamente tutti gli attacchi originali: le differenze richiedono valutazione visiva, indipendentemente dalle misure.

comparison.png mostra originale e varianti a 4x nearest neighbor e 1x nativo. context.png e' un confronto statico sul fondale della cabina a 3x, non una cattura Godot: soggetti posizionati con bounds superiori a (478,0), senza integrare le immagini o sovrapporre i vecchi componenti dell'interfono. L'altezza diversa sposta la bocca inferiore, da verificare prima di sostituire i componenti esistenti.

Decisione finale: l'utente ha scelto «usa v4» dopo aver visto dimensioni e osservazioni sul contorno. Integrata V4 come scelta visiva esplicita, inclusi maggiore larghezza, attacchi e trattamento dei raccordi. Rimosse soltanto le aree completamente trasparenti: rettangolo (45,3,37,121), confronto pixel per pixel con il nativo senza differenze. Originale conservato e nativo scelto copiato in interphone_tube_full-selected-native.png.

interphone_tube_full.png ora misura 37x121. In ep01_cabin.tscn sostituisce i due componenti precedenti: un unico Visual sotto interphone, offset (0,-100), attacco superiore globale (478,0). Hotspot della bocca a (478,100), esteso a 37x21. Scala invariata; dialoghi e sequenza invariati. Le varianti e i vecchi asset sono conservati.
