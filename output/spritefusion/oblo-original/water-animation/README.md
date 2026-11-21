# Animazione locale dell'acqua

Integrata su richiesta dell'utente a partire dalla variante 2 approvata. Nessuna chiamata a Sprite Fusion e nessun credito consumato.

`generate.ps1` riproduce il foglio `godot/assets/graphics/ep01_cabin/oblo.png`: 12 fotogrammi orizzontali da 43×43, canvas 516×43, riprodotti a 5 fps in un ciclo di 2,4 secondi. La scena `ep01_cabin.tscn` condivide lo stesso SpriteFrames tra i due oblò, con autoplay e loop. Posizioni, offset e hotspot conservati.

Il primo fotogramma è identico alla variante statica approvata, ritagliata dei soli margini trasparenti. La deformazione locale interessa esclusivamente pixel azzurri/verdi della superficie e delle increspature, tra x=9–33 e y=18–26. Oscillazione di circa un pixel con attenuazione in profondità. Cornice, contorno, riflesso superiore, ombre sul bordo interno e alpha sono invariati. I PNG dei fotogrammi e `frames.png` consentono il confronto senza alterare l'originale nativo.

Verifiche: import Godot riuscito; `check_animation.gd` passa con lettura delle texture importate, confronto pixel, autoplay di entrambi gli oblò, avanzamento dei frame e ritorno dal frame finale al primo. `git diff --check` superato. Non eseguita una valutazione visiva del gioco in una finestra interattiva; controllato il confronto dei fotogrammi ingranditi nearest-neighbor. La suite generale non è stata ripetuta, considerate le anomalie già registrate nella prova statica.
