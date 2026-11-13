extends "res://scripts/hotspot.gd"
## Area interattiva figlia di un personaggio: segue lo sprite e ne usa la posizione corrente per l'avvicinamento.
const Room = preload("res://scripts/world/room.gd")

## Converte il centro del personaggio nelle coordinate della stanza anche se è dentro un contenitore.
func approach_position() -> float:
	var character = get_parent()
	var room: Node = character.get_parent()
	while room != null and not room is Room:
		room = room.get_parent()
	if room == null:
		return super.approach_position()
	return room.to_local(character.to_global(Vector2(character.half_width, 0))).x
