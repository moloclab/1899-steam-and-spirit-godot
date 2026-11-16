extends SceneTree
## Catture col renderer reale: eseguire senza --headless per verificare layout, icone e ritaglio delle stanze.
const Main = preload("res://scenes/main.tscn")
var game: Control

## Avvia dopo l'inizializzazione del viewport alla risoluzione di riferimento.
func _initialize() -> void:
	root.size = Vector2i(1152, 720)
	_run.call_deferred()

## Attende il disegno effettivo prima di leggere la texture del viewport.
func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png("res://test-output/" + name + ".png")
	if error != OK:
		push_error("Cattura non riuscita: " + name)
		quit(1)

## Usa gli stessi componenti del gioco, senza modificare file di salvataggio del giocatore.
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
	var marker := FileAccess.open("res://test-output/.gdignore", FileAccess.WRITE)
	marker.close()
	game = Main.instantiate()
	root.add_child(game)
	game.set_process(false)
	await _capture("ep01_cabin")
	game.state.pick_up("ep01_cabin_bottle")
	game.state.pick_up("ep01_cabin_feather")
	game.state.pick_up("ep01_cabin_magnet")
	game._refresh()
	await _capture("inventory")
	# La stanza compone il dialogo; le catture mostrano il cambio speaker e la pausa della UI.
	game._start_actions(game.rooms.current_room.actions(game.state, "interphone"))
	game.sequences.advance_dialogue()
	await _capture("interphone")
	game.ui._toggle_help()
	await _capture("paused-conversation")
	game.ui._toggle_help()
	game.sequences.cancel()
	game.state.enter_room("ep01_corridor", "from_cabin")
	game._load_room()
	game._say(game._text("ep01.cabin.door.exit"))
	await _capture("ep01_corridor")
	game.queue_free()
	await process_frame
	print("Catture salvate in test-output/.")
	quit()
