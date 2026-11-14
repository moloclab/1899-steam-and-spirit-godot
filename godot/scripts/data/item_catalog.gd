extends RefCounted
## Indice delle scene: i dati sono definiti una sola volta, nella scena di ciascun oggetto.
const Definitions = preload("res://scripts/data/scene_definitions.gd")
const SCENES := {
	"bottle": "res://scenes/objects/ep01_cabin_bottle/bottle.tscn",
	"feather": "res://scenes/objects/ep01_cabin_feather/feather.tscn",
	"magnet": "res://scenes/objects/ep01_cabin_magnet/magnet.tscn",
	"magnetFeather": "res://scenes/objects/ep01_cabin_magnet_feather/magnet_feather.tscn",
	"key": "res://scenes/objects/ep01_cabin_key/key.tscn"
}
static var _items: Dictionary = {}
static var _recipes: Array = []
static var ITEMS: Dictionary:
	get:
		if _items.is_empty():
			for id in SCENES:
				_items[id] = Definitions.property(SCENES[id], "inventory_definition")
		return _items
static var RECIPES: Array:
	get:
		if _recipes.is_empty():
			_recipes.append(Definitions.property(SCENES.magnetFeather, "combination_definition"))
		return _recipes

## Anche la validazione dei salvataggi usa questo registro, evitando elenchi paralleli di ID.
static func has_item(item_id: String) -> bool:
	return SCENES.has(item_id)

## La coppia viene normalizzata: l'ordine di selezione non cambia la ricetta.
static func combination(first: String, second: String):
	var pair: Array[String] = [first, second]
	pair.sort()
	for recipe in RECIPES:
		var ingredients: Array[String] = recipe.ingredients.duplicate()
		ingredients.sort()
		if ingredients == pair:
			return recipe
	return null
