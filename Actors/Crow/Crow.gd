extends "res://Actors/Boid/Boid.gd"

var _highlight = 0.0
var min_highlight = 0.2
var max_highlight = 0.5
var flap : int = 0
var flap_threshold : int
var z_affinity : float = 1.0

func _ready() -> void:
    z_affinity = randf()
    flap_threshold = max_speed * 2

func _process(_delta: float) -> void:
    look_at(global_position + _velocity)

    var r = randf()
    # flap
    flap += momentum * r
    if flap > flap_threshold:
        if $Sprite.frame == 0:
            $Sprite.frame = 1
        else:
            $Sprite.frame = 0
        flap = 0

    # simulated z-depth
    if r < 0.5:
        # adjust randomly
        _highlight -= rand_range(-0.01, 0.01)
    else:
        if _flock_size and _highlight < _flock_size / 10.0:
            _highlight += _flock_size * 0.0001
        elif _highlight > min_highlight && r >= 0.3:
            _highlight -= 0.01

    _highlight = clamp(_highlight, min_highlight, max_highlight)
    var inverse : float = 1.0 - _highlight * z_affinity
    if debug:
        var avoiding = int(_avoiding > 0)
        if momentum < min_speed:
            $Sprite.modulate = Color(0, 1, avoiding)
        else:
            $Sprite.modulate = Color(1.0 - ((max_speed - momentum) / max_speed), 0, avoiding)
    else:
        $Sprite.modulate = Color(0,0,0, inverse)

    # fake z depth by scaling
    scale = Vector2(inverse + min_highlight, inverse + min_highlight)
