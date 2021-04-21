extends MarginContainer

export var parameter := "cohesion"
export var group := "boids"
export(float) var initial_value
export(float) var value_scalar := 0.01

var _value : float = 0

func _ready() -> void:
    $VBoxContainer/HBoxContainer/HSlider.value = initial_value
    $VBoxContainer/HBoxContainer/SpinBox.value = initial_value
    _value = initial_value * value_scalar
    _on_value_changed(initial_value)

func _on_value_changed(value: float) -> void:
    _value = value * value_scalar
    get_tree().call_group(group, "set_"+parameter, _value)

func _on_SpinBox_value_changed(value: float) -> void:
    _on_value_changed(value)
    $VBoxContainer/HBoxContainer/HSlider.value = value

func _on_HSlider_value_changed(value: float) -> void:
    _on_value_changed(value)
    $VBoxContainer/HBoxContainer/SpinBox.value = value

func get_value() -> float:
    return _value
