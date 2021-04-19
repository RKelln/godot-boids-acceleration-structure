extends "res://Actors/Boid/Boid.gd"

var _highlight = 0.0

func _process(_delta):
    look_at(global_position + _velocity)

    var r = randf()
    if r < 0.5:
        # adjust randomly
        _highlight -= rand_range(-0.01, 0.01)
    else:
        if _flock_size and _highlight < _flock_size / 10.0:
            _highlight += _flock_size / 1000.0
        elif _highlight > 0 && r >= 0.3:
            _highlight -= 0.01

    _highlight = clamp(_highlight, 0, 0.3)
    $Sprite.modulate = Color(_highlight, _highlight, _highlight)
    scale = Vector2(1.0 - _highlight, 1.0 - _highlight)
