extends RefCounted
## Registro unico degli oggetti e delle ricette. Le risorse non contengono dati della partita.
const ITEMS := {
	"bottle": preload("res://assets/data/items/bottle.tres"),
	"feather": preload("res://assets/data/items/feather.tres"),
	"magnet": preload("res://assets/data/items/magnet.tres"),
	"magnetFeather": preload("res://assets/data/items/magnet_feather.tres"),
	"key": preload("res://assets/data/items/key.tres")
}
const RECIPES := [preload("res://assets/data/combinations/magnet_feather.tres")]

## Anche la validazione dei salvataggi usa questo registro, evitando elenchi paralleli di ID.
static func has_item(item_id: String) -> bool:
	return ITEMS.has(item_id)

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
