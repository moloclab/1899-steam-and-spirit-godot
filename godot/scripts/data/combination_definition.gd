extends Resource
## Ricetta comune per combinazioni simmetriche, modificabile nell'Inspector.
## Per regole narrative particolari si può specializzare apply(), senza cambiare GameState.
@export var ingredients: Array[String] = []
@export var consumed: Array[String] = []
@export var results: Array[String] = []
@export var response_key := "common.cannot_combine"

## Verifica entrambi gli ingredienti prima di consumare o aggiungere oggetti.
func apply(state) -> String:
	for item in ingredients:
		if not state.has_item(item):
			return "common.cannot_use"
	for item in consumed:
		state.remove_item(item)
	for item in results:
		state.add_item(item)
	return response_key
