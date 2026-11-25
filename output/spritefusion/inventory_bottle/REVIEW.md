# Bottiglia whiskey da inventario

Metodo: Sprite Fusion `generate_sprites_in_style`, size 48, una chiamata da 15 crediti. Prompt completo, riferimenti ordinati, URL e ID dei nove risultati in `generation.json`.

Originale: canvas 50x50, soggetto 12x30, bounds [19,10,31,40], alpha binario. Base piatta, orientamento verticale. Riferimento ambiente: canvas e soggetto 30x12, bottiglia orizzontale. Tolleranza intera per il soggetto inventario: larghezza 12, altezza 29-31.

Tutti gli output nativi sono 48x48 e hanno alpha binario. Le misure dei soggetti sono in `measurements.json` e nel confronto `comparison.png` (scala UI 2x e ingrandimento nearest neighbor 6x). Tutti superano la tolleranza: V1 15x46; V2 16x45; V3 16x46; V4 13x46; V5 14x46; V6 17x45; V7 15x45; V8 16x45; V9 14x46.

Revisione visiva: bottiglie singole verticali, contorno scuro prevalentemente di un pixel, diagonali a gradini e nessun alone visibile. V1 e V2 introducono etichette frastagliate meno fedeli al riferimento; V3 mantiene una larga etichetta rettangolare, V7 conserva maggiormente il disegno dell'icona originale. Il bordo e la compatibilita nell'inventario andranno verificati sulla variante scelta prima dell'integrazione.

Decisione 2026-11-25: l'utente ha scelto V7 dopo la comunicazione delle dimensioni maggiori. Deroga limitata a questo asset. Integrata in `godot/assets/graphics/ep01_cabin/inventory_bottle.png`: soggetto 15x45 a (17,2) su canvas trasparente 50x50; margini sinistra/destra 17/18 e sopra/sotto 2/3. Verificati pixel identici al nativo, alpha binario e margini trasparenti. Output nativo e backup originale conservati. Riferimento della scena gia corretto, nessuna modifica necessaria. Verifica visiva eseguita sul PNG; prova nel gioco non eseguita.
