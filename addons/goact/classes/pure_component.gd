extends Component

class_name PureComponent

func _should_update(_incoming_props: Dictionary, _incoming_state: Dictionary) -> bool:
    if _incoming_state != state:
        return true

    if _incoming_props == props:
        return false

    for key in _incoming_props:
        if not props.has(key):
            return true
        if props[key] != _incoming_props[key]:
            return true

    for key in props:
        if not _incoming_props.has(key):
            return true
        if _incoming_props[key] != props[key]:
            return true

    return false