extends MarginContainer

export var parameter := "cohesion"
export var group := "boids"
export(float) var initial_value

func _ready() -> void:
    $VBoxContainer/HBoxContainer/HSlider.value = initial_value
    $VBoxContainer/HBoxContainer/SpinBox.value = initial_value
    get_tree().call_group(group, "set_"+parameter, initial_value)

func _on_value_changed(value: float) -> void:
    get_tree().call_group(group, "set_"+parameter, value)

func _on_SpinBox_value_changed(value: float) -> void:
    _on_value_changed(value)
    $VBoxContainer/HBoxContainer/HSlider.value = value

func _on_HSlider_value_changed(value: float) -> void:
    _on_value_changed(value)
    $VBoxContainer/HBoxContainer/SpinBox.value = value
