extends SceneTree
## Verifica la prova statica senza modificare lo stato del gioco.
func _initialize() -> void:
	var room = load("res://scenes/rooms/ep01_cabin.tscn").instantiate()
	for id in ["oblo1", "oblo2"]:
		var visual = room.get_node(id + "/Visual") as AnimatedSprite2D
		assert(visual.sprite_frames.get_frame_count("default") == 1)
		assert(visual.autoplay.is_empty() and not visual.is_playing())
		assert(not visual.sprite_frames.get_animation_loop("default"))
		assert(visual.sprite_frames.get_frame_texture("default", 0).get_size() == Vector2(43, 43))
		assert(visual.position == Vector2(2.5, 2.5))
	room.free()
	print("OK: entrambi gli oblo statici, 43x43, senza autoplay e centrati.")
	quit()
