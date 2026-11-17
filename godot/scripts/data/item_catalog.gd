extends RefCounted
## Legge l'inventario dalle stanze e le ricette dagli episodi senza istanziare nodi.
const Definitions = preload("res://scripts/data/scene_definitions.gd")
const Rooms = preload("res://scripts/data/room_catalog.gd")
const Episodes = preload("res://scripts/data/episode_catalog.gd")
## Cache condivisa fra UI, stato e validazione dei salvataggi; conserva le risorse delle scene.
static var _items: Dictionary = {}
static var _recipes: Array = []
## Distingue un catalogo già letto ma vuoto da un catalogo ancora da caricare.
static var _loaded := false
## Accesso pubblico alle definizioni per ID; la prima lettura popola entrambe le cache.
static var ITEMS: Dictionary:
	get:
		_load_definitions()
		return _items
## Ricette raccolte dalle scene combo degli episodi, indipendentemente dalla stanza attiva.
static var RECIPES: Array:
	get:
		_load_definitions()
		return _recipes

## Le risorse sono lette solo dopo la compilazione degli script, evitando cicli di preload.
static func _load_definitions() -> void:
	if _loaded:
		return
	# Si leggono le proprietà serializzate della radice, senza creare nodi o eseguire _ready.
	for scene_path in Rooms.SCENES.values():
		var items: Array = Definitions.property(scene_path, "inventory_definitions")
		for item in items:
			# Una definizione duplicata è un errore di contenuto: non sovrascrive quella già registrata.
			if _items.has(item.item_id):
				push_error("ID inventario duplicato: " + item.item_id)
				continue
			_items[item.item_id] = item
	# Ogni episodio indica la propria scena combo; anche qui si leggono soltanto risorse.
	for episode_id in Episodes.EPISODES:
		var episode = Episodes.get_episode(episode_id)
		if episode == null or episode.combo_scene_path.is_empty():
			continue
		var recipes: Array = Definitions.property(episode.combo_scene_path, "combination_definitions")
		_recipes.append_array(recipes)
	_loaded = true

## Anche la validazione dei salvataggi usa le stesse definizioni delle stanze.
static func has_item(item_id: String) -> bool:
	return ITEMS.has(item_id)

## La coppia viene normalizzata: l'ordine di selezione non cambia la ricetta.
static func combination(first: String, second: String):
	var pair: Array[String] = [first, second]
	pair.sort()
	for recipe in RECIPES:
		# Ordina una copia per non modificare la risorsa ricetta condivisa con l’Inspector.
		var ingredients: Array[String] = recipe.ingredients.duplicate()
		ingredients.sort()
		if ingredients == pair:
			return recipe
	return null
