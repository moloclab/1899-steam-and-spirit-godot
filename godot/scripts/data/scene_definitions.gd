extends RefCounted
## Legge le risorse incorporate senza istanziare nodi o eseguire gli script delle scene.
## Il caricamento avviene su richiesta, dopo la compilazione degli script, evitando cicli di preload.
## Variant permette di restituire sia una definizione Resource sia elenchi tipizzati.
static func property(scene_path: String, property_name: String) -> Variant:
	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("Scena non disponibile: " + scene_path)
		return null
	# Il nodo 0 è la radice: contiene le proprietà serializzate della scena richiesta.
	var state := scene.get_state()
	for index in state.get_node_property_count(0):
		if state.get_node_property_name(0, index) == property_name:
			return state.get_node_property_value(0, index)
	push_error("Proprietà %s assente in %s" % [property_name, scene_path])
	return null
