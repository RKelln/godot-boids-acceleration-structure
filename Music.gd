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

var note_status = {
    KEY_1: { 'on': false, 'group': 'notes_1' },
    KEY_2: { 'on': false, 'group': 'notes_2' },
    KEY_3: { 'on': false, 'group': 'notes_3' },
    KEY_4: { 'on': false, 'group': 'notes_4' },
    KEY_5: { 'on': false, 'group': 'notes_5' },
    KEY_6: { 'on': false, 'group': 'notes_6' },
    KEY_7: { 'on': false, 'group': 'notes_7' },
}

func _unhandled_input(event: InputEvent) -> void:
    # debug with number keys
    if event is InputEventKey:
        if event.scancode in note_status:
            if not event.pressed and note_status[event.scancode].on:
                print("Music note off", event.scancode)
                get_tree().call_group(note_status[event.scancode].group, 'note_off')
                note_status[event.scancode].on = false
            elif event.pressed and not note_status[event.scancode].on:
                print("Music note on", event.scancode)
                get_tree().call_group(note_status[event.scancode].group, 'note_on')
                note_status[event.scancode].on = true
