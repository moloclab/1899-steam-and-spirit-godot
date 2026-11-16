extends RefCounted
## Esecutore deterministico: un solo passo attivo, aggiornato dal coordinatore e sospendibile col menu.
## Non conserva nodi o coroutines dopo annullamento, caricamento o nuova partita.
signal line_requested(text_key: String, speaker: String)
signal state_changed
signal waiting_changed(waiting: bool)
signal finished(cancelled: bool)
const Step = preload("res://scripts/actions/action_step.gd")
const State = preload("res://scripts/game_state.gd")
const Rooms = preload("res://scripts/world/room_manager.gd")
var busy := false
var waiting_for_confirmation := false
var _steps: Array[Step] = []
var _index := 0
var _remaining := 0.0
var _active_actor: AnimatedSprite2D
var _state: State
var _rooms: Rooms

## Copia la lista, mantenendo immutabili le risorse condivise dagli oggetti della scena.
func start(steps: Array[Step], state: State, rooms: Rooms) -> void:
	cancel()
	_steps = steps.duplicate()
	_state = state
	_rooms = rooms
	_index = 0
	busy = true
	_next()

## Avanza i soli passi che richiedono tempo; le battute aspettano una conferma esplicita.
func tick(delta: float) -> void:
	if not busy or waiting_for_confirmation:
		return
	var step: Step = _steps[_index - 1]
	match step.kind:
		Step.Kind.WAIT:
			_remaining -= delta
			if _remaining <= 0:
				_next()
		Step.Kind.WALK:
			if not is_instance_valid(_active_actor):
				cancel()
			elif _active_actor.advance(delta):
				_active_actor.idle()
				_next()
		Step.Kind.ANIMATE:
			if not is_instance_valid(_active_actor):
				cancel()
			elif not _active_actor.is_playing():
				_next()

## Le conferme fuori da una battuta non saltano animazioni, attese o movimento.
func advance_dialogue() -> void:
	if busy and waiting_for_confirmation:
		waiting_for_confirmation = false
		waiting_changed.emit(false)
		_next()

## Cancella soltanto le azioni future: gli effetti già applicati appartengono allo stato corrente.
func cancel() -> void:
	if not busy:
		return
	if is_instance_valid(_active_actor) and _active_actor.has_method("stop_walking"):
		_active_actor.stop_walking()
	_finish(true)

## Esegue in ordine i passi immediati, fermandosi al primo che richiede tempo o conferma.
func _next() -> void:
	_active_actor = null
	while busy and _index < _steps.size():
		var step: Step = _steps[_index]
		_index += 1
		match step.kind:
			Step.Kind.SAY:
				line_requested.emit(step.text_key, step.speaker)
				if step.wait_for_completion:
					waiting_for_confirmation = true
					waiting_changed.emit(true)
					return
			Step.Kind.WAIT:
				_remaining = maxf(0, step.seconds)
				if _remaining > 0:
					return
			Step.Kind.WALK, Step.Kind.ANIMATE:
				_active_actor = _rooms.character(step.character_id)
				if _active_actor == null:
					push_error("Personaggio di sequenza mancante: " + step.character_id)
					cancel()
					return
				if step.kind == Step.Kind.WALK:
					# Le sequenze esprimono coordinate della stanza; l'attore può appartenere a un contenitore annidato.
					var room_x: float = _rooms.current_room.definition.clamp_x(step.target_x)
					var global_target: Vector2 = _rooms.current_room.to_global(Vector2(room_x, 0))
					_active_actor.target_x = _active_actor.get_parent().to_local(global_target).x
					return
				if not _active_actor.sprite_frames.has_animation(step.animation_name):
					push_error("Animazione mancante: " + step.animation_name)
					cancel()
					return
				# Un ciclo non può terminare da solo: va lanciato senza attenderne il completamento.
				if step.wait_for_completion and _active_actor.sprite_frames.get_animation_loop(step.animation_name):
					push_error("La sequenza non può attendere un'animazione ciclica.")
					cancel()
					return
				_active_actor.play(step.animation_name)
				if step.wait_for_completion:
					return
			Step.Kind.EFFECT:
				if not step.callback.is_valid():
					cancel()
					return
				var response: Variant = step.callback.call()
				state_changed.emit()
				if response is String and not response.is_empty():
					line_requested.emit(response, "common.speaker.churchill")
			Step.Kind.CHANGE_ROOM:
				if not _state.enter_room(step.destination_room, step.destination_entry):
					cancel()
					return
				state_changed.emit()
	if busy:
		_finish(false)

## Libera riferimenti e attese prima del segnale finale, così una nuova sequenza può partire subito.
func _finish(cancelled: bool) -> void:
	busy = false
	waiting_for_confirmation = false
	_active_actor = null
	_steps.clear()
	_state = null
	_rooms = null
	waiting_changed.emit(false)
	finished.emit(cancelled)
