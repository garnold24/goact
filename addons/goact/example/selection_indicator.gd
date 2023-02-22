extends PureComponent

const style_box = preload("res://new_style_box_texture.tres")

var selection_binding: GoactBinding
var update_selection_binding: Callable
var disconnect_process: Callable
var last_pos: float = 0

static func _get_default_props() -> Dictionary:
    var default_props: Dictionary = {
        "indicator_size": Vector2(32,32),
        "is_selected": false,
    }
    return default_props


static func _get_derived_state_from_props(_next_props: Variant, _last_state: Variant) -> Variant:
    return {
        "change_time": Time.get_unix_time_from_system(),
    }


func _comp_init(_initial_props):
    var selection_binding_set = Goact.create_binding(0)
    selection_binding = selection_binding_set[0]
    update_selection_binding = selection_binding_set[1]

    last_pos = 0.0
    set_state({
        "change_time": Time.get_unix_time_from_system(),
    })


func _will_update(_next_props: Dictionary, _next_state: Dictionary):
    last_pos = selection_binding.get_value()

func _render():
    return Goact.create_element("Panel", {
        "mouse_filter": Control.MOUSE_FILTER_IGNORE,
        "size": selection_binding.map(func(selection_progress: float):
            var tween_progress: float = Tween.interpolate_value(0.0, 1.0, selection_progress, 1, Tween.TRANS_SINE, Tween.EASE_OUT)
            return Vector2(tween_progress*props.indicator_size.x, props.indicator_size.y)
            ),
        "theme_override_styles/panel": style_box,
    })


func _did_mount():
    var on_process = func():
        #update selection binding based on state.selection_target
        var rate = 20.0
        var targ = 1.0 if props.is_selected else 0.0
        var dist = abs(targ - last_pos)
        var dt = min((Time.get_unix_time_from_system() - state.change_time)*rate/dist, 1)
        var progress = dt

        update_selection_binding.call(lerp(last_pos, targ, progress))

    Goact.get_tree().process_frame.connect(on_process)
    disconnect_process = func():
        Goact.get_tree().process_frame.disconnect(on_process)


func _will_unmount():
    disconnect_process.call()