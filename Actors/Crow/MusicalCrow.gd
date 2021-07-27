extends "res://Actors/Crow/Crow.gd"

var note : int = 0
var note_color : Color
var current_color : Color # alpha is unused, Crow.color is the actual color
var target_color : Color  # alpha is unused
var change_speed : float = 20.0
var note_duration_ms : int = 200 # seconds to change into note, double to change back
var transition_speed : float
var is_note_on := false

var current_scale : Vector2
var target_scale : Vector2
var note_scale_factor := 1.8
var _max_scale : Vector2

var _last_note_played_at : int = 0
var _last_note_off_at : int = 0

func _ready() -> void:
    current_scale = base_scale
    target_scale = base_scale
    _max_scale = base_scale * note_scale_factor
    $Sprite.scale = current_scale
    $Sprite/Trail.scale = current_scale
    transition_speed = change_speed


func _process(delta: float) -> void:
    var now = OS.get_ticks_msec()
    var weight = delta * transition_speed

    if is_note_on == false and _last_note_played_at != 0 and now > _last_note_played_at + note_duration_ms:
        _last_note_played_at = 0
        trail_color = color
        target_color = base_color
        target_scale = base_scale
        # trails
        if trail.emitting == true:
            trail.emitting = false
            #trail.visible = false
            #hide_trail(color)

#	if now - _last_note_off_at < 1000 or is_note_on == false and now - _last_note_played_at < 100:
#		# rapid notes, switch immediately
#		weight = 1.0

    if current_color != target_color:
        current_color = current_color.linear_interpolate(target_color, weight)
        color = Color(current_color.r, current_color.g, current_color.b, color.a)
        if is_note_on:
            trail_color = color
    if current_scale != target_scale:
        current_scale = current_scale.linear_interpolate(target_scale, weight)
        if current_scale.x > _max_scale.x:
            current_scale = _max_scale
        $Sprite.scale = current_scale
        $Sprite/Trail.scale = current_scale

# FIXME: not working
#func hide_trail(c : Color, duration : float = 0.3):
#	trail_tween.interpolate_property(
#		trail,
#		"modulate",
#		c * Color(1,1,1,1),
#		c * Color(1,1,1,0),
#		duration,
#		trail_tween.TRANS_SINE,
#		# Easing out means we start fast and slow down as we reach the target value.
#		trail_tween.EASE_OUT
#	)
#	trail_tween.start()

# warning-ignore:shadowed_variable
func set_note(note : int, color : Color) -> void:
    if self.note > 0 and is_in_group("note_" + String(self.note)):
        remove_from_group("note_" + String(self.note))

    if note > 0:
        self.note = note
        self.note_color = color
        add_to_group("note_" + String(note))

func play_note() -> void:
    if _last_note_played_at > 0:
        # still playing note, turn off
        color = base_color
        scale = base_scale
    target_color = note_color
    target_scale = base_scale * note_scale_factor
    transition_speed = change_speed
    _last_note_played_at = OS.get_ticks_msec()
    # trails
    #trail_tween.remove_all()
    if trail.emitting == false:
        trail.emitting = true
        #trail.restart()
        trail.visible = true

func play_alternate_note(c : Color) -> void:
    if not is_note_on:
        target_color = c
        target_scale = base_scale * note_scale_factor
        transition_speed = change_speed
        _last_note_played_at = OS.get_ticks_msec() + 1000 # HACK: stay on this long
        # trails
        #trail_tween.remove_all()
#		if trail.emitting == false:
#			trail.emitting = true
#			#trail.restart()
#			trail.visible = true


func note_on() -> void:
    play_note()
    is_note_on = true

func note_off() -> void:
    is_note_on = false
    transition_speed = 2.0 * change_speed
    _last_note_off_at = OS.get_ticks_msec()


func set_color(c : Color) -> void:
    target_color = c


func set_values(values : Dictionary) -> void:
    .set_values(values)

    set_note(values.get('note', 0), values.get('note_color', Color(1,1,1)))


func set_base_scale(value: float) -> void:
    .set_base_scale(value)
    target_scale = base_scale
    _max_scale = base_scale * note_scale_factor
