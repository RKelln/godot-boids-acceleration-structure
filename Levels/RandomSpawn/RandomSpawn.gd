extends Control

var debug : bool = false

signal add_boid(location)
signal remove_boid

var _boid_rate = 30.0
var _add_boid_pressed := false
var _remove_boid_pressed := false
var _next_boid := 0.0

var _follow := false
var _mouse_motion : Vector2

func _process(delta: float) -> void:
    if _add_boid_pressed or _remove_boid_pressed:
        _next_boid += delta * _boid_rate
        if _next_boid >= 1.0:
            _next_boid = 0.0
            if _add_boid_pressed:
                _add_boid()
            elif _remove_boid_pressed:
                emit_signal("remove_boid")

func _add_boid():
    # set target by mouse relative movement
    var target = get_viewport().get_mouse_position() + (5.0 * _mouse_motion)
    #prints(_mouse_motion, 3.0 * _mouse_motion, get_viewport().get_mouse_position(), target)
    emit_signal("add_boid", get_viewport().get_mouse_position(), target)

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _mouse_motion = event.relative

func set_background(visible : bool) -> void:
    $Background.visible = visible
    if visible:
        $GUIView/GUI.text_color(Color(1,1,1))
    else:
        $GUIView/GUI.text_color(Color(0,0,0))

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_released('debug_boids'):
        debug = !debug
        prints("set debug", debug)
        get_tree().call_group('boids', 'set_debug', debug)
    elif event.is_action_released('background'):
        set_background(!$Background.visible)
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
    elif event.is_action_released('play_video'):
        print("play video")
        if $Background/VideoPlayer.is_playing():
            $Background/VideoPlayer.stop()
        else:
            $Background/VideoPlayer.visible = true
            $Background/VideoPlayer.play()
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
            _add_boid()
        _add_boid_pressed = event.is_pressed()  # allow for echo
    elif event.is_action('remove_boid'):
        if event.is_action_pressed('remove_boid'):
            emit_signal("remove_boid")
        _remove_boid_pressed = event.is_pressed()  # allow for echo
    elif event.is_action_pressed('boid_explode'):
        print("avoid")
        get_tree().call_group('boids', 'avoid')
    elif event.is_action_released('boid_speed_increase'):
        # HACK: FIXME: go through GUI
        get_tree().call_group('boids', 'change_speed', 40 )
    elif event.is_action_released('boid_speed_decrease'):
        # HACK: FIXME: go through GUI
        get_tree().call_group('boids', 'change_speed', -40 )
    elif event.is_action_released('start_recording'):
        print("start recording")
        # start video and change the size to place it at the bottom
        $Background/VideoPlayer.visible = true
        $Background/VideoPlayer.play()
        var scale = 0.3
        $Background.scale = Vector2(scale, scale)
        $Background.position.y = get_viewport().size.y - $Background.texture.get_height() * scale / 2 # position is from center and not scaled

func _on_MidiPlayer_midi_event(_channel, event) -> void:
    Music.midi_note(event)
