# Redesign letto, prova same-style 128

Una chiamata Sprite Fusion, costo 15 crediti. Canvas richiesto e restituito: 128x128. L'utente ha autorizzato la prova alla massima larghezza disponibile dopo la segnalazione del limite rispetto all'originale 140x48. Nessun ridimensionamento degli output, nessuna sostituzione dell'originale e nessuna modifica alla scena.

Input ordinati e prompt completo sono registrati in generation.json. I file bed-redesign-2.png fino a bed-redesign-5.png sono nativi, scaricati sia accanto alla sorgente sia in questa cartella. Il suffisso parte da 2 per conservare bed-redesign.png della prova precedente.

| Variante/file | Soggetto | Canvas | Osservazioni |
| --- | --- | --- | --- |
| Originale | 140x48 | 140x48 | Base nella scena a y=200; origine x=18, y=152. |
| 2 | 121x45 | 128x128 | Massima larghezza ottenuta; coperta piu ordinata e tendente al viola, struttura sottile. |
| 3 | 120x44 | 128x128 | Rosso piu vicino all'originale, coperta irregolare, struttura piu aperta. |
| 4 | 120x59 | 128x128 | Maggiore altezza e volume della coperta; viola piu marcato. |
| 5 | 120x39 | 128x128 | Piu basso, rosso vicino all'originale, frontale in legno piu pieno. |

Tutti gli output hanno alpha binario 0/255. Il bordo scuro e presente e generalmente sottile, con ispessimenti locali nei raccordi della struttura e nelle ombre; il requisito rigoroso di spessore uniforme di un pixel non viene certificato come soddisfatto. Nessuna correzione automatica dei pixel o nuova generazione.

Il canvas 128 non garantisce un soggetto largo 128: l'ingombro massimo effettivo e 121. Tutte le varianti sono fuori dalla tolleranza standard di larghezza 133-147 rispetto all'originale, come previsto dalla prova autorizzata. Le altezze sono anch'esse fuori dalla tolleranza standard 46-50.

## Integrazione approvata

L'utente ha scelto esplicitamente la variante 5 dopo il confronto e la segnalazione di dimensioni e contorno. Integrata in bed.png rimuovendo soltanto i margini trasparenti: rettangolo (4,44)-(124,83), dimensioni finali 120x39. Verificata l'identita di tutti i pixel nel ritaglio e l'assenza di pixel visibili nei margini rimossi. Originale e nativo conservati in questa cartella. Nella scena ep01_cabin.tscn la posizione passa da (18,152) a (18,161), mantenendo x=18 e la base a y=200; hotspot aggiornato a 120x39. Le altre varianti restano conservate. Verifica della posa seduta in esecuzione Godot non effettuata.

comparison.png mostra dimensione nativa e ingrandimento nearest neighbor 3x con Churchill e como approvati. scene-comparison.png e una ricomposizione statica del contesto, non una verifica in esecuzione Godot. Mantiene x=18 e la base a y=200, eliminando i margini trasparenti solo nella visualizzazione, senza modificare i file. Non verifica la posa seduta di Churchill, da controllare in caso di integrazione.
