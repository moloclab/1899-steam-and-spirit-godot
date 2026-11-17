extends Node2D
## La stanza conserva i riferimenti ai propri hotspot, inclusi quelli in contenitori annidati.
const Definition = preload("res://scripts/data/room_definition.gd")
const State = preload("res://scripts/game_state.gd")
const Step = preload("res://scripts/actions/action_step.gd")
const ItemDefinition = preload("res://scripts/data/item_definition.gd")
## Metadati usati da ingressi, movimento e catalogo delle stanze.
@export var definition: Definition
## Le definizioni inventario appartengono alla stanza di origine, anche quando non è caricata.
@export var inventory_definitions: Array[ItemDefinition] = []
## Gli hotspot sono definiti nella scena e raccolti al caricamento; cambia soltanto la visibilità.
var _cached_hotspots: Array[Node2D] = []

## Le stanze specializzano questo ingresso per azioni narrative e conversazioni.
func actions(state: State, hotspot_id: String, item_id: String = "", examining: bool = false) -> Array[Step]:
	# Il percorso predefinito lascia all’hotspot le sole regole condivise; le stanze possono specializzarlo.
	var hotspot := find_hotspot(hotspot_id)
	return hotspot.actions(state, item_id, examining) if hotspot != null else []

## La ricerca esclude anche gli oggetti nascosti da un antenato o già rimossi.
func find_hotspot(hotspot_id: String) -> Hotspot:
	for hotspot in hotspots():
		if hotspot.hotspot_id == hotspot_id:
			return hotspot
	return null

## Ripristina anche gli oggetti nascosti, poi le sottoclassi aggiornano le proprie varianti.
func sync_from_state(state: State) -> void:
	for hotspot in hotspots(false):
		hotspot.sync_from_state(state)

## Registra una sola volta anche gli hotspot in contenitori, verificando gli ID della stanza.
func _ready() -> void:
	var ids := {}
	for node in find_children("*", "", true, false):
		if node is Hotspot:
			if node.hotspot_id.is_empty() or ids.has(node.hotspot_id):
				push_error("ID hotspot vuoto o duplicato in %s: %s" % [definition.room_id, node.hotspot_id])
			ids[node.hotspot_id] = true
			_cached_hotspots.append(node)

## La lista resta stabile; visibilità e validità vengono rivalutate a ogni richiesta.
func hotspots(visible_only: bool = true) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for hotspot in _cached_hotspots:
		if is_instance_valid(hotspot) and not hotspot.is_queued_for_deletion() \
			and is_ancestor_of(hotspot) and (not visible_only or hotspot.is_visible_in_tree()):
			result.append(hotspot)
	return result
