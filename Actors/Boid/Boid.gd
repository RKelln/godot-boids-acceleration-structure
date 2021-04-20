extends Node2D

export var max_speed: = 200.0
export var mouse_follow_force: = 0.05
export var cohesion_force: = 0.05
export var align_force: = 0.05
export var separation_force: = 0.05
export(float) var view_distance: = 50.0
export(float) var avoid_distance: = 20.0
export(float) var variance: = 0.1

onready var screen_size = get_viewport_rect().size

var _prev_point = null

var _mouse_target: Vector2
var _velocity: Vector2 setget velocity_set, velocity_get

var _accel_struct
var _flock_size: int = 0

func _ready():
    randomize()
    _velocity = Vector2(rand_range(-1, 1), rand_range(-1, 1)).normalized() * max_speed
    _mouse_target = get_random_target()
    # randomize settings by variance
    if variance > 0:
        max_speed = max_speed * rand_range(1.0 - variance, 1.0 + variance)
        mouse_follow_force = mouse_follow_force * rand_range(1.0 - variance, 1.0 + variance)
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

func _physics_process(delta):
    var scaled_point = _accel_struct.scale_point(position)
    var flock = _accel_struct.get_bodies(scaled_point, _velocity)

    var mouse_vector = Vector2.ZERO
    if _mouse_target != Vector2.INF:
        mouse_vector = global_position.direction_to(_mouse_target) * mouse_follow_force

    # get cohesion, alignment, and separation vectors
    var vectors = get_flock_status(flock)

    # steer towards vectors
    var cohesion_vector = vectors[0] * cohesion_force
    var align_vector = vectors[1] * align_force
    var separation_vector = vectors[2] * separation_force
    _flock_size = vectors[3]

    var acceleration =  max_speed * (align_vector + cohesion_vector + separation_vector + mouse_vector)

    velocity_set((_velocity + acceleration).clamped(max_speed))

    _prev_point = _accel_struct.update_body(self, scaled_point, _prev_point)


func get_flock_status(flock: Array):
    var center_vector: = Vector2()
    var flock_center: = Vector2()
    var align_vector: = Vector2()
    var avoid_vector: = Vector2()
    var flock_size: = 0

    for cell in flock:
        for f in cell:
            if f != self:
                var neighbor_pos: Vector2 = f.position

                if position.distance_to(neighbor_pos) < view_distance:
                    flock_size += 1
                    align_vector += f.velocity_get()
                    flock_center += neighbor_pos

                    var d = position.distance_to(neighbor_pos)
                    if d != 0 and d < avoid_distance:
                        avoid_vector -= (neighbor_pos - position).normalized() * (avoid_distance / d)

    if flock_size:
        align_vector /= flock_size
        flock_center /= flock_size

        var center_dir = position.direction_to(flock_center)
        var center_speed = (position.distance_to(flock_center) / view_distance)
        center_vector = center_dir * center_speed

    return [center_vector, align_vector, avoid_vector, flock_size]


func get_random_target():
    randomize()
    return Vector2(rand_range(0, screen_size.x), rand_range(0, screen_size.y))


func set_target(target : Vector2):
    _mouse_target = target


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
