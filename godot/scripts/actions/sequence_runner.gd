extends RefCounted
## Esegue un solo passo per clic; il comando iniziale avvia il primo passo.
## I clic durante movimento, attesa o animazione non vengono accodati.
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

## Copia la lista senza modificare le risorse condivise dagli oggetti della scena.
func start(steps: Array[Step], state: State, rooms: Rooms) -> void:
	cancel()
	_steps = steps.duplicate()
	_state = state
	_rooms = rooms
	_index = 0
	busy = true
	_next()

## La fine di un passo temporizzato abilita il clic senza avviare l'azione successiva.
func tick(delta: float) -> void:
	if not busy or waiting_for_confirmation:
		return
	var step: Step = _steps[_index - 1]
	match step.kind:
		Step.Kind.WAIT:
			_remaining -= delta
			if _remaining <= 0:
				_complete_step()
		Step.Kind.WALK:
			if not is_instance_valid(_active_actor):
				cancel()
			elif _active_actor.advance(delta):
				_active_actor.idle()
				_complete_step()
		Step.Kind.ANIMATE:
			if not is_instance_valid(_active_actor):
				cancel()
			elif not _active_actor.is_playing():
				_complete_step()

## Avvia il prossimo punto solo se quello corrente ha terminato la propria esecuzione.
func advance_dialogue() -> void:
	if busy and waiting_for_confirmation:
		waiting_for_confirmation = false
		waiting_changed.emit(false)
		_next()

## Annulla le azioni future senza ripristinare gli effetti già eseguiti.
func cancel() -> void:
	if not busy:
		return
	if is_instance_valid(_active_actor) and _active_actor.has_method("stop_walking"):
		_active_actor.stop_walking()
	_finish(true)

## L'ultima battuta resta fino al clic di chiusura; gli altri passi finali terminano subito.
func _complete_step() -> void:
	_active_actor = null
	if _index < _steps.size() or _steps[_index - 1].kind == Step.Kind.SAY:
		waiting_for_confirmation = true
		waiting_changed.emit(true)
	else:
		_finish(false)

## Esegue esattamente un'azione, anche quando il suo effetto è immediato.
func _next() -> void:
	if _index >= _steps.size():
		_finish(false)
		return
	var step: Step = _steps[_index]
	_index += 1
	# Una posa accompagnata da testo o effetto appartiene allo stesso passo dell'originale.
	if step.kind in [Step.Kind.SAY, Step.Kind.EFFECT] and not step.animation_name.is_empty():
		var actor := _rooms.character(step.subject_id)
		if actor == null or not actor.sprite_frames.has_animation(step.animation_name):
			push_error("Posa di sequenza mancante: " + step.animation_name)
			cancel()
			return
		actor.play(step.animation_name)
	match step.kind:
		Step.Kind.SAY:
			var subject := _rooms.subject(step.subject_id)
			if subject == null or subject.speaker_key.is_empty():
				push_error("Soggetto parlante di sequenza mancante: " + step.subject_id)
				cancel()
				return
			line_requested.emit(step.text_key, subject.speaker_key)
		Step.Kind.WAIT:
			_remaining = maxf(0, step.seconds)
			if _remaining > 0:
				return
		Step.Kind.WALK, Step.Kind.ANIMATE:
			_active_actor = _rooms.character(step.subject_id)
			if _active_actor == null:
				push_error("Personaggio di sequenza mancante: " + step.subject_id)
				cancel()
				return
			if step.kind == Step.Kind.WALK:
				# Coordinate stanza anche per soggetti e destinazioni in contenitori annidati.
				var target_x := step.target_x
				if not step.target_hotspot_id.is_empty():
					var target := _rooms.find_hotspot(step.target_hotspot_id)
					if target == null:
						push_error("Destinazione di sequenza mancante: " + step.target_hotspot_id)
						cancel()
						return
					var room_position := _rooms.current_room.to_local(_active_actor.to_global(Vector2(_active_actor.half_width, 0)))
					target_x = target.approach_position(room_position.x, _active_actor.half_width)
				var room_x: float = _rooms.current_room.definition.clamp_x(target_x)
				var global_target: Vector2 = _rooms.current_room.to_global(Vector2(room_x, 0))
				_active_actor.target_x = _active_actor.get_parent().to_local(global_target).x
				return
			if not _active_actor.sprite_frames.has_animation(step.animation_name):
				push_error("Animazione mancante: " + step.animation_name)
				cancel()
				return
			# Un'animazione ciclica può essere avviata solo senza attenderne la fine.
			if step.wait_for_completion and _active_actor.sprite_frames.get_animation_loop(step.animation_name):
				push_error("La sequenza non può attendere un'animazione ciclica.")
				cancel()
				return
			_active_actor.play(step.animation_name)
			if step.wait_for_completion:
				return
		Step.Kind.HIDE:
			var subject := _rooms.subject(step.subject_id)
			if subject == null:
				push_error("Soggetto di sequenza mancante: " + step.subject_id)
				cancel()
				return
			subject.hide()
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
	_complete_step()

## Libera riferimenti e attese prima di notificare la fine alla UI.
func _finish(cancelled: bool) -> void:
	busy = false
	waiting_for_confirmation = false
	_active_actor = null
	_steps.clear()
	_state = null
	_rooms = null
	waiting_changed.emit(false)
	finished.emit(cancelled)
