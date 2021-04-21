extends Node2D

export var max_speed: = 200.0
export var target_force: = 0.05
export var cohesion_force: = 0.05
export var align_force: = 0.05
export var separation_force: = 0.05
export(float) var view_distance: = 50.0
export(float) var avoid_distance: = 20.0
export(float) var variance: = 0.1

onready var screen_size = get_viewport_rect().size

var _prev_point = null

var target_vector: Vector2
var _velocity: Vector2 setget velocity_set, velocity_get

var _accel_struct
var _flock_size: int = 0
var _avoiding : int = 0
var _targets : Array

func _ready():
    add_to_group("boids")
    _velocity = Vector2(rand_range(-1, 1), rand_range(-1, 1)).normalized() * max_speed
    target_vector = get_random_target()
    # randomize settings by variance
    if variance > 0:
        max_speed = max_speed * rand_range(1.0 - variance, 1.0 + variance)
        target_force = target_force * rand_range(1.0 - variance, 1.0 + variance)
        cohesion_force = cohesion_force * rand_range(1.0 - variance, 1.0 + variance)
        align_force = align_force * rand_range(1.0 - variance, 1.0 + variance)
        separation_force = separation_force * rand_range(1.0 - variance, 1.0 + variance)

#func _input(event):
#    if event is InputEventMouseButton:
#        if event.get_button_index() == BUTTON_LEFT:
#            _mouse_target = event.position
#        elif event.get_button_index() == BUTTON_RIGHT:
#            _mouse_target = get_random_target()


func _process(delta):
    translate(_velocity * delta)
    #wrap_screen()
    bound_screen()

func _physics_process(_delta):
    var scaled_point = _accel_struct.scale_point(position)
    var flock = _accel_struct.get_bodies(scaled_point, _velocity, view_distance)

    var target_direction := Vector2.ZERO
    if _targets.size() > 0:
        if global_position.distance_to(target_vector) < avoid_distance:
            target_vector = choose_target()
        target_direction = global_position.direction_to(target_vector)

    # get cohesion, alignment, and separation vectors
    var vectors = get_flock_status(flock)
    _flock_size = vectors[3]

    # steer towards vectors
#    var cohesion_vector = vectors[0] * cohesion_force
#    var align_vector = vectors[1] * align_force
#    var separation_vector = vectors[2] * separation_force

    var acceleration =  max_speed * (
        vectors[0] * cohesion_force
        + vectors[1] * align_force
        + vectors[2] * separation_force
        + target_direction * target_force)
    if _avoiding > 0:
        # don't make big changes to acceleration
        acceleration /= float(100 * _avoiding)
        #acceleration += (target_vector + _velocity) * 0.5

    _velocity = (_velocity + acceleration).clamped(max_speed)
    #_velocity +=  Vector2(0, 9.8) # gravity

    _prev_point = _accel_struct.update_body(self, scaled_point, _prev_point)


func get_flock_status(flock: Array):
    var center_vector: = Vector2()
    var flock_center: = Vector2()
    var align_vector: = Vector2()
    var avoid_vector: = Vector2()
    var flock_size: = 0
    var d : float
    var max_flock_size = 30
    var avoiding := 0

    # note: first cell is the cell boid is currently in
    for cell in flock:
        for f in cell:
            if f != self:
                d = position.distance_to(f.position)

                if d < view_distance:
                    flock_size += 1
                    align_vector += f.velocity_get()
                    flock_center += f.position

                    if d > 0 and d < avoid_distance:
                        avoid_vector -= (f.position - position).normalized() * (avoid_distance / (d + 0.1))
                        #avoid_vector -= f.position - position
                        avoiding += 1

            if flock_size >= max_flock_size:
                break
        if flock_size >= max_flock_size:
            break

    if flock_size:
        align_vector /= flock_size
        flock_center /= flock_size

        #var center_dir = position.direction_to(flock_center)
        #var center_speed = ( / view_distance)
        #center_vector = center_dir * center_speed
        center_vector = position.direction_to(flock_center) * position.distance_to(flock_center) / view_distance

    # if avoiding everything
    if flock_size > 10 and avoiding >= flock_size * 0.66:
        _avoiding += 1
        #align_vector /= 2
        #center_vector /= 2
    elif _avoiding > 0:
        _avoiding -= 1

    return [center_vector, align_vector, avoid_vector, flock_size]


func get_random_target():
    randomize()
    return Vector2(rand_range(0, screen_size.x), rand_range(0, screen_size.y))


func set_target(target : Vector2):
    _targets.clear()
    _targets.append(target)
    target_vector = target

func add_target(target : Vector2):
    _targets.append(target)
    target_vector = choose_target(1.0 / _targets.size())

func remove_target(target : Vector2):
    _targets.erase(target)
    if target == target_vector:
        target_vector = choose_target()

func choose_target(switch_percent : float = 1.0) -> Vector2:
    var s = _targets.size()
    if s == 0:
        return Vector2.ZERO
    if s == 1:
        return _targets[0]

    if randf() > switch_percent:
        # stay with current target
        return target_vector

    # go to closest that is outside avoidance range
    var closest := 0
    var closest_d : float = 100000
    var d : float
    for i in range(s):
        if _targets[i] != target_vector:
            d = global_position.distance_to(_targets[i])
            if d > avoid_distance and d < closest_d:
                closest = i
                closest_d = d
    return _targets[closest]


func wrap_screen():
    position.x = wrapf(position.x, 0, screen_size.x)
    position.y = wrapf(position.y, 0, screen_size.y)


func bound_screen():
    position.x = clamp(position.x, 0, screen_size.x)
    position.y = clamp(position.y, 0, screen_size.y)


func velocity_set(velocity: Vector2):
    _velocity = velocity

func velocity_get():
    return _velocity

func _set_with_variance(value: float) -> float:
    if variance > 0:
        return value * rand_range(1.0 - variance, 1.0 + variance)
    return value

func set_variance(value: float) -> void:
    variance = value

func set_cohesion(value: float) -> void:
    cohesion_force = _set_with_variance(value)

func set_alignment(value: float) -> void:
    align_force = _set_with_variance(value)

func set_separation(value: float) -> void:
    separation_force = _set_with_variance(value)

func set_target_force(value: float) -> void:
    target_force = _set_with_variance(value)

func set_speed(value: float) -> void:
    max_speed = _set_with_variance(value)

func set_view_distance(value: float) -> void:
    view_distance = value

func set_avoid_distance(value: float) -> void:
    avoid_distance = value
