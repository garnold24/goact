class_name GoactRef
extends Object

var internal_binding

static func create() -> GoactRef:
    var binding_set: Array = GoactBinding.create(null)
    return GoactRef.new(binding_set[0])


func _init(_internal_binding: GoactBinding):
    self.internal_binding = _internal_binding


func _get(key: StringName) -> Variant:
    if key == "current":
        return internal_binding.get_value()
    else:
        return internal_binding.get(key)


func _get_property_list():
    return [
        { "name": "current", "type": TYPE_OBJECT }
    ]


func _set(key: StringName , value: Variant):
    if key == "current":
        self.internal_binding.update(value)
        return true
    internal_binding.set(key, value)
    return true


func _to_string() -> String:
    return "GoactRef({0})".format([str(internal_binding.get_value())])


func get_value() -> Variant:
    return internal_binding.get_value()
