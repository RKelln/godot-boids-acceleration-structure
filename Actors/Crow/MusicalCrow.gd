extends "res://Actors/Crow/Crow.gd"

var note : int = 0
var note_color : Color
var current_color : Color # alpha is unused, Crow.color is the acualt color
var target_color : Color  # alpha is unused
var change_speed : float = 20.0
var note_duration : float = 0.3 # seconds to change into note, double to change back
var transition_speed : float
var note_on := false

export var initial_scale : Vector2 = Vector2(0.4, 0.4)
var current_scale : Vector2
var target_scale : Vector2
var note_scale_factor := 2.0

var _last_note_played_at : int = 0

func _ready() -> void:
    current_scale = initial_scale
    target_scale = initial_scale
    $Sprite.scale = current_scale
    $Sprite/Trail.scale = current_scale
    transition_speed = change_speed

func _process(delta: float) -> void:
    if current_color != target_color:
        current_color = current_color.linear_interpolate(target_color, delta * transition_speed)
        color = Color(current_color.r, current_color.g, current_color.b, color.a)
    if current_scale != target_scale:
        current_scale = current_scale.linear_interpolate(target_scale, delta * transition_speed)
        $Sprite.scale = current_scale
        $Sprite/Trail.scale = current_scale

    if note_on == false and _last_note_played_at != 0 and OS.get_ticks_msec() > _last_note_played_at + (note_duration * 1000):
        _last_note_played_at = 0
        target_color = base_color
        target_scale = initial_scale
        transition_speed = 2.0 * change_speed
        # trails
        if trail.emitting == true:
            trail.emitting = false
            trail.visible = false

func set_note(note : int, color : Color) -> void:
    if self.note > 0 and is_in_group("note_" + String(self.note)):
        remove_from_group("note_" + String(self.note))

    if note > 0:
        self.note = note
        self.note_color = color
        add_to_group("note_" + String(note))

func play_note() -> void:
    target_color = note_color
    target_scale = initial_scale * note_scale_factor
    transition_speed = change_speed
    _last_note_played_at = OS.get_ticks_msec()
    # trails
    if trail.emitting == false:
        trail.emitting = true
        trail.restart()
        trail.visible = true

func note_on() -> void:
    play_note()
    note_on = true

func note_off() -> void:
    note_on = false

func set_color(c : Color) -> void:
    target_color = c

func set_values(values : Dictionary) -> void:
    .set_values(values)

    set_note(values.get('note', 0), values.get('note_color', Color(1,1,1)))
