extends RefCounted
## Ogni clic avvia una riga della matrice, con tutte le sue azioni nello stesso frame.
## Come in EP01, la conclusione di una riga bloccante avvia automaticamente la successiva.
signal row_started
signal line_requested(text_key: String, speaker: String)
signal state_changed
signal waiting_changed(waiting: bool)
signal finished(cancelled: bool)
const Step = preload("res://scripts/actions/action_step.gd")
const Row = preload("res://scripts/actions/action_row.gd")
const State = preload("res://scripts/game_state.gd")
const Rooms = preload("res://scripts/world/room_manager.gd")
var busy := false
var waiting_for_confirmation := false
var _rows: Array[Row] = []
var _index := 0
## Ogni azione bloccante ha il proprio attore o timer, separato dalle risorse di configurazione.
var _pending: Array[Dictionary] = []
var _state: State
var _rooms: Rooms

## Copia righe e colonne senza modificare le risorse condivise dalle stanze.
func start(rows: Array[Row], state: State, rooms: Rooms) -> void:
	cancel()
	_rows.clear()
	for row in rows:
		_rows.append(Row.of(row.actions, row.condition, row.wait_for_confirmation) if row != null else null)
	_state = state
	_rooms = rooms
	_index = 0
	busy = true
	_next()

## Aggiorna tutte le colonne attive e avanza solo quando sono terminate tutte.
func tick(delta: float) -> void:
	if not busy or waiting_for_confirmation:
		return
	for task in _pending.duplicate():
		var complete := false
		match task.kind:
			Step.Kind.WAIT:
				task.remaining -= delta
				complete = task.remaining <= 0
			Step.Kind.WALK, Step.Kind.ANIMATE:
				if not is_instance_valid(task.actor) or task.actor.is_queued_for_deletion():
					cancel()
					return
				if task.kind == Step.Kind.WALK:
					complete = task.actor.advance(delta)
				else:
					complete = not task.actor.is_playing()
		if complete:
			_pending.erase(task)
	if _pending.is_empty():
		_next()

## I clic durante cammini o attese vengono ignorati e non sono accodati.
func advance_dialogue() -> void:
	if busy and waiting_for_confirmation:
		waiting_for_confirmation = false
		waiting_changed.emit(false)
		_next()

## Ferma tutti i personaggi bloccanti, preservando gli effetti già applicati.
func cancel() -> void:
	if not busy:
		return
	for task in _pending:
		if task.has("actor") and is_instance_valid(task.actor):
			task.actor.stop_walking()
	_finish(true)

## Valida tutta la riga prima degli effetti; uno stesso attore non può camminare e animarsi due volte.
func _validate(row: Row) -> bool:
	if row == null:
		return false
	var animated_subjects := {}
	for step in row.actions:
		if step == null:
			return false
		match step.kind:
			Step.Kind.SAY:
				var subject := _rooms.subject(step.subject_id)
				if subject == null or subject.speaker_key.is_empty():
					return false
			Step.Kind.WALK, Step.Kind.ANIMATE:
				var actor := _rooms.character(step.subject_id)
				if actor == null or animated_subjects.has(actor):
					return false
				animated_subjects[actor] = true
				if step.kind == Step.Kind.WALK:
					if not step.target_hotspot_id.is_empty() and _rooms.find_hotspot(step.target_hotspot_id) == null:
						return false
				elif not actor.sprite_frames.has_animation(step.animation_name) or (step.wait_for_completion and actor.sprite_frames.get_animation_loop(step.animation_name)):
					return false
			Step.Kind.WAIT:
				if not is_finite(step.seconds) or step.seconds < 0:
					return false
			Step.Kind.HIDE:
				if _rooms.subject(step.subject_id) == null:
					return false
			Step.Kind.CHANGE_ROOM:
				# Una transizione sostituisce i nodi: deve occupare una riga propria.
				if row.actions.size() != 1:
					return false
	return true

## Avvia tutte le colonne prima di notificare UI e scena; le righe bloccanti finite avanzano da sole.
func _next() -> void:
	while busy:
		if _index >= _rows.size():
			_finish(false)
			return
		var row := _rows[_index]
		_index += 1
		if not _validate(row):
			cancel()
			return
		row_started.emit()
		# Una condizione scaduta esclude tutta la riga, comprese posa e battuta di successo.
		if not row.condition.is_null():
			if not row.condition.is_valid():
				cancel()
				return
			if not row.condition.call():
				line_requested.emit("common.cannot_use", "common.speaker.churchill")
				_finish(false)
				return
		var blocking := false
		var has_speech := false
		var changed := false
		var lines: Array[Dictionary] = []
		var previous_room := _state.room
		for step in row.actions:
			match step.kind:
				Step.Kind.SAY:
					lines.append({"key": step.text_key, "speaker": _rooms.subject(step.subject_id).speaker_key})
					has_speech = true
				Step.Kind.WAIT:
					blocking = true
					if step.seconds > 0:
						_pending.append({"kind": step.kind, "remaining": step.seconds})
				Step.Kind.WALK:
					var actor := _rooms.character(step.subject_id)
					var target_x := step.target_x
					if not step.target_hotspot_id.is_empty():
						var target := _rooms.find_hotspot(step.target_hotspot_id)
						var position_in_room := _rooms.current_room.to_local(actor.to_global(Vector2(actor.half_width, 0)))
						target_x = target.approach_position(position_in_room.x, actor.half_width, step.center_on_hotspot)
					var room_x: float = _rooms.current_room.definition.clamp_x(target_x)
					var global_target: Vector2 = _rooms.current_room.to_global(Vector2(room_x, 0))
					actor.target_x = actor.get_parent().to_local(global_target).x
					actor.advance(0)
					_pending.append({"kind": step.kind, "actor": actor})
					blocking = true
				Step.Kind.ANIMATE:
					var actor := _rooms.character(step.subject_id)
					actor.play(step.animation_name)
					if step.wait_for_completion:
						_pending.append({"kind": step.kind, "actor": actor})
						blocking = true
				Step.Kind.HIDE:
					_rooms.subject(step.subject_id).hide()
				Step.Kind.LEAVE:
					_state.remove_item(step.item_id)
					changed = true
				Step.Kind.ADD:
					_state.add_item(step.item_id)
					changed = true
				Step.Kind.CHANGE_STATUS:
					_state.set_progress(step.progress_scope, step.progress_key, step.progress_value)
					changed = true
				Step.Kind.CHANGE_ROOM:
					if not _state.enter_room(step.destination_room, step.destination_entry):
						cancel()
						return
					changed = true
		# Sincronizza una volta sola, quando tutti gli effetti della riga sono applicati.
		if changed:
			state_changed.emit()
		if previous_room != _state.room and not _pending.is_empty():
			cancel()
			return
		for line in lines:
			line_requested.emit(line.key, line.speaker)
		if not _pending.is_empty():
			return
		if blocking or row.actions.is_empty() or not row.wait_for_confirmation:
			continue
		if _index < _rows.size() or has_speech:
			waiting_for_confirmation = true
			waiting_changed.emit(true)
		else:
			_finish(false)
		return

## Libera i dati di esecuzione prima di notificare la conclusione.
func _finish(cancelled: bool) -> void:
	busy = false
	waiting_for_confirmation = false
	_pending.clear()
	_rows.clear()
	_state = null
	_rooms = null
	waiting_changed.emit(false)
	finished.emit(cancelled)
