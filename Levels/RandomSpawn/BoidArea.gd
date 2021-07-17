extends Node2D

const AccelStruct = preload("res://Nodes/AccelStruct/AccelStructure.gd")

export(int) var boids = 20
export(PackedScene) var Boid
export(PackedScene) var Target
export(int) var struct_scale = 10

var boid_rect: Rect2

var _accel_struct: AccelStruct

onready var gui := get_node("/root/RandomSpawn/GUIView/GUI")
onready var camera := get_node("/root/RandomSpawn/ZoomingCamera2D")

# internal padding from edge of screen
# default to don't include the bottom
export var x_padding := Vector2(0,0) # left, right
export var y_padding := Vector2(0,250) # top, bottom

func _ready() -> void:
    var screen_rect := get_viewport_rect()
    boid_rect = Rect2(x_padding.x, y_padding.x, screen_rect.size.x - x_padding.y, screen_rect.size.y - y_padding.y)
    _accel_struct = AccelStruct.new(boid_rect, struct_scale)
    _accel_struct.debug = false


func set_count(value: int) -> void:
    var boid_nodes := get_tree().get_nodes_in_group("boids")
    var current_boid_count = boid_nodes.size()
    prints("set count to", value, "from", current_boid_count)
    if current_boid_count < value:
        # add boids
        var values = gui.get_current_values()
        for _i in range(value - current_boid_count):
            var init_pos: = Vector2(rand_range(boid_rect.position.x + 10, boid_rect.end.x - 10), rand_range(boid_rect.position.y + 10, boid_rect.end.y - 10))
            add_boid(init_pos, values)

    if current_boid_count > value:
        # remove boids
        for i in range(current_boid_count - value):
            var boid = boid_nodes[i]
            remove_boid(boid)


func get_random_target():
    randomize()
    return Vector2(rand_range(0, boid_rect.size.x) + x_padding.x, rand_range(0, boid_rect.size.y) + y_padding.x)


func _on_FlagArea_gui_input(event: InputEvent) -> void:
    #return
    if event is InputEventMouseButton:
        # NOTE: pressed == false == mouse up
        if event.get_button_index() == BUTTON_LEFT and event.pressed == false:

                # hold shift to add more than one
                if not Input.is_key_pressed(KEY_SHIFT):
                    # remove all existing targets
                    for flag in $FlagArea.get_children():
                        flag.visible = false
                        flag.queue_free()

                var t = Target.instance()
                t.visible = false
                t.position = get_global_mouse_position()
                $FlagArea.add_child(t)
                print("set target", t.position)
                get_tree().call_group("boids", "set_target", t.position)

        elif event.get_button_index() == BUTTON_RIGHT and event.pressed == false:
            # remove all existing targets
            for flag in $FlagArea.get_children():
                flag.visible = false
                flag.queue_free()


func _clamp_to_area(point : Vector2) -> Vector2:
    var v : Vector2
    v.x = clamp(point.x, boid_rect.position.x, boid_rect.end.x)
    v.y = clamp(point.y, boid_rect.position.y, boid_rect.end.y)
    return v

func add_boid(location : Vector2, values : Dictionary, target : Vector2 = Vector2.INF) -> void:
    var boid = Boid.instance()

    boid.position = _clamp_to_area(location)
    var scaled = _accel_struct.scale_point(boid.position)
    boid._prev_point = scaled
    _accel_struct.add_body(boid, scaled)
    boid._accel_struct = _accel_struct

    boid.set_values(values)

    # add to notes
    var note = Music.notes[Music.rand_note()]
    boid.set_values(note)

    # set target
    if target != Vector2.INF:
        boid.set_target(_clamp_to_area(target))

    add_child(boid)

func remove_boid(boid) -> void:
    boid.visible = false
    _accel_struct.remove_body(boid, boid._prev_point)
    boid.queue_free()


func _on_add_boid(location : Vector2, target : Vector2 = Vector2.INF) -> void:
    var values = gui.get_current_values()
    # get first flag as target
    if target == Vector2.INF and  $FlagArea.get_child_count() > 0:
        target = $FlagArea.get_child(0).position
    add_boid(location, values, target)


func _on_remove_boid() -> void:
    var boid_nodes := get_tree().get_nodes_in_group("boids")
    var current_boid_count = boid_nodes.size()
    if current_boid_count > 0:
        remove_boid(boid_nodes[0])
