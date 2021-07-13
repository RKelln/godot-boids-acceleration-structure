extends Control

var debug : bool = false

signal add_boid(location)
signal remove_boid

var _boid_rate = 20.0
var _add_boid_pressed := false
var _remove_boid_pressed := false
var _next_boid := 0.0

var _follow := false


func _process(delta: float) -> void:
    if _add_boid_pressed or _remove_boid_pressed:
        _next_boid += delta * _boid_rate
        if _next_boid >= 1.0:
            _next_boid = 0.0
            if _add_boid_pressed:
                emit_signal("add_boid", get_viewport().get_mouse_position())
            elif _remove_boid_pressed:
                emit_signal("remove_boid")


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_released('debug_boids'):
        debug = !debug
        prints("set debug", debug)
        get_tree().call_group('boids', 'set_debug', debug)
    elif event.is_action_released('background'):
        $Background.visible = not $Background.visible
    elif event.is_action_released('toggle_boid_trails'):
        get_tree().call_group('boids', 'toggle_trails')
    elif event.is_action_released('toggle_paint'):
        $PaintTexture.visible = not $PaintTexture.visible
        $PaintViewportContainer.visible = not $PaintViewportContainer.visible
    elif event.is_action_released('toggle_music'):
        if $MidiPlayer.playing:
            $MidiPlayer.stop()
            get_tree().call_group('boids', 'note_off')
        else:
            $MidiPlayer.play()
    elif event.is_action_released('pause'):
        print("Pause", get_tree().paused)
        get_tree().paused = not get_tree().paused
    elif event.is_action_released('toggle_follow'):
        _follow = !_follow
        prints("Set follow:", _follow)
        get_tree().call_group('boids', 'toggle_follow')
        if _follow: # TODO: FIXME:
            Input.set_default_cursor_shape(Input.CURSOR_CROSS)
        else:
            Input.set_default_cursor_shape(Input.CURSOR_ARROW)
    elif event.is_action('add_boid'):
        if event.is_action_pressed('add_boid'):
            emit_signal("add_boid", get_viewport().get_mouse_position())
        _add_boid_pressed = event.is_pressed()  # allow for echo
    elif event.is_action('remove_boid'):
        if event.is_action_pressed('remove_boid'):
            emit_signal("remove_boid")
        _remove_boid_pressed = event.is_pressed()  # allow for echo
    elif event.is_action_pressed('boid_explode'):
        get_tree().call_group('boids', 'avoid')

func _on_MidiPlayer_midi_event(_channel, event) -> void:
    Music.midi_note(event)
