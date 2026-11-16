extends RefCounted
## Conserva soltanto l'intenzione del giocatore durante l'avvicinamento, senza modificare enigmi.
const Step = preload("res://scripts/actions/action_step.gd")
var _pending: Dictionary = {}

## Il bersaglio viene identificato per ID nella stanza corrente, mai conservato come nodo differito.
func request(hotspot: Hotspot, item_id: String, examining: bool, rooms) -> void:
	_pending = {"target": hotspot.hotspot_id, "item": item_id, "examining": examining}
	rooms.actor.target_x = rooms.current_room.definition.clamp_x(
		hotspot.approach_position(rooms.actor.current_x, rooms.actor.half_width))

## Cancella la richiesta e ferma il movimento senza alterare inventario e progressi.
func cancel(rooms) -> void:
	_pending.clear()
	if is_instance_valid(rooms.actor):
		rooms.actor.stop_walking()

## La validità e il possesso dell'oggetto vengono rivalutati dopo l'avvicinamento.
func take_ready_actions(state, rooms) -> Array[Step]:
	if _pending.is_empty() or not rooms.actor.has_arrived():
		return []
	# Consuma l’intenzione una sola volta, prima che una sequenza possa causare un cambio stanza.
	var request_data := _pending.duplicate()
	_pending.clear()
	var hotspot: Hotspot = rooms.find_hotspot(request_data.target)
	if hotspot == null:
		return []
	# La stanza decide le regole narrative; questo coordinatore gestisce soltanto l’avvicinamento.
	return rooms.current_room.actions(state, request_data.target, request_data.item, request_data.examining)
