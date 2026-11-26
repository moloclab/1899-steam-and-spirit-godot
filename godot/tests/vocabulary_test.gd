extends SceneTree
## Verifica il vocabolario sulla scena reale senza leggere o scrivere salvataggi del giocatore.
const Main = preload("res://scenes/main.tscn")
var checks := 0
var failures := 0

## La UI richiede il viewport pronto prima della costruzione dei controlli.
func _initialize() -> void:
	root.size = root.content_scale_size
	_run.call_deferred()

## Ogni errore rende il processo utilizzabile anche come controllo automatico.
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

## Cerca il testo effettivamente visualizzato, includendo le etichette del pannello aiuti.
func has_label(node: Node, value: String) -> bool:
	if node is Label and node.text == value:
		return true
	for child in node.get_children():
		if has_label(child, value):
			return true
	return false

## Cambia lingua con menu aperti e musica spenta, poi controlla le battute della sequenza reale.
func _run() -> void:
	var game = Main.instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	check(not DirAccess.dir_exists_absolute("res://assets/dialogue"), "Cartella originale rinominata")
	check(game.ui.save_buttons[0].text == "Save", "UI iniziale inglese")
	check(game.texts.language == "en" and game.ui.language_button.text == "Language: English", "Lingua predefinita inglese")
	check(has_label(game.ui.help_panel, "CONTROLS"), "Titolo aiuti inglese")
	for key in game.texts.entries:
		var entry: Dictionary = game.texts.entries[key]
		check(not str(entry.get("it", "")).is_empty() and not str(entry.get("en", "")).is_empty(), "Voce IT/EN completa: " + key)
	game.ui._toggle_help()
	game.ui.music_button.button_pressed = false
	game.ui._toggle_music()
	# Il pulsante alterna entrambe le lingue senza cambiare pausa e stato musicale.
	game.ui.language_button.pressed.emit()
	check(game.texts.language == "it" and game.ui.language_button.text == "Lingua: Italiano", "Pulsante lingua italiana")
	game.ui.language_button.pressed.emit()
	check(game.texts.language == "en" and game.ui.language_button.text == "Language: English", "Pulsante ritorna all'inglese")
	check(game.ui.help_panel.visible, "Cambio lingua conserva il pannello aperto")
	check(game.ui.save_buttons[0].text == "Save" and game.ui.save_buttons[1].text == "Load", "Pulsanti aiuti inglesi")
	check(game.ui.help_button.text.is_empty() and game.ui.help_button.tooltip_text.is_empty() and game.ui.help_close.text == "Back to game", "Bussola senza etichetta e tooltip, chiusura aiuti inglese")
	check(game.ui.reset_button.text == "Restart" and game.ui.reset_button.tooltip_text.is_empty(), "Reset inglese senza tooltip")
	check(has_label(game.ui.help_panel, "CONTROLS"), "Titolo aiuti inglese")
	check(has_label(game.ui.help_panel, game.texts.entries["common.ui.help_commands"].en), "Istruzioni complete inglesi")
	check(game.ui.music_button.text == "Music: OFF" and game.music.stream_paused, "Cambio lingua conserva musica spenta")
	game.ui._toggle_help()
	for hotspot_id in ["sink", "interphone", "door"]:
		game._open_hotspot_menu(game.rooms.find_hotspot(hotspot_id))
		check(game.ui.action_menu.interact_button.tooltip_text.is_empty(), "Azione senza tooltip: " + hotspot_id)
	check(game.ui.action_menu.examine_button.tooltip_text.is_empty(), "Esame senza tooltip")
	game.texts.language = "it"
	check(game.ui.action_menu.visible and game.ui.action_menu.interact_button.tooltip_text.is_empty(), "Menu aperto senza tooltip dopo il cambio lingua")
	check(game.ui.music_button.text == "Musica: OFF", "Stato musicale ritradotto")
	game.texts.language = "en"
	# I passi prodotti dalla stanza mantengono le chiavi traducibili e i soggetti delle battute.
	game._start_actions(game.rooms.current_room.interact(game.state, "interphone"))
	check(game.ui.speaker_label.text == "WINSTON CHURCHILL", "Nome Churchill dal vocabolario")
	game.sequences.advance_dialogue()
	check(game.ui.speaker_label.text == "INTERPHONE", "Nome interfono dal vocabolario")
	check(game.ui.speech_label.text == game.texts.text("ep01.cabin.interphone.summons"), "Battuta inglese della sequenza")
	game.texts.language = "it"
	check(game.ui.speaker_label.text == "INTERFONO", "Cambio lingua conserva l'interlocutore")
	game.sequences.cancel()
	game._say(game.texts.text("common.save_failed") % "test")
	check(game.ui.speech_label.text == "Non riesco a salvare la partita: test", "Messaggio di errore con parametro")
	game.queue_free()
	await process_frame
	# Attende che il mixer audio rilasci i decoder dopo la rimozione del player.
	await create_timer(0.15).timeout
	print("Vocabolario: %d verifiche, %d errori" % [checks, failures])
	quit(0 if failures == 0 else 1)
