extends PureComponent

const ExitButton: Script = preload("res://addons/goact/example/exit_button.gd")
const SelectionIndicator: Script = preload("res://addons/goact/example/selection_indicator.gd")

var fps_binding: GoactBinding
var update_fps_binding: Callable
var button_ref: GoactRef

var disconnect_process: Callable

static func _get_default_props() -> Dictionary:
    const DEFAULT_PROPS: Dictionary = {
        "size" = Vector2(200,100),
    }
    return DEFAULT_PROPS


func _comp_init(_initial_props: Dictionary):
    state = {
        "enabled": false,
        "is_selected": false,
        "change_time": Time.get_unix_time_from_system(),
    }

    var binding_set = Goact.create_binding(0)
    fps_binding = binding_set[0]
    update_fps_binding = binding_set[1]

    button_ref = Goact.create_ref()

func _render() -> Variant: # (Element | null)
    return Goact.create_element("Button", {
        "size_flags_vertical": Control.SIZE_EXPAND_FILL,
        "size": props.size,
        "text": fps_binding.map(func(new_value: int):
            return "FPS: " + str(new_value)
            ) if state.enabled else "DISABLED",
        Goact.Event.pressed: func(_node, _args): (
            set_state({
                "enabled": not state.enabled
            })
        ),
        Goact.Event.mouse_entered: func(_node, _args): (
            set_state({
                "is_selected": true,
            })
        ),
        Goact.Event.mouse_exited: func(_node, _args): (
            set_state({
                "is_selected": false,
            })
        ),
        Goact.Ref: button_ref,
    }, {
        SelectionIndicator = Goact.create_element(SelectionIndicator, {
            indicator_size = Vector2(15, button_ref.get_value().size.y if button_ref.get_value() else 0),
            is_selected = state.is_selected,
        })
    })


func _did_mount():
    var on_process = func():
        update_fps_binding.call(Engine.get_frames_per_second())

    Goact.get_tree().process_frame.connect(on_process)
    disconnect_process = func():
        Goact.get_tree().process_frame.disconnect(on_process)


func _will_unmount():
    disconnect_process.call()