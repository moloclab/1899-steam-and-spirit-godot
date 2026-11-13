extends AnimatedSprite2D
## Personaggio riutilizzabile: movimento e animazioni non dipendono da UI o inventario.
@export var character_id := "player"
@export var speed := 115.0
@export var half_width := 22.0
@export var height := 100.0
@export var idle_animation := "idle"
@export var walk_animation := "walk"
var current_x := 0.0
var target_x := 0.0

## I personaggi collocati nell'editor iniziano dalla propria posizione; il giocatore viene poi posizionato all'ingresso.
func _ready() -> void:
	current_x = position.x + half_width
	target_x = current_x

## Posiziona il personaggio usando centro orizzontale e quota dei piedi, comuni alle stanze.
func place(center_x: float, floor_y: float) -> void:
	current_x = center_x
	target_x = center_x
	position = Vector2(roundf(center_x) - half_width, floor_y - height)
	idle()

## L'arrivo viene verificato anche dal coordinatore e dalle sequenze di azioni.
func has_arrived() -> bool:
	return absf(target_x - current_x) <= 0.1

## Restituisce l'arrivo dopo lo spostamento, senza superare la destinazione.
func advance(delta: float) -> bool:
	var distance := target_x - current_x
	if absf(distance) > 0.1:
		current_x = move_toward(current_x, target_x, speed * delta)
		position.x = roundf(current_x) - half_width
		flip_h = distance < 0
		if sprite_frames.has_animation(walk_animation):
			play(walk_animation)
	else:
		idle()
	# L'ultima frazione di cammino può già avviare un dialogo nello stesso frame: fermiamo subito la camminata.
	if has_arrived():
		idle()
	return has_arrived()

## Un personaggio con una sola animazione, come il marinaio, può mantenere il proprio autoplay.
func idle() -> void:
	if sprite_frames != null and sprite_frames.has_animation(idle_animation):
		play(idle_animation)

## Annulla un percorso senza conservare una destinazione appartenente alla scena precedente.
func stop_walking() -> void:
	target_x = current_x
	idle()
