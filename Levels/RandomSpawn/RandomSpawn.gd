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
        $PaintTexture.visible = not $PaintTexture.visible
        $PaintViewportContainer.visible = not $PaintViewportContainer.visible
