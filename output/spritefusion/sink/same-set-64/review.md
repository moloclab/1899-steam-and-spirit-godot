# Lavabo abbinato al comò: prima prova

Una chiamata `generate_sprites_in_style`, `size: 64`, costo 15 crediti, nove risultati. Riferimenti nell'ordine: lavabo originale, Churchill per dettaglio e contorno, comò attualmente integrato come riferimento prioritario del set di mobili, palette 128 come sola guida cromatica flessibile. Nessun vincolo esatto tramite parametro `palette`.

Gli output nativi sono salvati accanto alla sorgente da `sink-redesign.png` a `sink-redesign-9.png`. Sorgente e scene non sono state modificate. `sink-original.png` conserva l'input della prova. Prompt, ordine degli input, ID e URL sono in `request.json`, `generation.json` e `downloads.json`.

## Misure

La sorgente ha canvas e soggetto visibile 40×56 px. Sono ammessi 38–42 px di larghezza e 54–58 px di altezza. Tutti i risultati hanno canvas 64×64 e alpha binario 0/255.

| Variante | Soggetto visibile | Coerenza con il set e osservazioni |
| --- | --- | --- |
| 1 | 38×62 | Pannello, legno desaturato e piedini sagomati vicini al comò; tono leggermente più violaceo. |
| 2 | 37×62 | Legno più rosso e frontale semplificato; aggiunge un elemento sul bordo della vasca. |
| 3 | 38×62 | Introduce un cassetto assente dalla sorgente e non richiesto. |
| 4 | 36×62 | Buon abbinamento di legno, pannello e ferramenta; più stretto e alto del previsto. |
| 5 | 36×60 | Legno più rossastro del comò e minore corrispondenza della ferramenta. |
| 6 | 35×60 | Buona sobrietà, ma cornici più semplici e sagoma stretta. |
| 7 | 36×60 | Dettagli e rivetti coerenti con il set; ingombro comunque fuori tolleranza. |
| 8 | 36×60 | Colore più grigio e frontale semplificato rispetto al comò. |
| 9 | 35×60 | Legno molto più aranciato del comò; abbinamento meno riuscito. |

Nessuna variante rispetta entrambe le tolleranze dimensionali: tutte sono troppo alte e solo 1 e 3 rispettano la larghezza. Le dimensioni native sono state conservate senza ridimensionare, ritagliare, aggiungere margini o rigenerare per compensare lo scostamento. Una scelta visiva deve includere una deroga esplicita alle dimensioni prima dell'integrazione.

## Contorno e confronto

I risultati mostrano un contorno esterno scuro leggibile e generalmente sottile; 1 e 4 sono i candidati più utili al confronto con il comò. Le linee della vasca e della ferramenta presentano piccoli cluster scuri più ampi, da distinguere dal bordo esterno. Non considerare la sola presenza del contorno una certificazione automatica dello spessore uniforme di un pixel lungo ogni raccordo.

`comparison.png` mostra i riferimenti, le varianti a 4× nearest neighbor e un campione nativo di ciascuna. `context.png` mostra un montaggio statico a 2× sul fondale della cabina, insieme al comò e al calamaio alle coordinate della scena. Per il confronto, il rettangolo visibile di ogni lavabo è appoggiato alla base y=200 e al lato x=272, senza scalare i suoi pixel. L'altezza extra emerge sopra la posizione originale: il montaggio non nasconde lo scostamento né modifica gli output.

Il contesto è un'anteprima statica, non una cattura o un test in Godot.

## Scelta e integrazione

L'utente ha scelto la variante 4 dopo la segnalazione delle dimensioni fuori tolleranza e ha chiesto di eliminare le altre. Integrato il rettangolo visibile (14, 1, 36, 62) in `sink.png`, rimuovendo soltanto margini completamente trasparenti e verificando ogni pixel rispetto al nativo. Conservati `sink-selected-native.png` e `sink-original.png` in questa cartella.

La posizione nella scena passa da (272, 144) a (272, 138), e l'hotspot da 40×56 a 36×62: la base resta a y=200, senza cambio di scala. Eliminate le altre otto varianti locali e gli eventuali `.import` dopo il controllo dei riferimenti. Conservata la variante 4 anche accanto alla sorgente. La libreria Sprite Fusion resta invariata.

I confronti e `downloads.json` documentano la generazione iniziale: i percorsi delle varianti eliminate sono storici. Stato finale: variante 4 integrata con deroga dimensionale scelta dall'utente; nessuna seconda generazione. Verifiche statiche e confronto dei pixel completati; gioco non avviato per questa integrazione.
