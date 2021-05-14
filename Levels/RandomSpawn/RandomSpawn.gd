extends Control

var debug : bool = false

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_released('debug_boids'):
        debug = !debug
        prints("set debug", debug)
        get_tree().call_group('boids', 'set_debug', debug)
    if event.is_action_released('background'):
        $Background.visible = not $Background.visible
    if event.is_action_released('toggle_boid_trails'):
        get_tree().call_group('boids', 'toggle_trails')
    if event.is_action_released('toggle_paint'):
        $PaintTexture.visible = not $PaintTexture.visible
        $PaintViewportContainer.visible = not $PaintViewportContainer.visible
    if event.is_action_released('toggle_music'):
        if $MidiPlayer.playing:
            $MidiPlayer.stop()
            get_tree().call_group('boids', 'note_off')
        else:
            $MidiPlayer.play()
    if event.is_action_released('pause'):
        print("Pause", get_tree().paused)
        get_tree().paused = not get_tree().paused


func _on_MidiPlayer_midi_event(channel, event) -> void:
    Music.midi_note(event)
