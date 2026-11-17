extends Node
## Combinazioni di EP01, disponibili da qualsiasi stanza e modificabili nell'Inspector.
const CombinationDefinition = preload("res://scripts/data/combination_definition.gd")
## Le ricette sono incorporate nella scena e lette dal catalogo senza istanziare nodi.
@export var combination_definitions: Array[CombinationDefinition] = []
