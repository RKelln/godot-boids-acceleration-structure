extends "res://Actors/Boid/Boid.gd"

var _highlight = 0.0
var min_highlight = 0.2
var max_highlight = 0.5
var flap = 0

func _process(_delta):
    look_at(global_position + _velocity)

    var r = randf()
    # flap
    if r < 0.5:
        $Sprite.frame = 0
    else:
        $Sprite.frame = 1

    # simulated z-depth
    if r < 0.5:
        # adjust randomly
        _highlight -= rand_range(-0.01, 0.01)
    else:
        if _flock_size and _highlight < _flock_size / 10.0:
            _highlight += _flock_size / 1000.0
        elif _highlight > min_highlight && r >= 0.3:
            _highlight -= 0.01

    _highlight = clamp(_highlight, min_highlight, max_highlight)
    var inverse : float = 1.0 - _highlight
    $Sprite.modulate = Color(0,0,0, inverse)
    scale = Vector2(inverse + min_highlight, inverse + min_highlight)
