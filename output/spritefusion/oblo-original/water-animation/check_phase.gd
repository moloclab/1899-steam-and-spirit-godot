extends SceneTree
## Verifica lo sfasamento reale dopo autoplay e il ripristino dei ritmi dopo la pausa.
func _initialize() -> void:
	_run.call_deferred()

## Usa la scena effettiva per controllare i valori dopo l'ingresso nell'albero.
func _run() -> void:
	var room = load("res://scenes/rooms/ep01_cabin.tscn").instantiate()
	root.add_child(room)
	var first = room.get_node("oblo1/Visual")
	var second = room.get_node("oblo2/Visual")
	print("Dopo autoplay: ", first.frame, " / ", second.frame)
	assert(first.frame == 0 and second.frame == 4)
	assert(is_equal_approx(second.speed_scale, 0.93))
	await create_timer(0.5).timeout
	assert(first.is_playing() and second.is_playing())
	assert(first.frame != second.frame)
	var manager = load("res://scripts/world/room_manager.gd").new()
	manager.current_room = room
	manager.pause_animations(true)
	var paused_first = first.frame
	var paused_second = second.frame
	await create_timer(0.3).timeout
	assert(first.frame == paused_first and second.frame == paused_second)
	manager.pause_animations(false)
	assert(is_equal_approx(first.speed_scale, 1.0))
	assert(is_equal_approx(second.speed_scale, 0.93))
	room.queue_free()
	print("OK: acqua sfasata, ritmi distinti e pausa/ripresa corretti.")
	quit()
