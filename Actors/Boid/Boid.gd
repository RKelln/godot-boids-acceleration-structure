extends Node2D

const AccelStruct = preload("res://Nodes/AccelStruct/AccelStructure.gd")

export var max_speed: = 200.0
export var target_force: = 0.05
export var cohesion_force: = 0.05
export var align_force: = 0.05
export var separation_force: = 0.05
export(float) var view_distance: = 50.0
export(float) var avoid_distance: = 20.0
export(float) var variance: = 0.1
export(Vector2) var gravity := Vector2.ZERO

onready var screen_size = get_viewport_rect().size

var _prev_point = null

var target_vector: Vector2 = Vector2.INF
var _velocity: Vector2 setget velocity_set, velocity_get
var momentum : float
var min_speed : float
var _acceleration := Vector2.ZERO

var _accel_struct : AccelStruct
var _flock_size: int = 0
var _avoiding : int = 0
var _targets : Array
var _bounds_cells : int = 5
var bounds_force := 1.0

var paint_viewport : Viewport

# optimizations:
var MAX_PHYSICS_GROUPS := 4
var _physics_group : int
var _active_physics_group : int = 0

var debug : bool = false
var debug_cells : bool = false
var _debug_cells : Array

func _ready():
    add_to_group("boids")
    _velocity = Vector2(rand_range(-1, 1), rand_range(-1, 1)).normalized() * max_speed
    target_vector = get_random_target()
    min_speed = max_speed / 10
    _physics_group = randi() % MAX_PHYSICS_GROUPS
    _active_physics_group = randi() % MAX_PHYSICS_GROUPS
    # randomize settings by variance
    if variance > 0:
        max_speed = max_speed * rand_range(1.0 - variance, 1.0 + variance)
        target_force = target_force * rand_range(1.0 - variance, 1.0 + variance)
        cohesion_force = cohesion_force * rand_range(1.0 - variance, 1.0 + variance)
        align_force = align_force * rand_range(1.0 - variance, 1.0 + variance)
        separation_force = separation_force * rand_range(1.0 - variance, 1.0 + variance)


func _draw() -> void:
    if debug_cells:
        var s := _debug_cells.size()
        if s > 0:
            var each := 1.0 / s
            for i in range(_debug_cells.size()):
                var r : Rect2 = _debug_cells[i]
                r.position = to_local(r.position)
                draw_rect(r, Color(1.0, 0, 0, 1.0 - i * each))
        var local_pos = to_local(global_position)
        draw_circle(local_pos, view_distance, Color(0, 0, 1.0, 0.2))
        draw_line(local_pos, to_local(target_vector), Color(0,0,0,target_force))


func _process(delta: float) -> void:
    _velocity += gravity * delta # gravity
#    _velocity *= 1.0 - (2.0 * delta) # friction
    momentum = max(1.0, _velocity.length())
    translate(_velocity * delta)
    bound_screen()
    if debug_cells:
        update()

func _physics_process(delta: float) -> void:
    var scaled_point = _accel_struct.scale_point(position)
    var acceleration := Vector2.ZERO
    _active_physics_group += 1
    if _active_physics_group >= MAX_PHYSICS_GROUPS:
        _active_physics_group = 0

    if _active_physics_group == _physics_group:
        var flock = _accel_struct.get_bodies(scaled_point, _velocity, view_distance, debug_cells)
        if debug_cells:
            _debug_cells = _accel_struct._debug()

        # targetting
        var target_direction := Vector2.ZERO
        if _targets.size() == 0 and momentum < min_speed:
            target_vector = choose_target()
        if target_vector != Vector2.INF and global_position.distance_to(target_vector) < avoid_distance * 2:
                target_vector = choose_target()
        target_direction = global_position.direction_to(target_vector)

        # get cohesion, alignment, and separation vectors
        var vectors = get_flock_status(flock)
        _flock_size = vectors[3]

        # steer towards vectors
        acceleration += 4 * (  # multiply by 2 because of group alternation
            vectors[0] * cohesion_force
            + vectors[1] * align_force
            + vectors[2] * separation_force
            + target_direction * target_force)
        if _avoiding > 0:
            # don't make big changes to acceleration
            acceleration /= float(10 * _avoiding)

    # dart if too slow
    #if momentum < min_speed + variance:
    #    acceleration += global_position.direction_to(get_random_target())

    # avoid screen edges
    if scaled_point.x <= _accel_struct.x_min + _bounds_cells:
        acceleration += bounds_force * Vector2(momentum / (0.1 + global_position.distance_to(
            Vector2(_accel_struct.global_bounds.position.x, position.y))), sign(_velocity.y))
    if scaled_point.y <= _accel_struct.y_min + _bounds_cells:
        acceleration += bounds_force * Vector2(sign(_velocity.x), momentum / (0.1 + global_position.distance_to(
            Vector2(position.x, _accel_struct.global_bounds.position.y))))
    if scaled_point.x >= _accel_struct.x_max - _bounds_cells:
        acceleration += bounds_force * Vector2(- momentum / (0.1 + global_position.distance_to(
            Vector2(_accel_struct.global_bounds.end.x, position.y))), sign(_velocity.y))
    # strongly avoid ground
    if scaled_point.y >= _accel_struct.y_max - (_bounds_cells + 6):
        acceleration += bounds_force * Vector2(sign(_velocity.x), - momentum / (0.1 + global_position.distance_to(
            Vector2(position.x, _accel_struct.global_bounds.end.y))))

    _acceleration = _acceleration.linear_interpolate(min(min_speed, momentum) * acceleration, 1.0 - delta).clamped(max_speed * delta + momentum)

    if momentum < min_speed:
        # fall and dart
        _acceleration += Vector2(max_speed * rand_range(-0.5, 0.5), gravity.y)
        _avoiding += 1

    #_velocity = _velocity.linear_interpolate(_velocity + _acceleration, 1.0 - delta).clamped(max_speed)
    _velocity = (_velocity + _acceleration).clamped(max_speed)

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
                        #avoid_vector -= (f.position - position).normalized() * (avoid_distance / (d + 0.01))
                        avoid_vector -= f.position - position
                        avoiding += 1

            if flock_size >= max_flock_size:
                break
        if flock_size >= max_flock_size:
            break

    if flock_size:
        align_vector /= flock_size
        align_vector += Vector2(rand_range(-1.0, 1.0), rand_range(-1.0, 1.0)) * max_speed * variance # imperfect alignment
        flock_center /= flock_size
        center_vector = position.direction_to(flock_center) * position.distance_to(flock_center) / view_distance

    # if avoiding everything
    if flock_size > 5 and avoiding >= flock_size * 0.7:
        _avoiding += 1
    elif _avoiding > 0:
        _avoiding -= 1

    return [center_vector, align_vector, avoid_vector, flock_size]


func get_random_target():
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
        return get_random_target()
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
    position.x = clamp(position.x, _accel_struct.global_bounds.position.x, _accel_struct.global_bounds.end.x)
    position.y = clamp(position.y, _accel_struct.global_bounds.position.y, _accel_struct.global_bounds.end.y)
    if (position.x == _accel_struct.global_bounds.position.x or
       position.y == _accel_struct.global_bounds.position.y or
       position.x == _accel_struct.global_bounds.end.x or
       position.y == _accel_struct.global_bounds.end.y):
        _velocity = -_velocity


func velocity_set(velocity: Vector2):
    _velocity = velocity

func velocity_get():
    return _velocity

func set_values(values : Dictionary) -> void:
    if values.has('variance'):
        set_variance(values.variance)
    if values.has('cohesion'):
        set_cohesion(values.cohesion)
    if values.has('alignment'):
        set_alignment(values.alignment)
    if values.has('separation'):
        set_separation(values.separation)
    if values.has('view_distance'):
        set_view_distance(values.view_distance)
    if values.has('avoid_distance'):
        set_avoid_distance(values.avoid_distance)
    if values.has('speed'):
        set_speed(values.speed)
    if values.has('target'):
        set_target_force(values.target)
    if values.has('target_force'):
        set_target_force(values.target_force)

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

func set_debug(b : bool) -> void:
    debug = b
