extends "res://scripts/world/room.gd"
## Azioni e varianti della cabina; disposizione e risposte statiche sono nella scena.
## Mappa con calamita ancora presente; la scena fornisce entrambe le varianti grafiche.
@export var map_complete_texture: Texture2D
## Mappa dopo la raccolta: cambia la grafica, ma rimane disponibile lo stesso hotspot.
@export var map_collected_texture: Texture2D

## Churchill resta seduto durante le battute iniziali e si rialza alla chiusura.
func introduction(keys: Array[String]) -> Array[Row]:
	if keys.is_empty():
		return []
	var rows: Array[Row] = [row([spriteTo("player", "sit"), say("player", keys[0])])]
	for key in keys.slice(1):
		rows.append(row([say("player", key)]))
	rows.append(row([spriteTo("player", "idle")]))
	return rows

## Prepara le descrizioni della cabina in base al progresso degli enigmi.
func examine(state: State, hotspot_id: String) -> Array[Row]:
	var hotspot := find_hotspot(hotspot_id)
	if hotspot == null:
		return []

	# La mappa descrive l'assenza della calamita dopo la raccolta.
	if hotspot_id == "map" and "ep01_cabin_magnet" in state.collected:
		return [row([say("player", "ep01.cabin.map.examine_without_magnet")], false)]

	# Allo stadio 1 la chiave è visibile nello scarico, ma non ancora raggiungibile.
	if hotspot_id == "sink" and state.get_progress("ep01_cabin", "sink_stage") == 1:
		return [row([say("player", "ep01.cabin.sink.key_unreachable")], false)]

	# Azione standard
	return super.examine(state, hotspot_id)

## Sceglie l'interazione narrativa; tutti gli effetti restano differiti fino all'esecuzione.
func interact(state: State, hotspot_id: String, inventory_item_id_selected: String = "") -> Array[Row]:
	var hotspot := find_hotspot(hotspot_id)
	if hotspot == null:
		return []
	match hotspot_id:
		"sink":
			# Il versamento richiede il Bourbon nell'inventario e il lavandino allo stadio iniziale.
			if inventory_item_id_selected == "ep01_cabin_bottle" and state.has_item(inventory_item_id_selected) and state.get_progress("ep01_cabin", "sink_stage") == 0:
				# Raggiunge il centro del lavandino, parla, consuma il Bourbon e rivela la chiave nello scarico.
				return [
					row([walkTo("player", "sink", true)]),
					row([spriteTo("player", "back"), say("player", "ep01.cabin.sink.pour_bourbon")]),
					row([
						leaveObj("ep01_cabin_bottle"),
						say("player", "ep01.cabin.sink.surprise")
					]),
					row([
						changeStatus("ep01_cabin", "sink_stage", 1),
						say("player", "ep01.cabin.sink.key_found")
					], false)
				]

			# Il recupero richiede l'attrezzo completo nell'inventario e la chiave nello scarico.
			if inventory_item_id_selected == "ep01_cabin_magnet_feather" and state.has_item(inventory_item_id_selected) and state.get_progress("ep01_cabin", "sink_stage") == 1:
				# Churchill recupera la chiave di spalle, al centro del lavandino.
				return [
					row([walkTo("player", "sink", true)]),
					row([
						spriteTo("player", "back"),
						addObj("ep01_cabin_key"),
						changeStatus("ep01_cabin", "sink_stage", 2),
						say("player", "ep01.cabin.sink.key_pickup")
					], false)
				]

			# A mani libere descrive la chiave nello scarico oppure usa la risposta della scena.
			if inventory_item_id_selected.is_empty():
				var response := hotspot.interaction_response
				if state.get_progress("ep01_cabin", "sink_stage") == 1:
					response = "ep01.cabin.sink.key_unreachable"
				return [
					row([walkTo("player", "sink", true)]),
					row([spriteTo("player", "back"), say("player", response)], false)
				]

			# La penna semplice non riesce a recuperare la chiave e non viene consumata.
			if inventory_item_id_selected == "ep01_cabin_feather" and state.has_item(inventory_item_id_selected) and state.get_progress("ep01_cabin", "sink_stage") == 1:
				return [
					row([walkTo("player", "sink", true)]),
					row([spriteTo("player", "back"), say("player", "ep01.cabin.sink.feather_failed")]),
					]

			return [row([say("player", "common.cannot_use")], false)]
		"door":
			# Lo sblocco richiede la chiave nell'inventario e il recupero completato.
			if inventory_item_id_selected == "ep01_cabin_key" and state.has_item(inventory_item_id_selected) and state.get_progress("ep01_cabin", "sink_stage") == 2:
				# «Finalmente...» resta nella cabina; soltanto il clic seguente attraversa la porta.
				return [
					# La chiave si usa al centro della porta, come le altre combinazioni riuscite.
					row([walkTo("player", "door", true)]),
					row([
						leaveObj("ep01_cabin_key"),
						changeStatus("ep01_cabin", "door_unlocked", true),
						spriteTo("player", "back"),
						say("player", "ep01.cabin.door.exit")
					]),
					# Il passaggio usa la destinazione della porta senza ripetere la battuta nella nuova stanza.
					row([changeRoom($door.destination_room, $door.destination_entry)])
				]

			# Gli altri usi di oggetti non aprono la porta.
			if not inventory_item_id_selected.is_empty():
				return [row([say("player", "common.cannot_use")], false)]

			# Dopo lo sblocco il passaggio usa la destinazione configurata nell'hotspot.
			if state.get_progress("ep01_cabin", "door_unlocked"):
				return super.interact(state, hotspot_id)

			# Prima dello sblocco la risposta segue il progresso dell'enigma.
			match state.get_progress("ep01_cabin", "sink_stage"):
				1: return [row([say("player", "ep01.cabin.door.key_needed")], false)]
				2: return [row([say("player", "ep01.cabin.door.ready_to_leave")], false)]

			return [row([say("player", "ep01.cabin.door.locked")], false)]
		"map":
			# Le risposte restano visibili senza richiedere un clic di chiusura.
			# Gli oggetti usati sulla mappa non hanno effetto.
			if not inventory_item_id_selected.is_empty():
				return [row([say("player", "common.cannot_use")], false)]

			# La calamita viene raccolta una volta sola; la mappa rimane esaminabile.
			if "ep01_cabin_magnet" in state.collected or state.has_item("ep01_cabin_magnet"):
				return [row([say("player", "ep01.cabin.map.examine_without_magnet")], false)]
			return [
				row([walkTo("player", "map", true)]),
				row([
					spriteTo("player", "up"),
					addObj("ep01_cabin_magnet"),
					say("player", "ep01.cabin.magnet.pickup")
				], false)
			]

		"como":
			if inventory_item_id_selected.is_empty():
				return [
					row([walkTo("player", hotspot_id, true)]),
					row([spriteTo("player", "down"), say("player", hotspot.interaction_response)], false)
				]
		"oblo1", "oblo2":
			if inventory_item_id_selected.is_empty():
				return [
					row([walkTo("player", hotspot_id, true)]),
					row([spriteTo("player", "back"), say("player", hotspot.interaction_response)], false)
				]
		"bottle":
			# La raccolta standard decide se aggiungere il Bourbon; solo la riuscita richiede la posa.
			var pickup := super.interact(state, hotspot_id, inventory_item_id_selected)
			if pickup[0].actions[0].kind == Step.Kind.ADD:
				pickup[0].actions.push_front(spriteTo("player", "down"))
				pickup.push_front(row([walkTo("player", hotspot_id, true)]))
			return pickup
		"interphone":
			if inventory_item_id_selected.is_empty():
				# Le quattro battute conservano ordine e interlocutori a ogni conversazione.
				return [
					row([say("player", "ep01.cabin.interphone.greeting")]),
					row([say("interphone", "ep01.cabin.interphone.summons")]),
					row([say("interphone", "ep01.cabin.interphone.urgency")]),
					row([say("player", "ep01.cabin.interphone.reply")])
				]

	# Letto, penna e usi generici restano configurati nella scena.
	return super.interact(state, hotspot_id, inventory_item_id_selected)

## Ricostruisce la mappa dal progresso, anche al rientro o caricando una partita precedente.
func sync_from_state(state: State) -> void:
	super.sync_from_state(state)
	$mapMagnet/Visual.texture = map_collected_texture if "ep01_cabin_magnet" in state.collected else map_complete_texture
