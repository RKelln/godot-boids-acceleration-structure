extends Node2D


func _init():
    visible = false


func _on_MarkerFlag_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
    if event is InputEventMouseButton:
        if event.get_button_index() == BUTTON_LEFT and not event.is_pressed():
            visible = false
            get_tree().call_group("boids", "remove_target", event.position)
            queue_free()
