extends Resource
## Contenitore riutilizzabile di passi: le stanze possono condividere una sequenza senza copiarne i dati.
## Ogni passo indica soggetto e azione; il passaggio al successivo richiede un clic sinistro.
const Step = preload("res://scripts/actions/action_step.gd")
@export var steps: Array[Step] = []
