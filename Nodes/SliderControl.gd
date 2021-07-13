extends MarginContainer

export var parameter := "cohesion"
export var group := "boids"
export(float) var initial_value
export(float) var value_scalar := 0.01

var _value : float = 0
var _display_value : float = 0

func _ready() -> void:
    $VBoxContainer/HBoxContainer/HSlider.value = initial_value
    $VBoxContainer/HBoxContainer/SpinBox.value = initial_value
    #_on_value_changed(initial_value)

func _on_value_changed(value: float) -> void:
    if value != _display_value:
        _display_value = value
        _value = value * value_scalar
        get_tree().call_group(group, "set_"+parameter, _value)

func _on_SpinBox_value_changed(value: float) -> void:
    _on_value_changed(value)
    $VBoxContainer/HBoxContainer/HSlider.value = value
    # prevent further keyboard input from being placed inside spinbox
    $VBoxContainer/HBoxContainer/HSlider.grab_focus()

func _on_HSlider_value_changed(value: float) -> void:
    _on_value_changed(value)
    $VBoxContainer/HBoxContainer/SpinBox.value = value

func get_value() -> float:
    return _value

func _on_add_boid(_loc: Vector2) -> void:
    _display_value += 1.0
    _value = _display_value * value_scalar
    $VBoxContainer/HBoxContainer/SpinBox.value = _display_value
    $VBoxContainer/HBoxContainer/HSlider.value = _display_value

func _on_remove_boid() -> void:
    if _display_value > 0:
        _display_value -= 1.0
        _value = _display_value * value_scalar
        $VBoxContainer/HBoxContainer/SpinBox.value = _display_value
        $VBoxContainer/HBoxContainer/HSlider.value = _display_value
