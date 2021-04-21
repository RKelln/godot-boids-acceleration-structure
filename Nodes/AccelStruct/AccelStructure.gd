extends Node

var _cells: Array
var _scale: int

var x_min: int
var x_max: int
var y_min: int
var y_max: int
var global_bounds: Rect2

func _init(bounds: Rect2, scale: int):
    _scale = scale
    global_bounds = bounds
    x_min = _scale_axis(bounds.position.x)
    x_max = _scale_axis(bounds.end.x)
    y_min = _scale_axis(bounds.position.y)
    y_max = _scale_axis(bounds.end.y)

    _cells = range(x_min, x_max + 1)

    for x in range(_cells.size()):
        _cells[x] = range(y_min, y_max + 1)
        for y in _cells[x].size():
            _cells[x][y] = []


func _scale_axis(point: float) -> int:
    return int(floor(point / _scale))


func scale_point(vector: Vector2) -> Vector2:
    return (vector / _scale).floor()


func add_body(body: Node2D, scaled_point: Vector2) -> void:
    _cells[scaled_point.x][scaled_point.y].append(body)


func remove_body(body: Node2D, scaled_point: Vector2) -> void:
    _cells[scaled_point.x][scaled_point.y].erase(body)


func update_body(body: Node2D, scaled_point: Vector2, prev_point: Vector2) -> Vector2:

    if scaled_point != prev_point:
        remove_body(body, prev_point)
        add_body(body, scaled_point)
        return scaled_point
    else:
        return prev_point


func get_bodies(scaled_point: Vector2, facing: Vector2, distance: float = 0):
    var x = scaled_point.x
    var y = scaled_point.y

    var d : int = 1
    if distance > _scale:
        d = _scale_axis(distance)

    var bodies = [_cells[x][y]]

    # find all cells around boid up to distance
    # TODO: onlylook ahead and to the side

#    var least_x : int = max(0, x - d)# if facing.x <= 0 else x
#    var most_x : int = min(x_max, x + d)# if facing.x >= 0 else x
#
#    var least_y : int = max(0, y - d) #if facing.y <= 0 else y
#    var most_y : int = min(y_max, y + d) #if facing.y >= 0 else y

    var signed := facing.sign()
    var horiz : bool = abs(facing.x) >= abs(facing.y)

    var jmin : int
    var jmax : int

    # add bodies from nearest to farthest
    for i in range(1, d+1):
        if horiz:
            jmin = y_max - y
            jmax = y_max - y
            if signed.x < 0 and x - i >= x_min:
                for j in range(max(jmin, 1 - i), min(jmax, i)):
                    bodies.append(_cells[x - i][y + j])
            if signed.x > 0 and x + i < x_max:
                for j in range(max(jmin, 1 - i), min(jmax, i)):
                    bodies.append(_cells[x + i][y + j])
        else:
            jmin = x_min - x
            jmax = x_max - x
            if signed.y < 0 and y - i >= y_min:
                for j in range(max(jmin, 1 - i), min(jmax, i)):
                    bodies.append(_cells[x + j][y - i])
            if signed.y > 0 and y + i < y_max:
                for j in range(max(jmin, 1 - i), min(jmax, i)):
                    bodies.append(_cells[x + j][y + i])
        if bodies.size() > 30:
            break

#    for cell_x in range(least_x, most_x + 1):
#        for cell_y in range(least_y, most_y + 1):
#            if cell_x != x and cell_y != y:
#                bodies.append(_cells[cell_x][cell_y])

    return bodies
