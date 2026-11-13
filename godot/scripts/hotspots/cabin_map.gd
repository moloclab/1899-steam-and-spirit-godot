extends "res://scripts/hotspot.gd"
## La calamita si raccoglie dalla mappa, ma la mappa rimane sempre esaminabile.
@export var complete_texture: Texture2D = preload("res://assets/graphics/original/mapMagnet.png")
@export var collected_texture: Texture2D = preload("res://assets/graphics/original/map.png")

## Dopo la raccolta la descrizione non menziona più la calamita rossa.
func examine(state: State) -> String:
	return "cabin.map.examine_without_magnet" if "magnet" in state.collected else "cabin.map.examine"

## Questa raccolta differisce da quella di un oggetto che scompare: al secondo clic si descrive la mappa.
func interact(state: State) -> String:
	return "cabin.magnet.pickup" if state.pick_up("magnet") else "cabin.map.examine_without_magnet"

## La texture viene derivata ogni volta dallo stato persistente, anche al rientro nella cabina.
func sync_from_state(state: State) -> void:
	$Visual.texture = collected_texture if "magnet" in state.collected else complete_texture
