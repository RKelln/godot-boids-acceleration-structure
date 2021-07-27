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
export(Vector2) var gravity := Vector2(0, 500)

onready var screen_size = get_viewport_rect().size

var base_scale : Vector2  = Vector2.ONE # base scale of the boid, sets initial scale

var _prev_point = null

var target_vector: Vector2 = Vector2.INF
var target_scalar : float  # modifies strength of target follow (based on distance)
var _velocity: Vector2 setget velocity_set, velocity_get
var momentum : float
var min_speed : float
var _acceleration := Vector2.ZERO
var follow : bool = false # follow mouse location

var _accel_struct : AccelStruct
var _flock_size: int = 0
var _avoiding : float = 0  # in seconds, if positive then avoid
var _targets : Array
var _bounds_cells : int = 10
var bounds_force := 7.0

var flock : Array

# optimizations:
var MAX_PHYSICS_GROUPS := 4
var _physics_group : int
var _active_physics_group : int = 0

var debug : bool = false
var debug_cells : bool = false
var _debug_cells : Array

func _ready():
    add_to_group("boids")

    target_vector = get_random_target()
    _physics_group = randi() % MAX_PHYSICS_GROUPS
    _active_physics_group = randi() % MAX_PHYSICS_GROUPS
    scale = base_scale

    set_speed(max_speed)
    _velocity = _random_direction() * max_speed * rand_range(0.4, 0.8)
    momentum = _velocity.length()

    # randomize settings by variance
#    if variance > 0:
#        max_speed = max_speed * rand_range(1.0 - variance, 1.0 + variance)
#        target_force = target_force * rand_range(1.0 - variance, 1.0 + variance)
#        cohesion_force = cohesion_force * rand_range(1.0 - variance, 1.0 + variance)
#        align_force = align_force * rand_range(1.0 - variance, 1.0 + variance)
#        separation_force = separation_force * rand_range(1.0 - variance, 1.0 + variance)


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
    if debug:
        var local_pos = to_local(global_position)
        for t in _targets:
            draw_line(local_pos, to_local(t), Color(0,0,0,0.2))
        # NOTE: target vector may not be in list of targets (if in follow mode, etc)
        draw_line(local_pos, to_local(target_vector), Color(0, 1, 0, min(target_scalar / 10, 1)))


func _process(delta: float) -> void:
    var verticality = abs(Vector2.UP.dot(_velocity.abs().normalized()))
    _velocity += gravity * verticality * delta # gravity hack: mainly apply when vertical
#    _velocity *= 1.0 - (2.0 * delta) # friction
    momentum = max(1.0, _velocity.length())
    translate(_velocity * delta)
    bound_screen()
    if debug:
        update()


#func _input(event: InputEvent) -> void:
#    if follow and event is InputEventMouseMotion:
#        set_target(event.position)


func _physics_process(delta: float) -> void:
    var scaled_point = _accel_struct.scale_point(position)
    var acceleration := Vector2.ZERO
    _active_physics_group += 1
    if _active_physics_group >= MAX_PHYSICS_GROUPS:
        _active_physics_group = 0

    if not visible:
        return

    # calculate flock influence if active
    if _active_physics_group == _physics_group:
        # follow behaviour
        if follow :
            target_vector = get_global_mouse_position()

        flock = _accel_struct.get_bodies(scaled_point, _velocity, view_distance, debug_cells)
        if debug_cells:
            _debug_cells = _accel_struct._debug()

        # targetting
        var target_direction := Vector2.ZERO
        if _targets.size() == 0 and momentum < min_speed:
            target_vector = choose_target()
        if target_vector == Vector2.INF:
            target_vector = choose_target()
        if target_vector == Vector2.INF:
            target_scalar = 0
        else:
            var distance_to_target = global_position.distance_to(target_vector)
            if distance_to_target < avoid_distance * 3:
                    target_vector = choose_target()
            target_direction = global_position.direction_to(target_vector)
            target_scalar = 10.0 * distance_to_target / _accel_struct.global_bounds.end.x # NOTE if we chose a new target this will be wrong for an update

        # get cohesion, alignment, and separation vectors
        var vectors = get_flock_status(flock)
        _flock_size = vectors[3]

        var separation_scalar := 1.0
        var avoid_scalar := 1.0
        if _avoiding > 0:
            separation_scalar = 20.0
            avoid_scalar = 0.2
            _avoiding -= delta
            if _avoiding < 0:
                _avoiding = 0

        # steer towards vectors
        acceleration += 4 * (  # multiply because of group alternation
            vectors[0] * cohesion_force * avoid_scalar
            + vectors[1] * align_force * avoid_scalar
            + vectors[2] * separation_force * separation_scalar
            + target_direction * target_force * target_scalar)

    # avoid screen edges
    if scaled_point.x <= _accel_struct.x_min + _bounds_cells:
        acceleration += bounds_force * Vector2(momentum / (0.1 + global_position.distance_to(
            Vector2(_accel_struct.global_bounds.position.x, position.y))), 2.0 * sign(_velocity.y))
    if scaled_point.y <= _accel_struct.y_min + _bounds_cells:
        acceleration += bounds_force * Vector2(2.0 * sign(_velocity.x), momentum / (0.1 + global_position.distance_to(
            Vector2(position.x, _accel_struct.global_bounds.position.y))))
    if scaled_point.x >= _accel_struct.x_max - _bounds_cells:
        acceleration += bounds_force * Vector2(- momentum / (0.1 + global_position.distance_to(
            Vector2(_accel_struct.global_bounds.end.x, position.y))), 2.0 * sign(_velocity.y))
    # strongly avoid ground
    if scaled_point.y >= _accel_struct.y_max - (_bounds_cells + 4):
        acceleration += bounds_force * Vector2(2.0 * sign(_velocity.x), - momentum / (0.1 + global_position.distance_to(
            Vector2(position.x, _accel_struct.global_bounds.end.y))))

    _acceleration = lerp(_acceleration, acceleration, 10 * delta).clamped(4 * max_speed) # HACK

    #var accel_scale = 2.0 + min_speed * delta # 1.0 # max(min_speed, momentum * 0.5)
    var accel_scale = 1.0 + max(min_speed, momentum * 0.1) * delta # HACK: conservation of momentum

    # avoid low speeds
    if momentum < min_speed * 2.0:
        accel_scale *= 2.0 - (momentum / (min_speed + 0.1))

    # dart if stalling
    if momentum < min_speed:
        # fall and dart
        _acceleration += _random_direction() * rand_range(0.5, 0.8)
        accel_scale *= 5.0
        _avoiding += rand_range(0.1, 0.5)

    #_velocity = _velocity.linear_interpolate(_velocity + _acceleration, 1.0 - delta).clamped(max_speed)
    _velocity = (_velocity + _acceleration * accel_scale).clamped(max_speed)

    _prev_point = _accel_struct.update_body(self, scaled_point, _prev_point)


func _random_direction() -> Vector2:
    return Vector2(rand_range(-1, 1), rand_range(-1, 1)).normalized()


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
        align_vector += Vector2(rand_range(-1.0, 1.0), rand_range(-1.0, 1.0)) * momentum * variance # imperfect alignment
        flock_center /= flock_size
        center_vector = position.direction_to(flock_center) * position.distance_to(flock_center) / view_distance

    # if avoiding everything
    if flock_size > 5 and avoiding >= flock_size * 0.7:
        _avoiding += 0.3

    return [center_vector, align_vector, avoid_vector, flock_size]


func get_random_target():
    return Vector2(rand_range(_accel_struct.global_bounds.position.x, _accel_struct.global_bounds.end.x),
                   rand_range(_accel_struct.global_bounds.position.y, _accel_struct.global_bounds.end.y))


func set_target(target : Vector2):
    _targets.clear()
    _targets.append(target)
    target_vector = target

func add_target(target : Vector2):
    _targets.append(target)
    target_vector = choose_target()
    #prints(target, _targets.size(), target_vector)

func remove_target(target : Vector2):
    _targets.erase(target)
    if target == target_vector:
        target_vector = choose_target()

func clear_targets() -> void:
    _targets.clear()
    target_vector = Vector2.INF

func choose_target(switch_percent : float = INF) -> Vector2:
    var s = _targets.size()
    if s == 0:
        return get_random_target()
    if s == 1:
        return _targets[0]

    if switch_percent == INF:
        if s > 1:
            switch_percent = 1.0 / float(s)
        else:
            s = 1.0

    if randf() <= switch_percent and target_vector != Vector2.INF:
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


func toggle_follow():
    follow = not follow
    if not follow:
        # remove all targets when we stop following
        #    _targets.clear()
        target_vector = Vector2.INF

func set_follow(f : bool):
    follow = f
    if not follow:
        target_vector = Vector2.INF


func avoid(amount : float = 0) -> void:
    if amount <= 0:
        amount = rand_range(0.1, 0.3)
    _avoiding += amount
    get_random_target()


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
    if values.has('scale'):
        set_base_scale(values.scale)
    if values.has('target_force'):
        set_target_force(values.target_force)
    if values.has('target'):
        set_target(values.target)
    if values.has("debug"):
        set_debug(values.debug)
    if values.has("follow"):
        follow = values.follow

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
    min_speed = max(10.0, max_speed / 5.0)

# change the speed by amount
func change_speed(amount: float) -> float:
    if amount < 0 and -amount >= max_speed:
        amount = -max_speed + 1
    #var change := (max_speed + amount) / max_speed
    #prints(amount, max_speed)
    max_speed = max(1.0, max_speed + amount)
    min_speed = max(1.0, max_speed / 5.0)
    # HACK: instantaneously change speed to better music dancing
    _acceleration = _acceleration.normalized() * max_speed
    _velocity = _velocity.clamped(max_speed)
    return max_speed

func set_base_scale(value: float) -> void:
    var s = _set_with_variance(value)
    base_scale = Vector2(s, s)
    scale = base_scale

func set_view_distance(value: float) -> void:
    view_distance = value

func set_avoid_distance(value: float) -> void:
    avoid_distance = value

func set_debug(b : bool) -> void:
    debug = b

func set_heading(target : Vector2):
    _velocity = Vector2.ZERO
    _acceleration = position.direction_to(target) * max_speed
