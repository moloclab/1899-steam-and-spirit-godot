extends "res://scripts/world/room.gd"
## Azioni e varianti della cabina; disposizione e risposte statiche sono nella scena.
## Mappa con calamita ancora presente; la scena fornisce entrambe le varianti grafiche.
@export var map_complete_texture: Texture2D
## Mappa dopo la raccolta: cambia la grafica, ma rimane disponibile lo stesso hotspot.
@export var map_collected_texture: Texture2D

## Churchill resta seduto durante le quattro battute iniziali e si rialza alla chiusura.
func introduction(keys: Array[String]) -> Array[Row]:
	var rows := super.introduction(keys)
	if not rows.is_empty():
		rows[0].actions.append(Step.animate("sit"))
		rows.append(Row.of([Step.animate("idle")]))
	return rows

## Pianifica senza effetti: possesso e condizioni vengono rivalutati durante l'esecuzione.
func actions(state: State, hotspot_id: String, item_id: String = "", examining: bool = false) -> Array[Row]:
	var hotspot := find_hotspot(hotspot_id)
	if hotspot == null:
		return []
	# Le scene narrative mantengono battute ed effetti separati, senza anticipare i consumi.
	if not examining and state.has_item(item_id):
		if hotspot_id == "sink" and item_id == "ep01_cabin_bottle" and state.get_progress("ep01_cabin", "sink_stage") == 0:
			var context := {"started": false, "poured": false}
			return [
				Row.of([Step.effect(_begin_pouring.bind(state, context)), Step.animate("back")]),
				Row.of([Step.effect(drop_bottle.bind(state, context))]),
				Row.of([Step.effect(_reveal_key.bind(state, context))])
			]
		if hotspot_id == "door" and item_id == "ep01_cabin_key" and state.get_progress("ep01_cabin", "sink_stage") == 2:
			return [Row.of([Step.effect(use_key.bind(state)), Step.animate("back")]), Row.of([Step.effect(_leave_after_unlock.bind(state))])]
	# Il Callable rinvia le mutazioni al motore delle sequenze, dopo la scelta e l’avvicinamento.
	if hotspot_id in ["map", "sink", "door"]:
		return [Row.of([Step.effect(_execute.bind(state, hotspot_id, item_id, examining))])]
	# Letto, oblò e raccoglibili mantengono i comportamenti comuni configurati nella scena.
	return hotspot.actions(state, item_id, examining)

## La lente ha precedenza sull'oggetto selezionato; gli usi richiedono il possesso corrente.
func _execute(state: State, hotspot_id: String, item_id: String, examining: bool) -> String:
	var hotspot := find_hotspot(hotspot_id)
	if hotspot == null:
		return "common.cannot_use"
	# Le descrizioni variabili dipendono dal progresso; le altre usano il testo statico del nodo.
	if examining:
		if hotspot_id == "map":
			return "ep01.cabin.map.examine_without_magnet" if "ep01_cabin_magnet" in state.collected else hotspot.examine_response
		if hotspot_id == "sink" and state.get_progress("ep01_cabin", "sink_stage") == 1:
			return "ep01.cabin.sink.key_unreachable"
		return hotspot.examine(state)
	if not item_id.is_empty() and not state.has_item(item_id):
		return "common.cannot_use"
	# Gli ID identificano gli oggetti logici anche quando il nome del nodo è diverso, come sinkNormal.
	match hotspot_id:
		"map":
			if item_id.is_empty():
				return "ep01.cabin.magnet.pickup" if state.pick_up("ep01_cabin_magnet") else "ep01.cabin.map.examine_without_magnet"
		"sink":
			if item_id.is_empty():
				return "ep01.cabin.sink.key_unreachable" if state.get_progress("ep01_cabin", "sink_stage") == 1 else hotspot.interaction_response
			if item_id == "ep01_cabin_magnet_feather":
				return collect_key(state)
			if item_id == "ep01_cabin_feather" and state.get_progress("ep01_cabin", "sink_stage") == 1:
				return "ep01.cabin.sink.feather_failed"
		"door":
			if item_id == "ep01_cabin_key":
				return use_key(state)
			if item_id.is_empty():
				return _open_door(state)
	return "common.cannot_use"

## La prima battuta precede il consumo; il contesto vale soltanto per questa sequenza.
func _begin_pouring(state: State, context: Dictionary) -> String:
	context.started = state.has_item("ep01_cabin_bottle") and state.get_progress("ep01_cabin", "sink_stage") == 0
	return "ep01.cabin.sink.pour_bourbon" if context.started else "common.cannot_use"

## La seconda battuta consuma il Bourbon; una richiesta divenuta invalida non produce effetti.
func drop_bottle(state: State, context: Dictionary) -> String:
	if not context.started or not state.has_item("ep01_cabin_bottle") or state.get_progress("ep01_cabin", "sink_stage") != 0:
		return "common.cannot_use"
	state.remove_item("ep01_cabin_bottle")
	context.poured = true
	return "ep01.cabin.sink.surprise"

## La chiave diventa recuperabile solo insieme alla terza battuta, come nell'originale.
func _reveal_key(state: State, context: Dictionary) -> String:
	if not context.poured or state.get_progress("ep01_cabin", "sink_stage") != 0:
		return "common.cannot_use"
	# Stadi del lavandino: 0 iniziale, 1 chiave nello scarico, 2 chiave recuperata.
	state.set_progress("ep01_cabin", "sink_stage", 1)
	return "ep01.cabin.sink.key_found"

## La penna magnetica recupera la chiave senza poterla duplicare.
func collect_key(state: State) -> String:
	if not state.has_item("ep01_cabin_magnet_feather") or state.get_progress("ep01_cabin", "sink_stage") != 1:
		return "common.cannot_use"
	state.add_item("ep01_cabin_key")
	state.set_progress("ep01_cabin", "sink_stage", 2)
	return "ep01.cabin.sink.key_pickup"

## Lo sblocco persistente consente di attraversare la porta anche dopo il consumo della chiave.
func use_key(state: State) -> String:
	if not state.has_item("ep01_cabin_key") or state.get_progress("ep01_cabin", "sink_stage") != 2:
		return "common.cannot_use"
	state.remove_item("ep01_cabin_key")
	# Il flag sopravvive al cambio stanza e al salvataggio, indipendentemente dal possesso della chiave.
	state.set_progress("ep01_cabin", "door_unlocked", true)
	# Il passaggio al corridoio è il passo successivo: «Finalmente...» resta nella cabina.
	return "ep01.cabin.door.exit"

## Il secondo passo attraversa la porta senza ripetere la battuta nel corridoio.
func _leave_after_unlock(state: State) -> String:
	if not state.get_progress("ep01_cabin", "door_unlocked"):
		return "common.cannot_use"
	var response: String = $door.interact(state)
	return "" if state.room != definition.room_id else response

## L'uscita generica risolve la destinazione; la stanza aggiunge il vincolo dell'enigma.
func _open_door(state: State) -> String:
	if state.get_progress("ep01_cabin", "door_unlocked"):
		return $door.interact(state)
	match state.get_progress("ep01_cabin", "sink_stage"):
		1: return "ep01.cabin.door.key_needed"
		2: return "ep01.cabin.door.ready_to_leave"
	return "ep01.cabin.door.locked"

## Ricostruisce la mappa dal progresso, anche al rientro o caricando una partita precedente.
func sync_from_state(state: State) -> void:
	super.sync_from_state(state)
	$mapMagnet/Visual.texture = map_collected_texture if "ep01_cabin_magnet" in state.collected else map_complete_texture
