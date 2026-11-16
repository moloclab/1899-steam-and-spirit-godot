extends SceneTree
## Verifica il contratto un clic/un'azione attraverso lo stesso input usato dal gioco.
const Main = preload("res://scenes/main.tscn")
const Step = preload("res://scripts/actions/action_step.gd")
var checks := 0
var failures := 0
var game

## Il viewport viene preparato prima della UI e della stanza.
func _initialize() -> void:
	root.size = Vector2i(1152, 720)
	_run.call_deferred()

## Ogni errore viene contato per restituire un esito utilizzabile da riga di comando.
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

## Un clic completo nel mondo deve essere consumato dalla sequenza.
func click() -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(100, 400)
	game._input(event)

## Costruisce un passo dichiarativo senza effetti durante la pianificazione.
func step(kind: Step.Kind, subject_id: String = "player", text_key: String = "") -> Step:
	var action := Step.new()
	action.kind = kind
	action.subject_id = subject_id
	action.text_key = text_key
	return action

## Prova cammino, tre battute, oggetto nascosto, attese, animazioni ed effetti adiacenti.
func _run() -> void:
	game = Main.instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	var walk := step(Step.Kind.WALK)
	walk.target_hotspot_id = "como"
	var first := step(Step.Kind.SAY, "player", "ep01.cabin.interphone.greeting")
	var second := step(Step.Kind.SAY, "player", "ep01.cabin.interphone.reply")
	var third := step(Step.Kind.SAY, "interphone", "ep01.cabin.interphone.summons")
	var actions: Array[Step] = [walk, first, second, third]
	game._start_actions(actions)
	var target: Hotspot = game.rooms.find_hotspot("como")
	var destination := target.approach_position(game.rooms.actor.current_x, game.rooms.actor.half_width)
	check(game.rooms.actor.target_x == destination, "Cammino fino al bordo del comodino")
	click()
	check(not game.sequences.waiting_for_confirmation, "Clic durante il cammino ignorato")
	game._process(10)
	check(game.rooms.actor.has_arrived() and game.sequences.waiting_for_confirmation, "Arrivo abilita la conferma")
	check(game.ui.speech_label.text != game._text(first.text_key), "Arrivo non avvia la prima battuta")
	game._process(10)
	check(game.ui.speech_label.text != game._text(first.text_key), "Clic anticipato non accodato")
	click()
	check(game.ui.speech_label.text == game._text(first.text_key), "Primo clic dopo arrivo: frase 1")
	check(game.ui._speaker_key == game.rooms.actor.speaker_key, "Churchill parla come soggetto")
	click()
	check(game.ui.speech_label.text == game._text(second.text_key), "Secondo clic: frase 2")
	click()
	check(game.ui.speech_label.text == game._text(third.text_key), "Terzo clic: frase 3")
	check(game.ui._speaker_key == "common.speaker.interphone", "Oggetto parla come soggetto")
	check(game.sequences.busy and game.ui.speech_label.visible, "Ultima battuta resta fino alla chiusura")
	click()
	check(not game.sequences.busy and not game.ui.speech_label.visible, "Ultimo clic chiude senza avviare interazioni")
	check(not game.ui.save_buttons[0].disabled, "UI sbloccata alla fine")
	var hide := step(Step.Kind.HIDE, "interphone")
	var effects := {"count": 0}
	var effect := Step.effect(func(): effects.count += 1)
	var immediate: Array[Step] = [first, hide, effect, effect]
	game._start_actions(immediate)
	check(target.visible and game.rooms.find_hotspot("interphone") != null, "Pianificazione senza scomparsa anticipata")
	click()
	check(game.rooms.find_hotspot("interphone") == null and effects.count == 0, "Un clic nasconde solo il soggetto")
	click()
	check(effects.count == 1 and game.sequences.waiting_for_confirmation, "Un clic esegue un solo effetto immediato")
	click()
	check(effects.count == 2 and not game.sequences.busy, "Effetto finale conclude la sequenza")
	var wait := step(Step.Kind.WAIT)
	wait.seconds = 0.5
	var timed: Array[Step] = [wait, effect]
	game._start_actions(timed)
	click()
	game._process(0.25)
	check(effects.count == 2 and not game.sequences.waiting_for_confirmation, "Attesa non saltata dal clic")
	game._process(0.25)
	check(effects.count == 2 and game.sequences.waiting_for_confirmation, "Fine attesa non esegue l'effetto")
	click()
	check(effects.count == 3 and not game.sequences.busy, "Clic dopo attesa esegue l'effetto")
	# Un'animazione reale non ciclica deve finire prima di accettare la conferma.
	var frames: SpriteFrames = game.rooms.actor.sprite_frames.duplicate()
	frames.add_animation("sequence_test")
	frames.add_frame("sequence_test", frames.get_frame_texture("idle", 0))
	frames.set_animation_loop("sequence_test", false)
	frames.set_animation_speed("sequence_test", 20)
	game.rooms.actor.sprite_frames = frames
	var animation := step(Step.Kind.ANIMATE)
	animation.animation_name = "sequence_test"
	var animated: Array[Step] = [animation, effect]
	game._start_actions(animated)
	click()
	check(not game.sequences.waiting_for_confirmation, "Clic non salta l'animazione")
	await create_timer(0.15).timeout
	game._process(0)
	check(effects.count == 3 and game.sequences.waiting_for_confirmation, "Fine animazione aspetta il clic")
	click()
	check(effects.count == 4 and not game.sequences.busy, "Clic dopo animazione esegue l'effetto")
	game._start_actions(timed)
	game.sequences.cancel()
	game._process(10)
	check(effects.count == 4 and not game.sequences.busy, "Annullamento scarta gli effetti futuri")
	var empty: Array[Step] = []
	game._start_actions(empty)
	check(not game.sequences.busy, "Sequenza vuota conclusa")
	game.queue_free()
	await process_frame
	print("Sequenze: %d verifiche, %d errori" % [checks, failures])
	quit(0 if failures == 0 else 1)
