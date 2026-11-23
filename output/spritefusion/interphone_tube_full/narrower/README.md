# Tubo meno largo

Modifica diretta richiesta dall'utente sulla V4 integrata: larghezza da 37 a 19 px (circa meta', arrotondata al pixel intero), altezza invariata a 121 px. Sostituisce la prima riduzione a 29 px rifiutata dall'utente. Campionamento orizzontale nearest neighbor dalla V4 originale, senza interpolazione, sfocatura o nuovi colori. Anche imboccatura e collari mantengono la stessa riduzione orizzontale.

File finale: godot/assets/graphics/ep01_cabin/interphone_tube_full.png. Attacco superiore (478,0), scala e offset invariati. L'hotspot in ep01_cabin.tscn misura ora 19x21. Nessuna chiamata Sprite Fusion.

before-37x121.png conserva la versione precedente; comparison.png mostra prima/dopo a 4x nearest neighbor. Il risultato cambia esplicitamente le proporzioni orizzontali della variante scelta, come richiesto. I materiali nella cartella same-style-128 documentano la generazione e l'integrazione precedenti a questa modifica.
