extends SceneTree
## Controlla il foglio importato e l'avanzamento reale, senza avviare una partita.
func _initialize() -> void:
	_run.call_deferred()

## Ogni differenza deve restare nell'acqua e non cambiare sagoma, ottone o riflesso superiore.
func _run() -> void:
	var room = load("res://scenes/rooms/ep01_cabin.tscn").instantiate()
	var first = room.get_node("oblo1/Visual") as AnimatedSprite2D
	var second = room.get_node("oblo2/Visual") as AnimatedSprite2D
	assert(first.sprite_frames == second.sprite_frames)
	var frames = first.sprite_frames
	assert(frames.get_frame_count("default") == 12)
	assert(frames.get_animation_loop("default"))
	assert(frames.get_animation_speed("default") == 5.0)
	var source = load("res://assets/graphics/ep01_cabin/oblo-original-redesign-2.png").get_image().get_region(Rect2i(2, 2, 43, 43))
	var sheet = load("res://assets/graphics/ep01_cabin/oblo.png").get_image()
	assert(sheet.get_size() == Vector2i(516, 43))
	var total_changes := 0
	for frame in range(12):
		assert(frames.get_frame_texture("default", frame).get_size() == Vector2(43, 43))
		for y in range(43):
			for x in range(43):
				var original: Color = source.get_pixel(x, y)
				var current: Color = sheet.get_pixel(frame * 43 + x, y)
				assert(original.a == current.a)
				if original != current:
					assert(frame != 0)
					assert(x >= 9 and x <= 33 and y >= 18 and y <= 26)
					assert(original.g > original.r + 12.0 / 255.0 and original.b > original.r + 12.0 / 255.0)
					total_changes += 1
	assert(total_changes > 0)
	# Prova l'autoplay di entrambi i nodi con il clock del motore e poi il ritorno al primo frame.
	for visual in [first, second]:
		assert(visual.autoplay == "default")
		assert(visual.position == Vector2(2.5, 2.5))
		visual.owner = null
		visual.get_parent().remove_child(visual)
		root.add_child(visual)
	await create_timer(0.3).timeout
	assert(first.is_playing() and second.is_playing())
	assert(first.frame > 0 and first.frame == second.frame)
	first.frame = 11
	first.frame_progress = 0.0
	await create_timer(0.25).timeout
	assert(first.frame == 0)
	first.queue_free()
	second.queue_free()
	room.free()
	print("OK: acqua animata, 12 frame a 5 fps, ciclo e autoplay verificati; cornice, riflesso alto e alpha invariati.")
	quit()
