extends TextureRect


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    var img := texture.get_data()
    img.fill(Color(0.5,0.5,0.5,0))

