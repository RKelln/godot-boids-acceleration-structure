extends Node

var _cells: Array
var _scale: int

var x_min: int
var x_max: int
var y_min: int
var y_max: int
var global_bounds: Rect2

var max_bodies_optimization : int = 16

var debug := false
var _debug_cells: Array

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

func _debug() -> Array:
    # convert to Rect2
    var rects = []
    for cell in _debug_cells:
        rects.append(Rect2(cell.x * _scale, cell.y * _scale, _scale, _scale))
    _debug_cells.clear()
    return rects

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


func get_bodies(scaled_point: Vector2, facing: Vector2, distance: float = 0, debug_single : bool = false):
    var x = scaled_point.x
    var y = scaled_point.y

    var d : int = 1
    if distance > _scale:
        d = _scale_axis(distance)

    var bodies = [_cells[x][y]]
    if debug and debug_single:
        _debug_cells.append(Vector2(x,y))

    var signed := facing.sign()
    var horiz : bool = abs(facing.x) >= abs(facing.y)
    var jmin : int
    var jmax : int

    # add bodies from nearest to farthest
    var w := d / 2
    if horiz:
        jmin = y_min - y
        jmax = y_max - y
        # add cells beside
        for i in range(1, w+2):
            # add cells in front
            if signed.x < 0 and x - i >= x_min:
                for j in range(max(jmin, 1 - i - w), min(jmax, i + w)):
                    bodies.append(_cells[x - i][y + j])
            if signed.x > 0 and x + i < x_max:
                for j in range(max(jmin, 1 - i - w), min(jmax, i + w)):
                    bodies.append(_cells[x + i][y + j])
            # add cells beside
            if y - i >= y_min:
                bodies.append(_cells[x][y - i])
            if y + i < y_max:
                bodies.append(_cells[x][y + i])
            if bodies.size() > max_bodies_optimization:
                break
    else: # vertical
        jmin = x_min - x
        jmax = x_max - x
        for i in range(1, w+2):
            # add cells in front
            if signed.y < 0 and y - i >= y_min:
                for j in range(max(jmin, 1 - i - w), min(jmax, i + w)):
                    bodies.append(_cells[x + j][y - i])
            if signed.y > 0 and y + i < y_max:
                for j in range(max(jmin, 1 - i - w), min(jmax, i + w)):
                    bodies.append(_cells[x + j][y + i])
            # add cells beside
            if x - i >= x_min:
                bodies.append(_cells[x - i][y])
            if x + i < x_max:
                bodies.append(_cells[x + 1][y])
            if bodies.size() > max_bodies_optimization:
                break

    if debug and debug_single:
        if horiz:
            jmin = y_min - y
            jmax = y_max - y
            # add cells beside
            for i in range(1, w+2):
                # add cells in front
                if signed.x < 0 and x - i >= x_min:
                    for j in range(max(jmin, 1 - i - w), min(jmax, i + w)):
                        _debug_cells.append(Vector2(x - i, y + j))
                if signed.x > 0 and x + i < x_max:
                    for j in range(max(jmin, 1 - i - w), min(jmax, i + w)):
                        _debug_cells.append(Vector2(x + i, y + j))
                # add cells beside
                if y - i >= y_min:
                    _debug_cells.append(Vector2(x, y - i))
                if y + i < y_max:
                    _debug_cells.append(Vector2(x, y + 1))
        else: # vertical
            jmin = x_min - x
            jmax = x_max - x
            for i in range(1, w+2):
                # add cells in front
                if signed.y < 0 and y - i >= y_min:
                    for j in range(max(jmin, 1 - i - w), min(jmax, i + w)):
                        _debug_cells.append(Vector2(x + j, y - i))
                if signed.y > 0 and y + i < y_max:
                    for j in range(max(jmin, 1 - i - w), min(jmax, i + w)):
                        _debug_cells.append(Vector2(x + j, y + i))
                # add cells beside
                if x - i >= x_min:
                    _debug_cells.append(Vector2(x - i, y))
                if x + i < x_max:
                    _debug_cells.append(Vector2(x + i, y))

#    # all cells:
#    for cell_x in range(least_x, most_x + 1):
#        for cell_y in range(least_y, most_y + 1):
#            if cell_x != x and cell_y != y:
#                bodies.append(_cells[cell_x][cell_y])

    return bodies
