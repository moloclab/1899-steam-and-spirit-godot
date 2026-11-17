extends Resource
## Matrice riutilizzabile: righe successive, ciascuna con una o più azioni contemporanee.
const Row = preload("res://scripts/actions/action_row.gd")
@export var rows: Array[Row] = []
