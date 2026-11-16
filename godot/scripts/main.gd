extends Control
## Collega i componenti del gioco: input, selezione e ciclo di aggiornamento.
## Le regole degli enigmi restano negli hotspot; contenuti, movimento, UI e salvataggi sono indipendenti.
const State = preload("res://scripts/game_state.gd")
const UI = preload("res://scripts/game_ui.gd")
const Items = preload("res://scripts/data/item_catalog.gd")
const Texts = preload("res://scripts/data/dictionary_catalog.gd")
const Rooms = preload("res://scripts/world/room_manager.gd")
const Interactions = preload("res://scripts/actions/interaction_controller.gd")
const Sequences = preload("res://scripts/actions/sequence_runner.gd")
const Step = preload("res://scripts/actions/action_step.gd")
const Saves = preload("res://scripts/save_store.gd")
const Episodes = preload("res://scripts/data/episode_catalog.gd")
const CURSOR_NORMAL = preload("res://assets/graphics/ui/cursors/cursor_normal.png")
const CURSOR_MAGNIFIER = preload("res://assets/graphics/ui/cursors/cursor_magnifier.png")
var state: State
var texts: Texts
var rooms = Rooms.new()
var interactions = Interactions.new()
var sequences = Sequences.new()
var ui: UI
var music := AudioStreamPlayer.new()
@export var starting_episode := Episodes.DEFAULT_EPISODE
var _active_episode := ""
## Selezioni temporanee: non appartengono al salvataggio e vengono scartate al cambio partita.
var selected_item := ""
var menu_hotspot: Hotspot

## Prepara i componenti e collega le intenzioni della UI ai servizi del gioco.
func _ready() -> void:
	state = State.new(starting_episode)
	texts = Texts.new(starting_episode)
	Input.set_custom_mouse_cursor(CURSOR_NORMAL, Input.CURSOR_ARROW, Vector2(1, 1))
	Input.set_custom_mouse_cursor(CURSOR_NORMAL, Input.CURSOR_POINTING_HAND, Vector2(1, 1))
	Input.set_custom_mouse_cursor(CURSOR_MAGNIFIER, Input.CURSOR_CROSS, Vector2(1, 1))
	ui = UI.new()
	ui.texts = texts
	add_child(ui)
	ui.save_requested.connect(_save)
	ui.load_requested.connect(_load)
	# Un solo player mantiene il brano tra stanze dello stesso episodio.
	add_child(music)
	# La pausa conserva la posizione del brano quando si riabilita la musica.
	ui.music_toggled.connect(func(enabled: bool): music.stream_paused = not enabled)
	ui.new_game_requested.connect(_new_game)
	ui.world_input.connect(_world_input)
	ui.action_chosen.connect(_choose_action)
	ui.inventory_pressed.connect(_inventory_click)
	ui.item_examined.connect(func(item: String): _say(_item_description(item)))
	ui.menu_toggled.connect(_menu_toggled)
	sequences.line_requested.connect(func(key: String, speaker: String): _say(_text(key), speaker))
	sequences.state_changed.connect(_after_effect)
	sequences.finished.connect(func(_cancelled: bool): ui.lock_interactions(false))
	_load_room()
	_show_intro()

## I cursori appartengono a Input: rilasciarli alla chiusura evita texture trattenute oltre il renderer.
func _exit_tree() -> void:
	# Rilascia il decoder del sottofondo prima della chiusura del server audio.
	music.stop()
	music.stream = null
	for cursor in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_CROSS]:
		Input.set_custom_mouse_cursor(null, cursor)

## Nuova partita e caricamento eliminano ogni richiesta legata ai nodi della stanza precedente.
func _new_game() -> void:
	sequences.cancel()
	state = State.new(starting_episode)
	selected_item = ""
	ui.help_panel.hide()
	_load_room()
	_show_intro()

## Introduzione e musica provengono dalla definizione dell'episodio corrente.
func _show_intro() -> void:
	var episode = Episodes.get_episode(state.episode_id)
	if episode == null:
		return
	var lines: Array[String] = []
	for key in episode.intro_keys:
		lines.append(_text(key))
	_say("  ".join(lines))

## I cambi stanza nello stesso episodio conservano posizione del brano e preferenza musicale.
func _sync_episode() -> void:
	if _active_episode == state.episode_id:
		return
	var episode = Episodes.get_episode(state.episode_id)
	if episode == null or not texts.load_episode(state.episode_id):
		return
	music.stop()
	# Il decoder usato dal player non modifica la risorsa condivisa della configurazione.
	music.stream = episode.music.duplicate() if episode.music != null else null
	if music.stream != null:
		music.play()
	music.stream_paused = not ui.music_button.button_pressed
	_active_episode = state.episode_id

## Il gestore delle stanze mantiene tutto il codice di creazione e posizionamento del personaggio.
func _load_room() -> void:
	ui.speech_label.hide()
	_close_action_menu()
	interactions.cancel(rooms)
	if not rooms.load_room(state, ui.world_panel):
		push_error("Impossibile caricare la stanza: " + state.room)
		return
	_sync_episode()
	_refresh()
	rooms.pause_animations(ui.help_panel.visible)

## Sincronizza anche gli oggetti nascosti, necessari quando si ripristina un salvataggio precedente.
func _refresh() -> void:
	for hotspot in _hotspots(false):
		hotspot.sync_from_state(state)
	if not state.has_item(selected_item):
		selected_item = ""
	ui.refresh_inventory(state.inventory, selected_item, texts)
	ui.lock_interactions(sequences.busy)

## Gli effetti possono chiedere una transizione modificando lo stato, senza conoscere il gestore scene.
func _after_effect() -> void:
	if rooms.current_room.definition.room_id != state.room:
		_load_room()
	else:
		_refresh()

## Ogni sequenza blocca la UI prima dell'avvio; il segnale finale la riabilita anche per azioni immediate.
func _start_actions(actions: Array[Step]) -> void:
	# La cancellazione può riabilitare la UI tramite finished: deve precedere il blocco della nuova sequenza.
	sequences.cancel()
	ui.lock_interactions(true)
	sequences.start(actions, state, rooms)

## Unica lista di hotspot della stanza corrente, con supporto per contenitori annidati.
func _hotspots(visible_only: bool = true) -> Array[Node2D]:
	return rooms.current_room.hotspots(visible_only)

## Separa la scelta di un'azione dal suo avvicinamento e dalla successiva esecuzione.
func _request(hotspot: Hotspot, examine: bool) -> void:
	if sequences.busy:
		return
	_close_action_menu()
	interactions.request(hotspot, selected_item, examine, rooms)

## I testi dell'inventario provengono dalla stessa definizione usata per nomi, icone e validazione.
func _item_description(item: String) -> String:
	return _text(Items.ITEMS[item].description_key)

## I componenti di gioco lavorano con chiavi, mentre il catalogo sceglie la traduzione corrente.
func _text(key: String) -> String:
	return texts.text(key)

## Ogni nuova battuta appare sopra chi parla e resta ferma fino alla prossima interazione.
func _say(value: String, speaker: String = "common.speaker.churchill") -> void:
	ui.say(value, speaker)
	# Una sequenza può emettere la battuta nello stesso frame dell'arrivo: aggiorna prima lo scorrimento.
	rooms.position_world(ui.world_panel.size.x)
	_position_speech()

## Personaggi e oggetti espongono un punto sopra la propria sagoma nelle coordinate locali.
func _position_speech() -> void:
	var target := rooms.speech_target(ui._speaker_key)
	var anchor := Vector2.ZERO
	if target is Hotspot:
		anchor.x = target.hit_size.x / 2.0
	elif is_instance_valid(target):
		anchor.x = target.half_width
	ui.position_speech(target, anchor)

## Le richieste di avvicinamento libere vengono annullate; le sequenze mantengono il proprio percorso.
func _menu_toggled(open: bool) -> void:
	_close_action_menu()
	if not sequences.busy:
		interactions.cancel(rooms)
	rooms.pause_animations(open)

## Nasconde il pannello e rimuove i riferimenti al suo bersaglio.
## Il controllo di validità consente di chiamarla anche prima che il pannello sia stato costruito.
func _close_action_menu() -> void:
	if is_instance_valid(ui.action_menu):
		ui.action_menu.hide()
	menu_hotspot = null

## Apre le due scelte su un oggetto della stanza, senza ancora eseguire alcuna azione.
## Il tipo esportato dell'hotspot sceglie la grafica mano, bocca oppure uscita.
func _open_hotspot_menu(hotspot: Node2D) -> void:
	_close_action_menu()
	interactions.cancel(rooms)

	menu_hotspot = hotspot
	var kind: String = hotspot.interaction_kind
	var center: Vector2 = hotspot.to_global(hotspot.hit_size / 2)
	# Stanza ingrandita e corridoio scorrevole usano trasformazioni diverse dalla UI:
	# passiamo prima al canvas globale, poi alle coordinate locali del genitore del pannello.
	ui.action_menu.open(get_global_transform().affine_inverse() * center, kind)

## Gestisce il clic sinistro su un oggetto posseduto.
## Esamina e seleziona subito, oppure combina con l'oggetto già selezionato.
func _inventory_click(item: String, _button: Button) -> void:
	_select_item(item)

## Riceve la scelta dal pannello: true indica la lente, false l'interazione.
## Gli oggetti della stanza richiedono avvicinamento.
func _choose_action(examine: bool) -> void:
	ui.speech_label.hide()
	# Copia il bersaglio prima di chiudere il menu; il clic sulla scelta non passa alla stanza.
	var hotspot := menu_hotspot
	_close_action_menu()
	if is_instance_valid(hotspot) and hotspot.visible:
		_request(hotspot, examine)

## Gestisce solo i clic ricevuti dall'area della stanza.
## Il sinistro apre le scelte o usa un oggetto selezionato; il destro resta una scorciatoia facoltativa.
func _world_input(event: InputEvent) -> void:
	if ui.help_panel.visible or sequences.busy:
		return
	if event is InputEventMouseButton and event.pressed:
		ui.speech_label.hide()
		if event.button_index not in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			return
		# gui_input fornisce una posizione locale al contenitore, mentre gli hotspot ricevono punti globali.
		var point: Vector2 = ui.world_panel.get_global_transform() * event.position
		var hotspot := _at_point(point)
		if hotspot != null:
			if event.button_index == MOUSE_BUTTON_RIGHT or not selected_item.is_empty():
				# Come in EP01, un oggetto già selezionato si usa direttamente sul bersaglio.
				_close_action_menu()
				_request(hotspot, event.button_index == MOUSE_BUTTON_RIGHT)
			else:
				_open_hotspot_menu(hotspot)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel()
		else:
			# Sul pavimento si abbandona l'azione precedente e si sceglie una nuova destinazione.
			_close_action_menu()
			selected_item = ""
			interactions.cancel(rooms)
			rooms.actor.target_x = rooms.current_room.definition.clamp_x(rooms.current_room.to_local(point).x)

## Trova l'hotspot sotto il puntatore attuale, usato per l'evidenziazione durante il movimento del mouse.
func _at_mouse() -> Node2D:
	return _at_point(get_global_mouse_position())

## Cerca un oggetto cliccabile a partire da un punto in coordinate globali del canvas.
## In caso di sovrapposizione viene provato prima l'ultimo hotspot nell'ordine dei figli.
func _at_point(point: Vector2) -> Node2D:
	return _find_at_point(point, _hotspots())

## Riusa la lista del frame anche per individuare il bersaglio del mouse.
func _find_at_point(point: Vector2, hotspots: Array[Node2D]) -> Node2D:
	# Visita a ritroso senza invertire o copiare la lista condivisa dal chiamante.
	for index in range(hotspots.size() - 1, -1, -1):
		var hotspot := hotspots[index]
		if hotspot.contains(point):
			return hotspot
	return null

## Seleziona un oggetto, lo deseleziona al secondo clic oppure combina due oggetti diversi.
## La combinazione è delegata a GameState; qui si aggiornano soltanto selezione e interfaccia.
func _select_item(item: String) -> void:
	ui.speech_label.hide()
	_close_action_menu()
	interactions.cancel(rooms)

	if selected_item == item:
		selected_item = ""
	elif selected_item.is_empty():
		selected_item = item
		_say(_item_description(item))
	else:
		_say(_text(state.combine(selected_item, item)))
		selected_item = ""
	_refresh()

## Annulla pannello, oggetto selezionato e azione in attesa, fermando il personaggio sul posto.
func _cancel() -> void:
	_close_action_menu()
	selected_item = ""
	interactions.cancel(rooms)

	_refresh()

## Gestisce i clic durante i dialoghi e ignora tastiera e controller.
func _input(event: InputEvent) -> void:
	# Impedisce anche ai controlli UI di reagire a Invio, Spazio, Tab e frecce.
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()
		return
	# Il movimento del puntatore non cancella le battute; un clic nell'ambiente o nell'inventario le chiude.
	if not ui.help_panel.visible and event is InputEventMouseButton and event.pressed:
		if ui.world_panel.get_global_rect().has_point(event.position) or ui.inventory_scroll.get_global_rect().has_point(event.position) or (ui.action_menu.visible and ui.action_menu.get_global_rect().has_point(event.position)):
			ui.speech_label.hide()
	# Musica e aiuti restano utilizzabili anche durante le battute e le sequenze.
	if sequences.busy and not ui.help_panel.visible and event is InputEventMouseButton and event.pressed and not ui.music_button.get_global_rect().has_point(event.position) and not ui.help_button.get_global_rect().has_point(event.position):
		# Nasconde la battuta precedente prima di avanzare: la nuova resta visibile.
		ui.speech_label.hide()
		if event.button_index == MOUSE_BUTTON_LEFT:
			sequences.advance_dialogue()
		get_viewport().set_input_as_handled()
		return

## Il cursore mostra la lente sugli oggetti; la selezione resta visibile nell'inventario.
func _update_highlight() -> void:
	var hotspots := _hotspots()
	var mouse_target: Node2D = null
	if not ui.help_panel.visible and ui.world_panel.get_global_rect().has_point(get_global_mouse_position()):
		mouse_target = _find_at_point(get_global_mouse_position(), hotspots)
	ui.world_panel.mouse_default_cursor_shape = Control.CURSOR_CROSS if mouse_target != null else Control.CURSOR_ARROW
	ui.highlight_inventory(selected_item, -1, false)

## Aggiorna il movimento libero oppure il passo attivo della sequenza, mai entrambi nello stesso frame.
func _process(delta: float) -> void:
	if rooms.current_room == null:
		return
	if not ui.help_panel.visible:
		if sequences.busy:
			sequences.tick(delta)
		else:
			rooms.actor.advance(delta)
			state.player_x = rooms.actor.current_x
			var actions: Array[Step] = interactions.take_ready_actions(state, rooms)
			if not actions.is_empty():
				selected_item = ""
				_start_actions(actions)
	state.player_x = rooms.actor.current_x
	rooms.position_world(ui.world_panel.size.x)
	_update_highlight()

## I salvataggi manuali sono disponibili ai confini delle sequenze, quando lo stato è stabile.
func _save() -> void:
	if sequences.busy:
		return
	_close_action_menu()
	var error: Error = Saves.save_game(state)
	_say(_text("common.game_saved") if error == OK else _text("common.save_failed") % error_string(error))

## Il servizio valida e migra i dati prima di sostituire la partita corrente.
func _load() -> void:
	if sequences.busy:
		return
	_close_action_menu()
	var error: Error = Saves.load_game(state)
	if error == OK:
		selected_item = ""
		_load_room()
		_say(_text("common.game_loaded"))
	elif error == ERR_FILE_NOT_FOUND:
		_say(_text("common.save_not_found"))
	else:
		_say(_text("common.save_unreadable"))
