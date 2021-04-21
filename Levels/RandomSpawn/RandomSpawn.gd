extends Node2D

const AccelStruct = preload("res://Nodes/AccelStruct/AccelStructure.gd")

export(int) var boids = 20
export(PackedScene) var Boid
export(PackedScene) var Target
export(int) var struct_scale = 10

var boid_rect: Rect2

var _accel_struct: AccelStruct

func _ready():
    var screen_rect := get_viewport_rect()
    boid_rect = Rect2(0, 0, screen_rect.size.x, screen_rect.size.y) # don't include the bottom
    _accel_struct = AccelStruct.new(boid_rect, struct_scale)


func set_count(value: int) -> void:
    var boid_nodes := get_tree().get_nodes_in_group("boids")
    var current_boid_count = boid_nodes.size()
    if current_boid_count < value:
        # add boids
        var screen_size = boid_rect.size
        for _i in range(value - current_boid_count):
            var boid = Boid.instance()
            var init_pos: = Vector2(rand_range(0, screen_size.x), rand_range(0, screen_size.y))
            boid.position = init_pos
            var scaled = _accel_struct.scale_point(init_pos)
            boid._prev_point = scaled
            _accel_struct.add_body(boid, scaled)
            boid._accel_struct = _accel_struct
            add_child(boid)

    if current_boid_count > value:
        # remove boids
        for i in range(current_boid_count - value):
            var boid = boid_nodes[i]
            boid.visible = false
            _accel_struct.remove_body(boid, boid._prev_point)
            boid.queue_free()


func get_random_target():
    randomize()
    return Vector2(rand_range(0, boid_rect.size.x), rand_range(0, boid_rect.size.y))


func _on_FlagArea_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        # NOTE: pressed == false == mouse up
        if event.get_button_index() == BUTTON_LEFT and event.pressed == false:
            # remove all existing targets
            for flag in $FlagArea.get_children():
                flag.visible = false
                flag.queue_free()

            var t = Target.instance()
            t.visible = true
            t.position = event.global_position
            $FlagArea.add_child(t)
            print("set target", t.position)
            get_tree().call_group("boids", "set_target", t.position)

        elif event.get_button_index() == BUTTON_RIGHT and event.pressed == false:
            var t = Target.instance()
            t.visible = true
            t.position = event.global_position
            $FlagArea.add_child(t)
            print("add target", t.position)
            get_tree().call_group("boids", "add_target", t.position)

