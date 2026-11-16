extends RefCounted
## Carica una stanza alla volta e applica camera e configurazione senza regole specifiche della cabina.
const Catalog = preload("res://scripts/data/room_catalog.gd")
const Room = preload("res://scripts/world/room.gd")
const Character = preload("res://scripts/world/character.gd")
const PLAYER = preload("res://scenes/characters/churchill.tscn")
var current_room: Room
var actor: Character
var _paused_speeds: Dictionary = {}

## Il caricamento resta sincrono. La vecchia scena viene sostituita solo dopo aver preparato la nuova.
func load_room(state, host: Control) -> bool:
	var definition = Catalog.get_room(state.room)
	if definition == null:
		return false
	var scene: PackedScene = load(definition.scene_path)
	if scene == null:
		return false
	var room = scene.instantiate()
	if not room is Room or room.definition != definition:
		room.free()
		push_error("Definizione incoerente nella scena: " + definition.scene_path)
		return false
	if is_instance_valid(current_room):
		current_room.get_parent().remove_child(current_room)
		current_room.queue_free()
	_paused_speeds.clear()
	current_room = room
	current_room.scale = Vector2.ONE * definition.visual_scale
	host.add_child(current_room)
	actor = PLAYER.instantiate()
	current_room.add_child(actor)
	state.player_x = definition.clamp_x(state.player_x)
	actor.place(state.player_x, definition.floor_y)
	position_world(host.size.x)
	return true

## Una stanza stretta viene centrata; una larga segue il personaggio entro i bordi del fondale.
func position_world(view_width: float) -> void:
	var definition: Resource = current_room.definition
	var scaled_width: float = definition.width * definition.visual_scale
	var offset: float = (view_width - scaled_width) / 2.0
	if scaled_width > view_width:
		offset = clampf(view_width / 2.0 - actor.current_x * definition.visual_scale, view_width - scaled_width, 0)
	current_room.position = Vector2(offset, 0)

## Cerca nuovamente il bersaglio all'arrivo: un oggetto nascosto o rimosso non può agire.
func find_hotspot(hotspot_id: String) -> Hotspot:
	# La ricerca appartiene alla stanza, che mantiene la cache e controlla la visibilità corrente.
	return current_room.find_hotspot(hotspot_id)

## Gli attori della stanza possono partecipare alle sequenze usando un ID indipendente dal nodo.
func character(character_id: String) -> Character:
	if character_id == "player":
		return actor
	for node in current_room.find_children("*", "AnimatedSprite2D", true, false):
		if node is Character and node.character_id == character_id:
			return node
	return null

## Risolve il soggetto di un'azione nella stanza corrente senza conservare nodi differiti.
func subject(subject_id: String) -> Node2D:
	var person := character(subject_id)
	if person != null:
		return person
	return find_hotspot(subject_id)

## Risolve lo speaker nella stanza corrente senza conservare nodi dopo una transizione.
func speech_target(speaker_key: String) -> Node2D:
	if actor.speaker_key == speaker_key:
		return actor
	for node in current_room.find_children("*", "AnimatedSprite2D", true, false):
		if node is Character and node.speaker_key == speaker_key:
			return node
	for hotspot in current_room.hotspots():
		if hotspot.speaker_key == speaker_key:
			return hotspot
	return null

## Il menu sospende anche le animazioni: un'azione non termina mentre la sequenza è in pausa.
func pause_animations(paused: bool) -> void:
	if paused:
		for node in current_room.find_children("*", "AnimatedSprite2D", true, false):
			if not _paused_speeds.has(node):
				_paused_speeds[node] = node.speed_scale
				node.speed_scale = 0.0
	else:
		for node in _paused_speeds:
			if is_instance_valid(node):
				node.speed_scale = _paused_speeds[node]
		_paused_speeds.clear()
