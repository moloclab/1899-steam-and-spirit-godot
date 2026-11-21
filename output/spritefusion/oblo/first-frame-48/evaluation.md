# Oblò: prova del primo fotogramma

Una chiamata `generate_sprites_in_style`, size 48, costo 15 crediti, nove risultati. Prompt, riferimenti ordinati e ID degli asset sono in `request.json`; misure in `metrics.json`. Il foglio originale e la scena Godot restano invariati. Le copie native sono conservate qui e in `godot/assets/graphics/ep01_cabin/oblo-redesign*.png`.

Soggetto descritto dall'utente: oblò di un sottomarino, bordo in ottone, vetro trasparente e acqua del mare visibile fino a circa metà apertura.

Tutti i canvas sono 48×48 e tutti gli alpha sono binari (0/255). La sorgente visibile misura 48×48; tolleranza dimensionale: 46–50 px per asse.

Le varianti 1 (47×48) e 2 (47×46) rispettano le dimensioni. Le varianti 3–9 hanno soggetti visibili da 23–24 px per asse: fuori tolleranza, senza ridimensionamento o rigenerazione automatica.

Il contorno scuro è presente, ma le varianti 1 e 2 hanno tratti spessi due pixel e non rispettano ancora il requisito uniforme di un pixel. Conferma tramite lettura del bordo superiore centrale: variante 1, x=24, y=0–1, RGB 28/14/13; variante 2, x=24, y=1–2, RGB 28/15/11. Occorre correggere il bordo prima di un'eventuale integrazione, dopo la scelta visiva. Non sono state apportate correzioni ai nativi.

La variante 1 ha ottone più luminoso e acqua a metà; la 2 ha ottone più spento e un riflesso diagonale evidente sul vetro. Le superfici dell'acqua sono molto semplici: il movimento sarà valutato dopo la scelta del fotogramma base. Nessuna animazione nuova è stata generata e nessuna variante è stata integrata o provata nella scena.
