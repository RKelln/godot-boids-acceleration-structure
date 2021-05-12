extends Node

# https://colorswall.com/palette/102/
var notes = [
    { 'note' : 1, 'note_color': Color("ff0000")}, # red
    { 'note' : 2, 'note_color': Color("ffa500")}, # orange
    { 'note' : 3, 'note_color': Color("ffff00")}, # yellow
    { 'note' : 4, 'note_color': Color("008000")}, # green
    { 'note' : 5, 'note_color': Color("0000ff")}, # blue
    { 'note' : 6, 'note_color': Color("4b0082")}, # indigo
    { 'note' : 7, 'note_color': Color("ee82ee")}, # violet
]

var note_status = [
    { 'on': false, 'group': 'note_1' },
    { 'on': false, 'group': 'note_2' },
    { 'on': false, 'group': 'note_3' },
    { 'on': false, 'group': 'note_4' },
    { 'on': false, 'group': 'note_5' },
    { 'on': false, 'group': 'note_6' },
    { 'on': false, 'group': 'note_7' },
]

var keys_to_note = {
    KEY_1 : 0,
    KEY_2 : 1,
    KEY_3 : 2,
    KEY_4 : 3,
    KEY_5 : 4,
    KEY_6 : 5,
    KEY_7 : 6,
}

# song_data is an array of dicts: timestamp, notes and messages:
# [ {"time": <float seconds>, "note": <int>, "message": "note_on/note_off"}, ...]
var song_data : Array
var song_time : float # seconds into the song
var song_index : int # current (unplayed) index into song list
var playing := false

func _unhandled_input(event: InputEvent) -> void:
    # debug with number keys
    if event is InputEventKey:
        if event.scancode in keys_to_note:
            if not event.pressed: # released
                note(keys_to_note[event.scancode], "note_off")
            elif event.pressed:
                note(keys_to_note[event.scancode], "note_on")


func _process(delta: float) -> void:
    if playing:
        song_time += delta
        while song_data[song_index].time <= song_time:
            note(song_data[song_index].note, song_data[song_index].message)
            song_index += 1
            if song_index >= song_data.size():
                playing = false
                break


func note(note_index : int, message : String) -> void:
    var n : Dictionary = note_status[note_index]
    if message == "note_off" and n.on:
        print("Note off: ", note_index)
        get_tree().call_group(n.group, message)
        n.on = false
    if message == "note_on" and not n.on:
        print("Note on:  ", note_index)
        get_tree().call_group(n.group, message)
        n.on = true


func rand_note() -> int:
    return randi() % notes.size()


# warning-ignore:shadowed_variable
func play(song_data : Array) -> void:
    song_time = 0
    song_index = 0
    self.song_data = song_data
    if self.song_data.size() > 0:
        playing = true


func stop() -> void:
    playing = false


func random_song(length: float) -> Array:
    var time := 0.0
    var data := []
    var note_on := Array()
    # start all notes off
    for _i in range(notes.size()):
        note_on.append(false)

    while time < length:
        var note := rand_note()
        var on = note_on[note]
        note_on[note] = not on
        var message = "note_on" if on else "note_off"
        data.append({"time" : time, "note": note, "message": message})
        time += randf()
    return data
