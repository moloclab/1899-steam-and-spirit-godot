extends Resource
class_name ActionRow
## Una riga della matrice: tutte le azioni partono nello stesso avanzamento.
## Il motore attende insieme tutte le colonne bloccanti prima di proseguire automaticamente.
const Step = preload("res://scripts/actions/action_step.gd")
@export var actions: Array[Step] = []

## Costruisce una riga da script senza modificare risorse condivise.
static func of(steps: Array[Step]) -> ActionRow:
	var row := ActionRow.new()
	row.actions.assign(steps)
	return row
