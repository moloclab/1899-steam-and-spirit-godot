extends RefCounted
## Legge inventario e ricette dalle stanze di origine senza istanziare i loro nodi.
const Definitions = preload("res://scripts/data/scene_definitions.gd")
const Rooms = preload("res://scripts/data/room_catalog.gd")
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
## Ricette raccolte da tutte le stanze registrate, indipendentemente da quella attiva.
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
		var recipes: Array = Definitions.property(scene_path, "combination_definitions")
		for item in items:
			# Una definizione duplicata è un errore di contenuto: non sovrascrive quella già registrata.
			if _items.has(item.item_id):
				push_error("ID inventario duplicato: " + item.item_id)
				continue
			_items[item.item_id] = item
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
