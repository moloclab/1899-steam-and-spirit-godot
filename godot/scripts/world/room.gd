extends Node2D
## La stanza conserva i riferimenti ai propri hotspot, inclusi quelli in contenitori annidati.
const Definition = preload("res://scripts/data/room_definition.gd")
@export var definition: Definition
var _cached_hotspots: Array[Node2D] = []
var _dirty := true

## Le modifiche alla UI o ad altre stanze non invalidano gli hotspot di questa stanza.
func _ready() -> void:
	get_tree().node_added.connect(_hotspot_tree_changed)
	get_tree().node_removed.connect(_hotspot_tree_changed)

## node_removed copre anche gli hotspot rimossi insieme a un contenitore annidato.
func _hotspot_tree_changed(node: Node) -> void:
	if node is Hotspot and (is_ancestor_of(node) or node in _cached_hotspots):
		_invalidate()

## Ricostruisce la lista solo quando cambia l'albero; la visibilità viene verificata alla lettura.
func _invalidate() -> void:
	_dirty = true

## Gli ID sono univoci nella stanza; un errore viene segnalato quando si aggiorna la cache.
func hotspots(visible_only: bool = true) -> Array[Node2D]:
	if _dirty:
		_cached_hotspots.clear()
		var ids := {}
		for node in find_children("*", "", true, false):
			if node is Hotspot:
				if node.hotspot_id.is_empty() or ids.has(node.hotspot_id):
					push_error("ID hotspot vuoto o duplicato in %s: %s" % [definition.room_id, node.hotspot_id])
				ids[node.hotspot_id] = true
				_cached_hotspots.append(node)
		_dirty = false
	var result: Array[Node2D] = []
	for hotspot in _cached_hotspots:
		if is_instance_valid(hotspot) and not hotspot.is_queued_for_deletion() \
			and is_ancestor_of(hotspot) and (not visible_only or hotspot.is_visible_in_tree()):
			result.append(hotspot)
	return result
