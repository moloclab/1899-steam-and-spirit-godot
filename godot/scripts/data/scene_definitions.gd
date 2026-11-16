extends RefCounted
## Legge le risorse incorporate senza istanziare nodi o eseguire il codice delle stanze.
## Il caricamento avviene su richiesta, dopo la compilazione degli script, evitando cicli di preload.
## Variant permette di restituire sia una definizione Resource sia gli elenchi tipizzati della stanza.
static func property(scene_path: String, property_name: String) -> Variant:
	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("Scena non disponibile: " + scene_path)
		return null
	# Il nodo 0 è la radice: qui sono serializzati definition e gli elenchi inventario e ricette.
	var state := scene.get_state()
	for index in state.get_node_property_count(0):
		if state.get_node_property_name(0, index) == property_name:
			return state.get_node_property_value(0, index)
	push_error("Proprietà %s assente in %s" % [property_name, scene_path])
	return null
