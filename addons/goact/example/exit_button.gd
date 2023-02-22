extends PureComponent

static func _get_default_props() -> Dictionary:
    var default_props: Dictionary = {
        "button_size": Vector2(32,32),
        "on_click": func():
            print("You forgot to pass an 'on_click' function")
    }
    return default_props


func _comp_init(_initial_props):
    pass

func _render():
    return Goact.create_element("Button", {
        "size": props.button_size,
        "text": "X",
        "anchor_left": 1,
        "anchor_right": 1,
        "offset_left": -props.button_size.x,
        "offset_right": 0,

        Goact.Event.pressed: func(_instance, _args):
            props.on_click.call()
    })

func _did_update(_previous_props, _previous_state):
    pass
        
    