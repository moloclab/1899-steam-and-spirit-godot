extends Resource
## Contenitore riutilizzabile di passi: le stanze possono condividere una sequenza senza copiarne i dati.
const Step = preload("res://scripts/actions/action_step.gd")
@export var steps: Array[Step] = []
