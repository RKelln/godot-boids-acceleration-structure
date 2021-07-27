extends Control

onready var fps := $HBoxContainer/FPS

var _hidden := false

func get_current_values() -> Dictionary:
    return {
        'cohesion' : $HBoxContainer/Cohesion.get_value(),
        'alignment' : $HBoxContainer/Alignment.get_value(),
        'separation' : $HBoxContainer/Separation.get_value(),
        'target_force' : $HBoxContainer/Target.get_value(),
        'view' : $HBoxContainer/SightRange.get_value(),
        'avoid' : $HBoxContainer/AvoidRange.get_value(),
        'speed' :$HBoxContainer/Speed.get_value(),
        'scale' :$HBoxContainer/Scale.get_value(),
        'count' : $HBoxContainer/Count.get_value()
    }

func text_color(c : Color) -> void:
    get_tree().call_group("text", "set_modulate", c)

func _process(_delta: float) -> void:
    fps.text = str("FPS:",(Engine.get_frames_per_second()))

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_released("toggle_gui"):
        _hidden = !_hidden
        visible = !_hidden
    if event.is_action_pressed("toggle_help"):
        # annoyingly the popup handles cancellingitself on pressed instead of released
        # so we only have to trigger it, and it must be on pressed
        if not $Help.visible:
            $Help.popup_centered()


func _on_Quit_pressed() -> void:
    get_tree().quit()
