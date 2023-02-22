class_name GoactBinding
extends Object

signal change_signal(value: Variant)

var value: Variant

static func create(initial_value: Variant):
    var new_binding: GoactBinding = GoactBinding.new(initial_value)
    return [new_binding, new_binding.update]

func _init(initial_value: Variant):
    value = initial_value

func update(new_value: Variant):
    value = new_value
    change_signal.emit(new_value)

func subscribe(callback: Callable) -> Callable:
    if not change_signal.is_connected(callback):
        change_signal.connect(callback)

    return func():
        if change_signal.is_connected(callback):
            change_signal.disconnect(callback)

func get_value():
    return value

# return a mapped binding
func map(_mapping_function: Callable) -> MappedGoactBinding:
    return MappedGoactBinding.new(self, _mapping_function)

class MappedGoactBinding: 
    extends GoactBinding

    var parent_binding: GoactBinding
    var predicate: Callable

    func _init(_parent_binding: GoactBinding, _predicate: Callable):
        parent_binding = _parent_binding
        predicate = _predicate

    func subscribe(callback: Callable) -> Callable:
        return parent_binding.subscribe(func(new_value: Variant):(
            callback.call(predicate.call(new_value))
        ))

    func get_value():
        return predicate.call(parent_binding.get_value())

    func update(_new_value: Variant):
        printerr("MappedBindings created by GoactBinding.map(Callable) cannot be updated directly")

    func map(_mapping_function: Callable):
        printerr("MappedBindings created by GoactBinding.map(Callable) cannot be recursive")