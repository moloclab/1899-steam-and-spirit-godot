extends "res://scripts/hotspot.gd"
## Passaggio senza enigma: stanza e ingresso nominato si impostano nell'Inspector.
## Le coordinate appartengono alla definizione della destinazione e possono cambiare senza aggiornare le uscite.
@export var destination_room := ""
@export var destination_entry := "default"

## Accoda il passaggio; esame, usi e conversazioni seguono le regole comuni.
func actions(state: State, item_id: String = "", examining: bool = false) -> Array[Row]:
	if examining or not item_id.is_empty() or (conversation != null and not conversation.rows.is_empty()):
		return super.actions(state, item_id, examining)
	# La transizione occupa una riga propria; la risposta viene mostrata nella destinazione.
	var rows: Array[Row] = [Row.of([Step.changeRoom(destination_room, destination_entry)], Callable(), false)]
	if not interaction_response.is_empty():
		rows.append(Row.of([Step.say("player", interaction_response)], Callable(), false))
	return rows
