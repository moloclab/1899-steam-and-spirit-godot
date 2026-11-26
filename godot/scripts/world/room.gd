extends Node2D
## La stanza conserva i riferimenti ai propri hotspot, inclusi quelli in contenitori annidati.
const Definition = preload("res://scripts/data/room_definition.gd")
const State = preload("res://scripts/game_state.gd")
const Step = preload("res://scripts/actions/action_step.gd")
const Row = preload("res://scripts/actions/action_row.gd")
const ItemDefinition = preload("res://scripts/data/item_definition.gd")
## Metadati usati da ingressi, movimento e catalogo delle stanze.
@export var definition: Definition
## Le definizioni inventario appartengono alla stanza di origine, anche quando non è caricata.
@export var inventory_definitions: Array[ItemDefinition] = []
## Gli hotspot sono definiti nella scena e raccolti al caricamento; cambia soltanto la visibilità.
var _cached_hotspots: Array[Node2D] = []

## Raggruppa azioni simultanee; il requisito viene letto soltanto quando la riga parte.
## Con confirm false la riga avanza da sola, conservando comunque le attese bloccanti.
func row(steps: Array[Step], condition: Callable = Callable(), confirm: bool = true) -> Row:
	return Row.of(steps, condition, confirm)

## Accoda una battuta con il soggetto esplicito prima della chiave del testo.
func say(subject: String, key: String) -> Step:
	return Step.say(subject, key)

## Accoda una posa con soggetto esplicito; soltanto le animazioni finite possono richiedere l'attesa.
func spriteTo(subject: String, animation: String, wait: bool = false) -> Step:
	return Step.animate(subject, animation, wait)

## Accoda il cammino del soggetto esplicito fino al bordo o al centro di un hotspot.
func walkTo(subject: String, hotspot: String, center: bool = false) -> Step:
	return Step.walkTo(subject, hotspot, center)

## Rimuove un oggetto dall'inventario soltanto quando viene eseguita la riga.
func leaveObj(item: String) -> Step:
	return Step.leaveObj(item)

## Aggiunge un oggetto all'inventario soltanto quando viene eseguita la riga.
func addObj(item: String) -> Step:
	return Step.addObj(item)

## Cambia stanza durante l'esecuzione; il passaggio deve occupare una riga propria.
func changeRoom(room_id: String, entry_id: String = "default") -> Step:
	return Step.changeRoom(room_id, entry_id)

## Cambia un progresso soltanto quando viene eseguita la riga, usando lo schema dello stato.
func changeStatus(scope: String, key: String, value: Variant) -> Step:
	return Step.changeStatus(scope, key, value)

## Le battute iniziali usano lo stesso motore delle interazioni; la stanza può aggiungere pose.
func introduction(keys: Array[String]) -> Array[Row]:
	var rows: Array[Row] = []
	for key in keys:
		rows.append(row([say("player", key)]))
	return rows

## Delega l'esame all'hotspot; le stanze possono specializzare le descrizioni narrative.
func examine(state: State, hotspot_id: String) -> Array[Row]:
	var hotspot := find_hotspot(hotspot_id)
	return hotspot.examine(state) if hotspot != null else []

## Delega le interazioni comuni all'hotspot, compreso l'eventuale uso di un oggetto.
func interact(state: State, hotspot_id: String, item_id: String = "") -> Array[Row]:
	var hotspot := find_hotspot(hotspot_id)
	return hotspot.interact(state, item_id) if hotspot != null else []

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
