extends Resource
class_name ActionRow
## Una riga della matrice: tutte le azioni partono nello stesso avanzamento.
## Il motore attende insieme tutte le colonne bloccanti prima di proseguire automaticamente.
const Step = preload("res://scripts/actions/action_step.gd")
@export var actions: Array[Step] = []
## False per risposte immediate: la battuta resta visibile senza richiedere un clic di chiusura.
@export var wait_for_confirmation := true
## Requisito runtime, senza effetti: se fallisce il motore conclude la sequenza.
var condition: Callable

## Costruisce una riga da script senza modificare risorse condivise.
static func of(steps: Array[Step], requirement: Callable = Callable(), confirm: bool = true) -> ActionRow:
	var row := ActionRow.new()
	row.actions.assign(steps)
	row.condition = requirement
	row.wait_for_confirmation = confirm
	return row
